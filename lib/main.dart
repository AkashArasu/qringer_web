import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:stream_video_flutter/stream_video_flutter.dart';
import 'utils/app_theme.dart';

const _apiBaseUrl = String.fromEnvironment(
  'QRINGER_PUBLIC_API_URL',
  defaultValue: 'https://token-server.takash-arasu.workers.dev',
);
const _streamApiKey = String.fromEnvironment(
  'STREAM_API_KEY',
  defaultValue: 'y8h5754fwgma',
);

void main() => runApp(const QringerVisitorApp());

class QringerVisitorApp extends StatelessWidget {
  const QringerVisitorApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'QRinger', debugShowCheckedModeBanner: false, theme: AppTheme.theme,
        home: const AutomaticDoorbellPage(),
      );
}

enum VisitorCallStatus { preparing, requestingPermission, ringing, connecting, connected, busy, noAnswer, declined, cancelled, ended, error }

class _VisitorSession {
  const _VisitorSession({required this.callId, required this.propertyId, required this.visitorId, required this.streamToken, required this.sessionToken});
  final String callId, propertyId, visitorId, streamToken, sessionToken;
  factory _VisitorSession.fromJson(Map<String, dynamic> json) => _VisitorSession(
    callId: json['callId'] as String, propertyId: json['propertyId'] as String,
    visitorId: json['visitorId'] as String, streamToken: json['streamToken'] as String,
    sessionToken: json['sessionToken'] as String,
  );
}

class AutomaticDoorbellPage extends StatefulWidget {
  const AutomaticDoorbellPage({super.key});
  @override State<AutomaticDoorbellPage> createState() => _AutomaticDoorbellPageState();
}

class _AutomaticDoorbellPageState extends State<AutomaticDoorbellPage> {
  VisitorCallStatus _status = VisitorCallStatus.preparing;
  String? _error; _VisitorSession? _session; StreamVideo? _streamVideo; Call? _call;
  html.MediaStream? _permissionStream; Timer? _poller; bool _cancelled = false;

  @override void initState() { super.initState(); unawaited(_startAutomatically()); }
  @override void dispose() { _poller?.cancel(); unawaited(_cancelIfNeeded()); unawaited(_disconnect()); super.dispose(); }

  Future<void> _startAutomatically() async {
    final propertyId = _propertyIdFromUrl();
    if (propertyId == null) return _fail('This QR code is invalid or has expired.');
    try {
      _setStatus(VisitorCallStatus.requestingPermission);
      _permissionStream = await html.window.navigator.mediaDevices!.getUserMedia({'video': true, 'audio': true});
      if (_cancelled) return;
      _setStatus(VisitorCallStatus.preparing);
      final response = await http.post(Uri.parse('$_apiBaseUrl/v1/visitor-sessions'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'propertyId': propertyId})).timeout(const Duration(seconds: 10));
      if (response.statusCode == 409) return _setStatus(VisitorCallStatus.busy);
      if (response.statusCode != 200) throw Exception(_errorFrom(response));
      _session = _VisitorSession.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      _setStatus(VisitorCallStatus.ringing);
      _poller = Timer.periodic(const Duration(seconds: 1), (_) => unawaited(_pollCallState()));
      await _pollCallState();
    } catch (error) { _fail('Unable to start the doorbell call. ${_friendlyError(error)}'); }
  }

  String? _propertyIdFromUrl() {
    final segments = Uri.base.pathSegments;
    final pIndex = segments.indexOf('p');
    if (pIndex >= 0 && segments.length > pIndex + 1) return segments[pIndex + 1];
    return null;
  }

  Future<void> _pollCallState() async {
    final session = _session; if (session == null || _cancelled) return;
    try {
      final response = await http.get(Uri.parse('$_apiBaseUrl/v1/calls/${session.callId}/events'), headers: {'X-Property-Id': session.propertyId, 'X-Visitor-Session': session.sessionToken}).timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return;
      final state = (jsonDecode(response.body) as Map<String, dynamic>)['status'] as String;
      switch (state) {
        case 'accepted': await _connectMedia(); break;
        case 'busy': _setStatus(VisitorCallStatus.busy); break;
        case 'no_answer': _setStatus(VisitorCallStatus.noAnswer); break;
        case 'declined': _setStatus(VisitorCallStatus.declined); break;
        case 'cancelled': _setStatus(VisitorCallStatus.cancelled); break;
        case 'ended': _setStatus(VisitorCallStatus.ended); break;
      }
    } catch (_) { /* A transient polling failure must not end a ringing call. */ }
  }

  Future<void> _connectMedia() async {
    if (_status == VisitorCallStatus.connected || _status == VisitorCallStatus.connecting) return;
    final session = _session; if (session == null) return;
    _setStatus(VisitorCallStatus.connecting);
    try {
      _streamVideo = StreamVideo(_streamApiKey, user: User.regular(userId: session.visitorId, name: 'Visitor'), userToken: session.streamToken);
      await _streamVideo!.connect();
      _call = _streamVideo!.makeCall(callType: StreamCallType.defaultType(), id: session.callId);
      await _call!.join();
      await _call!.setCameraEnabled(enabled: true);
      await _call!.setMicrophoneEnabled(enabled: true);
      _poller?.cancel(); _setStatus(VisitorCallStatus.connected);
    } catch (error) { _fail('The homeowner answered, but video could not connect. ${_friendlyError(error)}'); }
  }

  Future<void> _cancelIfNeeded() async {
    final session = _session;
    if (session == null || _status == VisitorCallStatus.connected || _isTerminal(_status)) return;
    _cancelled = true;
    try { await http.post(Uri.parse('$_apiBaseUrl/v1/calls/${session.callId}/cancel'), headers: {'Content-Type': 'application/json', 'X-Property-Id': session.propertyId, 'X-Visitor-Session': session.sessionToken}); } catch (_) {}
  }
  Future<void> _disconnect() async { for (final track in _permissionStream?.getTracks() ?? <html.MediaStreamTrack>[]) { track.stop(); } try { await _call?.leave(); await _streamVideo?.disconnect(); } catch (_) {} }
  Future<void> _cancel() async { await _cancelIfNeeded(); await _disconnect(); if (mounted) _setStatus(VisitorCallStatus.cancelled); }
  void _setStatus(VisitorCallStatus value) { if (mounted) setState(() => _status = value); }
  void _fail(String message) { if (mounted) setState(() { _error = message; _status = VisitorCallStatus.error; }); }
  bool _isTerminal(VisitorCallStatus status) => {VisitorCallStatus.busy, VisitorCallStatus.noAnswer, VisitorCallStatus.declined, VisitorCallStatus.cancelled, VisitorCallStatus.ended, VisitorCallStatus.error}.contains(status);
  String _errorFrom(http.Response response) { try { return (jsonDecode(response.body) as Map<String, dynamic>)['error'] as String; } catch (_) { return 'request_failed'; } }
  String _friendlyError(Object error) => error.toString().contains('NotAllowed') ? 'Camera and microphone permission is required.' : '';

  @override Widget build(BuildContext context) => Scaffold(body: Container(decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient), child: SafeArea(child: _status == VisitorCallStatus.connected ? _buildCall() : _buildStatus())));
  Widget _buildCall() => StreamCallContainer(call: _call!, callContentWidgetBuilder: (context, call) => StreamCallContent(call: call, layoutMode: ParticipantLayoutMode.spotlight));
  Widget _buildStatus() {
    final details = switch (_status) {
      VisitorCallStatus.requestingPermission => ('Allow camera and microphone', 'QRinger needs both permissions to let the homeowner see and hear you.', Icons.video_call),
      VisitorCallStatus.preparing => ('Starting doorbell', 'Connecting securely…', Icons.doorbell),
      VisitorCallStatus.ringing => ('Ringing homeowner', 'Please wait while they answer.', Icons.notifications_active),
      VisitorCallStatus.connecting => ('Connecting video', 'The homeowner answered.', Icons.videocam),
      VisitorCallStatus.busy => ('Homeowner is busy', 'Please try again in a moment.', Icons.phone_in_talk),
      VisitorCallStatus.noAnswer => ('No answer', 'The homeowner did not answer.', Icons.phone_missed),
      VisitorCallStatus.declined => ('Call declined', 'The homeowner is unavailable.', Icons.call_end),
      VisitorCallStatus.cancelled => ('Call cancelled', 'Your doorbell call was cancelled.', Icons.cancel),
      VisitorCallStatus.ended => ('Call ended', 'Thank you for visiting.', Icons.call_end),
      VisitorCallStatus.error => ('Unable to call', _error ?? 'Please try again.', Icons.error_outline),
      _ => ('Preparing', '', Icons.doorbell),
    };
    return Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(details.$3, color: Colors.white, size: 72), const SizedBox(height: 24), Text(details.$1, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold), textAlign: TextAlign.center), const SizedBox(height: 12), Text(details.$2, style: const TextStyle(color: Colors.white70, fontSize: 16), textAlign: TextAlign.center), if (_status == VisitorCallStatus.ringing || _status == VisitorCallStatus.preparing) ...[const SizedBox(height: 28), const CircularProgressIndicator(color: Colors.white)], if (_status == VisitorCallStatus.ringing) ...[const SizedBox(height: 28), OutlinedButton.icon(onPressed: _cancel, icon: const Icon(Icons.call_end), label: const Text('Cancel'), style: OutlinedButton.styleFrom(foregroundColor: Colors.white))]])));
  }
}
