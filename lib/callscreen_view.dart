import 'package:flutter/material.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';
import 'utils/app_theme.dart';

class CallScreen extends StatefulWidget {
  final Call call;

  const CallScreen({
    super.key,
    required this.call,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: StreamCallContainer(
          call: widget.call,
        ),
      ),
    );
  }
}