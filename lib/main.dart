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

void _videoLog(String event, [Map<String, Object?> details = const {}]) {
  final message = '[QRINGER_VIDEO] $event ${jsonEncode(details)}';
  html.window.console.log(message);
}

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
  const _VisitorSession({required this.callId, required this.propertyId, required this.visitorId, required this.streamToken, required this.sessionToken, required this.streamApiKey});
  final String callId, propertyId, visitorId, streamToken, sessionToken, streamApiKey;
  factory _VisitorSession.fromJson(Map<String, dynamic> json) => _VisitorSession(
    callId: json['callId'] as String, propertyId: json['propertyId'] as String,
    visitorId: json['visitorId'] as String, streamToken: json['streamToken'] as String,
    sessionToken: json['sessionToken'] as String, streamApiKey: json['streamApiKey'] as String,
  );
}

class AutomaticDoorbellPage extends StatefulWidget {
  const AutomaticDoorbellPage({super.key});
  @override State<AutomaticDoorbellPage> createState() => _AutomaticDoorbellPageState();
}

class _AutomaticDoorbellPageState extends State<AutomaticDoorbellPage> {
  VisitorCallStatus _status = VisitorCallStatus.preparing;
  String? _error; _VisitorSession? _session; StreamVideo? _streamVideo; Call? _call;
  html.MediaStream? _permissionStream; Timer? _poller;
  bool _cancelled = false; bool _finishing = false;

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
        case 'busy': await _finishFromRemote(VisitorCallStatus.busy); break;
        case 'no_answer': await _finishFromRemote(VisitorCallStatus.noAnswer); break;
        case 'declined': await _finishFromRemote(VisitorCallStatus.declined); break;
        case 'cancelled': await _finishFromRemote(VisitorCallStatus.cancelled); break;
        case 'ended': await _finishFromRemote(VisitorCallStatus.ended); break;
      }
    } catch (_) { /* A transient polling failure must not end a ringing call. */ }
  }

  Future<void> _connectMedia() async {
    if (_status == VisitorCallStatus.connected || _status == VisitorCallStatus.connecting) return;
    final session = _session; if (session == null) return;
    _setStatus(VisitorCallStatus.connecting);
    try {
      // getUserMedia above is strictly a permission prompt.  Release those
      // temporary tracks before Stream creates the tracks it will publish.
      for (final track in _permissionStream?.getTracks() ?? <html.MediaStreamTrack>[]) { track.stop(); }
      _permissionStream = null;
      _streamVideo = StreamVideo(session.streamApiKey, user: User.regular(userId: session.visitorId, name: 'Visitor'), userToken: session.streamToken);
      await _streamVideo!.connect();
      _call = _streamVideo!.makeCall(callType: StreamCallType.defaultType(), id: session.callId);
      // The Worker created this call before the visitor joined.  Load and
      // watch that existing call first, otherwise the browser can connect to
      // the SFU with an empty participant snapshot and render a blank call.
      final callData = await _call!.get(membersLimit: 2, watch: true);
      if (callData.isFailure) {
        throw StateError('Unable to load the doorbell call: ${callData.getErrorOrNull()}');
      }
      // StreamCallContainer below owns the single RTC join. Its connect
      // options publish the visitor camera and microphone as part of that
      // join, so participant state and the rendered tracks stay in sync.
      _setStatus(VisitorCallStatus.connected);
    } catch (error) { _fail('The homeowner answered, but video could not connect. ${_friendlyError(error)}'); }
  }

  Future<void> _cancelIfNeeded() async {
    final session = _session;
    if (session == null || _isTerminal(_status)) return;
    _cancelled = true;
    final action = _status == VisitorCallStatus.connected ? 'end' : 'cancel';
    try { await http.post(Uri.parse('$_apiBaseUrl/v1/calls/${session.callId}/$action'), headers: {'Content-Type': 'application/json', 'X-Property-Id': session.propertyId, 'X-Visitor-Session': session.sessionToken}); } catch (_) {}
  }
  Future<void> _disconnect() async { for (final track in _permissionStream?.getTracks() ?? <html.MediaStreamTrack>[]) { track.stop(); } try { await _call?.leave(); await _streamVideo?.disconnect(); } catch (_) {} }
  Future<void> _cancel() async { await _cancelIfNeeded(); await _disconnect(); if (mounted) _setStatus(VisitorCallStatus.cancelled); }
  Future<void> _endCall() async { await _cancelIfNeeded(); await _disconnect(); if (mounted) _setStatus(VisitorCallStatus.ended); }
  Future<void> _finishFromRemote(VisitorCallStatus status) async {
    if (_finishing || _isTerminal(_status)) return;
    _finishing = true;
    _poller?.cancel();
    await _disconnect();
    if (mounted) _setStatus(status);
  }
  void _setStatus(VisitorCallStatus value) { if (mounted) setState(() => _status = value); }
  void _fail(String message) { if (mounted) setState(() { _error = message; _status = VisitorCallStatus.error; }); }
  bool _isTerminal(VisitorCallStatus status) => {VisitorCallStatus.busy, VisitorCallStatus.noAnswer, VisitorCallStatus.declined, VisitorCallStatus.cancelled, VisitorCallStatus.ended, VisitorCallStatus.error}.contains(status);
  String _errorFrom(http.Response response) { try { return (jsonDecode(response.body) as Map<String, dynamic>)['error'] as String; } catch (_) { return 'request_failed'; } }
  String _friendlyError(Object error) => error.toString().contains('NotAllowed') ? 'Camera and microphone permission is required.' : '';

  @override Widget build(BuildContext context) => Scaffold(body: Container(decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient), child: SafeArea(child: _status == VisitorCallStatus.connected ? _buildCall() : _buildStatus())));
  Widget _buildCall() => StreamCallContainer(
    call: _call!,
    callConnectOptions: CallConnectOptions(
      camera: TrackOption.enabled(),
      microphone: TrackOption.enabled(),
      speakerDefaultOn: true,
    ),
    onCallDisconnected: (_) => unawaited(_finishFromRemote(VisitorCallStatus.ended)),
    // Do not add a second CallStatus gate here. Signalling has already told
    // this page that the homeowner accepted, and StreamCallContainer owns the
    // RTC join. The previous nested StreamCallContent could remain in its
    // non-connected body on web and never insert participant video widgets.
    callContentWidgetBuilder: (context, call) => _VisitorCallSurface(
      call: call,
      onEnd: _endCall,
    ),
  );
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
      VisitorCallStatus.ended => ('Session ended', 'The doorbell session has ended. You can safely close this window.', Icons.check_circle_outline),
      VisitorCallStatus.error => ('Unable to call', _error ?? 'Please try again.', Icons.error_outline),
      _ => ('Preparing', '', Icons.doorbell),
    };
    return Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(details.$3, color: Colors.white, size: 72), const SizedBox(height: 24), Text(details.$1, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold), textAlign: TextAlign.center), const SizedBox(height: 12), Text(details.$2, style: const TextStyle(color: Colors.white70, fontSize: 16), textAlign: TextAlign.center), if (_status == VisitorCallStatus.ringing || _status == VisitorCallStatus.preparing) ...[const SizedBox(height: 28), const CircularProgressIndicator(color: Colors.white)], if (_status == VisitorCallStatus.ringing) ...[const SizedBox(height: 28), OutlinedButton.icon(onPressed: _cancel, icon: const Icon(Icons.call_end), label: const Text('Cancel'), style: OutlinedButton.styleFrom(foregroundColor: Colors.white))]])));
  }

}

class _VisitorCallSurface extends StatefulWidget {
  const _VisitorCallSurface({required this.call, required this.onEnd});

  final Call call;
  final Future<void> Function() onEnd;

  @override
  State<_VisitorCallSurface> createState() => _VisitorCallSurfaceState();
}

class _VisitorCallSurfaceState extends State<_VisitorCallSurface> {
  late CallState _callState;
  StreamSubscription<CallState>? _stateSubscription;
  Timer? _statePoller;
  String _lastSignature = '';
  int _buildCount = 0;

  @override
  void initState() {
    super.initState();
    _callState = widget.call.state.value;
    _lastSignature = _signature(_callState);
    _logState('surface_mounted', _callState);
    _subscribe(widget.call);
  }

  @override
  void didUpdateWidget(covariant _VisitorCallSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.call != widget.call) {
      _stateSubscription?.cancel();
      _statePoller?.cancel();
      _callState = widget.call.state.value;
      _lastSignature = _signature(_callState);
      _logState('call_widget_changed', _callState);
      _subscribe(widget.call);
    }
  }

  void _subscribe(Call call) {
    _videoLog('call_state_listener_subscribed');
    _stateSubscription = call.state.listen((state) {
      _logState('call_state_event', state);
      _lastSignature = _signature(state);
      if (mounted) setState(() => _callState = state);
    });

    // This also makes the UI resilient if a browser/SDK combination mutates
    // the ValueStream value without delivering a distinct listener event.
    _statePoller = Timer.periodic(const Duration(milliseconds: 500), (_) {
      final current = call.state.value;
      final signature = _signature(current);
      if (signature == _lastSignature) return;
      _lastSignature = signature;
      _logState('call_state_poll_change', current);
      if (mounted) setState(() => _callState = current);
    });
  }

  String _signature(CallState state) => [
        state.status.runtimeType,
        for (final participant in state.callParticipants)
          '${participant.uniqueParticipantKey}:${participant.publishedTracks.keys.join(',')}:${participant.isVideoEnabled}',
      ].join('|');

  void _logState(String event, CallState state) {
    final participants = state.callParticipants;
    final local = participants.where((participant) => participant.isLocal).firstOrNull;
    final remotes = participants.where((participant) => !participant.isLocal).toList();
    final localVideoTracks = local == null ||
            !local.publishedTracks.containsKey(SfuTrackType.video)
        ? 0
        : 1;
    final remoteVideoTracks = remotes
        .where((participant) =>
            participant.publishedTracks.containsKey(SfuTrackType.video))
        .length;

    _videoLog(event, {
      'callStatus': state.status.runtimeType.toString(),
      'participantCount': participants.length,
      'localParticipantExists': local != null,
      'remoteParticipantExists': remotes.isNotEmpty,
      'localVideoTrackCount': localVideoTracks,
      'remoteVideoTrackCount': remoteVideoTracks,
      'participants': [
        for (final participant in participants)
          {
            'local': participant.isLocal,
            'videoEnabled': participant.isVideoEnabled,
            'publishedTracks': participant.publishedTracks.keys
                .map((track) => track.toString())
                .toList(),
            'videoTrackMountedInCall': widget.call.getTrack(
                  participant.trackIdPrefix,
                  SfuTrackType.video,
                ) !=
                null,
          },
      ],
    });
  }

  @override
  Widget build(BuildContext context) {
    _buildCount += 1;
    final participants = _callState.callParticipants;
    final local = participants.where((participant) => participant.isLocal).firstOrNull;
    final remote = participants.where((participant) => !participant.isLocal).firstOrNull;

    _videoLog('surface_rebuild', {
      'buildCount': _buildCount,
      'callStatus': _callState.status.runtimeType.toString(),
      'participantCount': participants.length,
      'localParticipantExists': local != null,
      'remoteParticipantExists': remote != null,
    });

    return Scaffold(
      backgroundColor: const Color(0xFF25292F),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: const Color(0xFF102018),
        title: const Text('QRinger doorbell'),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: _buildParticipants(local: local, remote: remote),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: SafeArea(
              child: Center(
                child: FilledButton.icon(
                  onPressed: () => unawaited(widget.onEnd()),
                  icon: const Icon(Icons.call_end),
                  label: const Text('End call'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipants({
    required CallParticipantState? local,
    required CallParticipantState? remote,
  }) {
    _videoLog('participant_detection_executed', {
      'localParticipantExists': local != null,
      'remoteParticipantExists': remote != null,
    });

    if (local == null && remote == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Waiting for call participants…',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    if (remote == null) {
      return _participantWidget(local!, 'local');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final previewWidth = (constraints.maxWidth * 0.28).clamp(120.0, 280.0);
        return Stack(
          children: [
            Positioned.fill(child: _participantWidget(remote, 'remote')),
            if (local != null)
              Positioned(
                right: 16,
                bottom: 88,
                width: previewWidth,
                height: previewWidth * 9 / 16,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: _participantWidget(local, 'local'),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _participantWidget(
    CallParticipantState participant,
    String role,
  ) {
    _videoLog('participant_widget_inserted', {
      'role': role,
      'videoEnabled': participant.isVideoEnabled,
      'publishedTracks':
          participant.publishedTracks.keys.map((track) => track.toString()).toList(),
    });
    return StreamCallParticipant(
      key: ValueKey('${participant.uniqueParticipantKey}-$role'),
      call: widget.call,
      participant: participant,
    );
  }

  @override
  void dispose() {
    _videoLog('surface_disposed', {'buildCount': _buildCount});
    _stateSubscription?.cancel();
    _statePoller?.cancel();
    super.dispose();
  }
}
