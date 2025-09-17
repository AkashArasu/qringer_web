// import 'package:flutter/material.dart';
// import 'package:qringer_web_stream_io/callscreen_view.dart';
// import 'package:stream_video_flutter/stream_video_flutter.dart';
// import 'dart:math';
// import 'package:universal_html/html.dart' as html;
// import 'package:http/http.dart' as http;
// import 'dart:convert';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Stream Video Call',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//       ),
//       home: const VideoCallPage(),
//     );
//   }
// }

// class VideoCallPage extends StatefulWidget {
//   const VideoCallPage({super.key});

//   @override
//   State<VideoCallPage> createState() => _VideoCallPageState();
// }

// class _VideoCallPageState extends State<VideoCallPage> {
//   late final StreamVideo _streamVideo;
//   Call? call;
//   bool _isCallingUser = false;
//   late final String randomString;
//   late final String calleeId;

//   @override
//   void initState() {
//     super.initState();
//     randomString = generateRandomString(10);
//     extractPhoneNumberandToken();
//     _initializeStreamVideo();
//   }

//   @override
//   void dispose() {
//     call?.end();
//     _streamVideo.disconnect();
//     super.dispose();
//   }

//   String generateRandomString(int len) {
//     var r = Random();
//     return String.fromCharCodes(
//         List.generate(len, (index) => r.nextInt(33) + 89));
//   }

//   void extractPhoneNumberandToken() {
//     // Get the current URL
//     final uri = Uri.base;

//     // Extract the phone parameter
//     final String? extractedPhone = uri.queryParameters['userId'];

//     // Set the callee ID
//     setState(() {
//       calleeId = extractedPhone ?? '';
//     });
//   }

//   Future<String> fetchToken(String userId) async {
//     // final response = await http.get(
//     //   Uri.parse('https://jwt-token-server.onrender.com/get-token/$userId'),
//     // );

//     final response = await http.post(
//       Uri.parse('https://token-server.takash-arasu.workers.dev/token'),
//       body: jsonEncode({"userId": userId}),
      
//     );

//     if (response.statusCode == 200) {
//       // If the server did return a 200 OK response,
//       // then parse the JSON.
//       return response.body;
//     } else {
//       // If the server did not return a 200 OK response,
//       // then throw an exception.
//       throw Exception('Failed to load token');
//     }
//   }

//   Future<void> _initializeStreamVideo() async {
//     // Fetch token - token is working
//     final token = await fetchToken('$calleeId-visitor-$randomString');
//     // final token = await fetchToken('8586035683');

//     // Initialize Stream Video client

//     _streamVideo = StreamVideo(
//       'y8h5754fwgma', // Replace with your Stream API key
//       user: User.regular(
//           userId: '$calleeId-visitor-$randomString',
//           name: "Visitor" // Replace with your user ID
//           ),
//       userToken: token,
//       options: const StreamVideoOptions(
//         keepConnectionsAliveWhenInBackground: true,
//       ),
//     );

//     // _streamVideo = StreamVideo(
//     //     'y8h5754fwgma', // Replace with your Stream API key
//     //     user: User.regular(
//     //         userId: '8586035683', name: "visitor" // Replace with your user ID
//     //         ),
//     //     userToken: token,
//     //     options: const StreamVideoOptions(
//     //       keepConnectionsAliveWhenInBackground: true,
//     //     ));

//     await _streamVideo.connect();
//     _startCall();
//   }

//   Future<void> _startCall() async {
//     try {
//       setState(() {
//         _isCallingUser = true;
//       });

//       // Create and join a call
//       final callId = "call-$randomString";

//       call = _streamVideo.makeCall(
//         callType: StreamCallType.defaultType(),
//         id: callId,
//       );

//       await call!
//           .getOrCreate(memberIds: [calleeId], ringing: true, video: true);

//       await call!.join();

//       setState(() {
//         _isCallingUser = false;
//       });
//     } catch (e) {
//       debugPrint('Error starting call: $e');
//       setState(() {
//         _isCallingUser = false;
//       });
//     }
//   }

//   Future<void> _endCall() async {
//     try {
//       await call!.leave();
//       await call!.end();
//       setState(() {
//         call = null;
//       });
//     } catch (e) {
//       debugPrint('Error ending call: $e');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//           if (call != null) ...[
//             StreamCallContainer(
//               // Stream's pre-made component
//               call: call!,
//               callConnectOptions: CallConnectOptions(
//                 camera: TrackOption.enabled(),
//                 screenShare: TrackOption.disabled(),
//                 microphone: TrackOption.enabled(),
//               ),

//               callContentBuilder: (context, call, callState) {
//                 return StreamCallContent(
//                   call: call,
//                   callState: callState,
//                   layoutMode: ParticipantLayoutMode.spotlight,
//                   callAppBarBuilder: (context, call, callState) {
//                     return AppBar(
//                       actions: const [],
//                     );
//                   },
//                   callControlsBuilder: (context, call, callState) {
//                     return const StreamCallControls(options: [
//                       // LeaveCallOption(call: call, onLeaveCallTap: call.leave)
//                     ]);
//                   },
//                 );
//               },
//             ),
//             Positioned(
//               bottom: 32,
//               left: 0,
//               right: 0,
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   FloatingActionButton(
//                     backgroundColor: Colors.red,
//                     onPressed: _endCall,
//                     child: const Icon(Icons.call_end),
//                   ),
//                 ],
//               ),
//             ),
//           ] else if (_isCallingUser)
//             const Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   CircularProgressIndicator(),
//                   SizedBox(height: 16),
//                   Text('Connecting to call...'),
//                 ],
//               ),
//             )
//           else
//             const Center(
//               child: Text('Call ended'),
//             ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';
import 'dart:math';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'utils/app_theme.dart';

void main() {
  // Set WebRTC logging level to reduce noise
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stream Video Call',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const VideoCallPage(),
    );
  }
}

class VideoCallPage extends StatefulWidget {
  const VideoCallPage({super.key});

  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  StreamVideo? _streamVideo;
  Call? _call;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  late final String _callId;
  String? _calleeId;

  @override
  void initState() {
    super.initState();
    _callId = _generateRandomString(10);
    _extractCalleeIdFromUrl();
    _initializeStreamVideo();
  }

  @override
  void dispose() {
    _endCall();
    super.dispose();
  }

  String _generateRandomString(int len) {
    final r = Random();
    return String.fromCharCodes(
        List.generate(len, (index) => r.nextInt(26) + 97)); // Use only lowercase letters for more reliable IDs
  }

  void _extractCalleeIdFromUrl() {
    // Get the current URL
    final uri = Uri.base;

    // Extract the userId parameter
    final String? extractedUserId = uri.queryParameters['userId'];

    // Set the callee ID
    setState(() {
      _calleeId = extractedUserId;
    });

    if (_calleeId == null || _calleeId!.isEmpty) {
      setState(() {
        _hasError = true;
        _isLoading = false;
        _errorMessage = 'Missing userId parameter in URL';
      });
    }
  }

  Future<String> _fetchToken(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('https://token-server.takash-arasu.workers.dev/token'),
        body: jsonEncode({"userId": userId})
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Token request timed out'),
      );

      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception('Server returned ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to fetch token: $e');
    }
  }

  Future<void> _initializeStreamVideo() async {
    if (_calleeId == null || _calleeId!.isEmpty) {
      return; // Error already handled in _extractCalleeIdFromUrl
    }

    try {
      // Generate unique visitor ID
      final visitorUserId = '$_calleeId-visitor-$_callId';
      
      // Fetch token
      final token = await _fetchToken(visitorUserId);

      // Initialize Stream Video client with custom stats options to avoid the error
      _streamVideo = StreamVideo(
        'y8h5754fwgma', // Your Stream API key
        user: User.regular(
          userId: visitorUserId,
          name: "Visitor",
        ),
        userToken: token,
        options: const StreamVideoOptions(
          keepConnectionsAliveWhenInBackground: true,
        ),
      );

      await _streamVideo!.connect();
      await _startCall();
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
        _errorMessage = 'Connection error: $e';
      });
      debugPrint('Error initializing Stream Video: $e');
    }
  }

  Future<void> _startCall() async {
    try {
      if (_calleeId == null || _calleeId!.isEmpty) {
        throw Exception('No callee ID available');
      }
      
      // Create call ID with unique identifier
      final callId = "call-$_callId";

      _call = _streamVideo!.makeCall(
        callType: StreamCallType.defaultType(),
        id: callId,
      );

      // Use a more robust try-catch for getOrCreate
      try {
        await _call!.getOrCreate(
          memberIds: [_calleeId!], 
          ringing: true,
        );
      } catch (e) {
        developer.log('Error in getOrCreate', error: e, name: 'video_call');
        // If this fails, we'll try to join anyway
      }

      try {
        await _call!.join();

        // IMPORTANT: Enable camera for visitor so they can be seen by the callee
        // The callee controls their own camera state independently
        try {
          await _call!.setCameraEnabled(enabled: true);
          developer.log('Camera enabled for visitor', name: 'video_call');
        } catch (e) {
          developer.log('Error enabling camera', error: e, name: 'video_call');
        }

        setState(() {
          _isLoading = false;
        });
        
      } catch (e) {
        developer.log('Error joining call', error: e, name: 'video_call');
        throw Exception('Failed to join call: $e');
      }
    } catch (e) {

      setState(() {
        _hasError = true;
        _isLoading = false;
        _errorMessage = 'Failed to start call: $e';
      });
      
      developer.log('Error starting call', error: e, name: 'video_call');
      debugPrint('Error starting call: $e');
    }
  }

  Future<void> _endCall() async {
    try {
      if (_call != null) {
        try {
          await _call!.leave();
        } catch (e) {
          debugPrint('Error leaving call: $e');
        }
        
        try {
          await _call!.end();
        } catch (e) {
          debugPrint('Error ending call: $e');
        }
        
        if (mounted) {
          setState(() {
            _call = null;
          });
        }
      }
      
      if (_streamVideo != null) {
        try {
          _streamVideo!.disconnect();
        } catch (e) {
          debugPrint('Error disconnecting: $e');
        }
      }
    } catch (e) {
      debugPrint('Error in _endCall: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_hasError) {
      return _buildErrorView();
    }
    
    if (_isLoading) {
      return _buildLoadingView();
    }
    
    if (_call != null) {
      return _buildCallView();
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.call_end,
            size: 64,
            color: Colors.white.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 16),
          ShaderMask(
            shaderCallback: (bounds) => AppTheme.titleGradient.createShader(bounds),
            child: const Text(
              'Call ended',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            ShaderMask(
              shaderCallback: (bounds) => AppTheme.titleGradient.createShader(bounds),
              child: Text(
                'Connection Error',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'An unknown error occurred',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                gradient: AppTheme.accentGradient(),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _hasError = false;
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _initializeStreamVideo();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                ),
                child: const Text('Retry'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.accentGradient(alpha: 0.3),
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          ShaderMask(
            shaderCallback: (bounds) => AppTheme.titleGradient.createShader(bounds),
            child: const Text(
              'Connecting to call...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait while we establish the connection',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallView() {
    return Stack(
      children: [
        // Use a try-catch with builder to prevent rendering errors
        Builder(
          builder: (context) {
            try {
              return StreamCallContainer(
                call: _call!,
                // Removed CallConnectOptions as they don't work properly in SDK 0.10.2
                // Camera and microphone are now controlled via call.camera.disable()/enable() methods
                callContentWidgetBuilder: (context, call) {
                  return StreamCallContent(
                    call: call,
                    layoutMode: ParticipantLayoutMode.grid,
                    // Empty call controls builder to hide all default controls
                    callControlsWidgetBuilder: (context, call) {
                      return const SizedBox.shrink();
                    },
                  );
                },
              );
            } catch (e) {
              debugPrint('Error rendering call view: $e');
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.video_call, size: 48),
                    const SizedBox(height: 16),
                    const Text('Call is connected, but there was an error displaying the video.'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {});  // Force rebuild
                      },
                      child: const Text('Refresh'),
                    ),
                  ],
                ),
              );
            }
          },
        ),
        // Only leave call button positioned at the bottom
        // Positioned(
        //   bottom: 32,
        //   left: 0,
        //   right: 0,
        //   child: Center(
        //     child: FloatingActionButton(
        //       backgroundColor: Colors.red,
        //       onPressed: () {
        //         _endCall();
        //         setState(() {
        //           _call = null;
        //         });
        //       },
        //       child: const Icon(Icons.call_end, color: Colors.white, size: 28),
        //     ),
        //   ),
        // ),
      ],
    );
  }
}