// import 'package:flutter/material.dart';
// import 'package:stream_video_flutter/stream_video_flutter.dart';

// Future<void> main() async {
//   // Ensure Flutter is able to communicate with Plugins
//   WidgetsFlutterBinding.ensureInitialized();

//   // Initialize Stream video and set the API key along with the user for our app.
//   final client = StreamVideo(
//     'y8h5754fwgma',
//     user: User.regular(userId: 'REPLACE_WITH_USER_ID', name: 'Test User'),
//     userToken: 'REPLACE_WITH_TOKEN',
//   );

//   // Set up our call object and pass it the call type and ID. The most common call type is `default`, which enables full audio and video transmission
//   final call = client.makeCall(
//       callType: StreamCallType.defaultType(), id: 'REPLACE_WITH_CALL_ID');
//   // Connect to the call we created
//   await call.join();

//   runApp(
//     DemoAppHome(
//       call: call,
//     ),
//   );
// }

// class DemoAppHome extends StatelessWidget {
//   const DemoAppHome({super.key, required this.call});

//   final Call call;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: StreamCallContainer(
//         // Stream's pre-made component
//         call: call,
//         callContentBuilder: (context, call, callState) {
//           return StreamCallContent(
//             call: call,
//             callState: callState,
//             callControlsBuilder: (context, call, callState) {
//               return StreamCallControls(
//                 options: [
//                   LeaveCallOption(call: call, onLeaveCallTap: call.leave)
//                   ]
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter Demo',
//       theme: ThemeData(
//         // This is the theme of your application.
//         //
//         // TRY THIS: Try running your application with "flutter run". You'll see
//         // the application has a purple toolbar. Then, without quitting the app,
//         // try changing the seedColor in the colorScheme below to Colors.green
//         // and then invoke "hot reload" (save your changes or press the "hot
//         // reload" button in a Flutter-supported IDE, or press "r" if you used
//         // the command line to start the app).
//         //
//         // Notice that the counter didn't reset back to zero; the application
//         // state is not lost during the reload. To reset the state, use hot
//         // restart instead.
//         //
//         // This works for code too, not just values: Most code changes can be
//         // tested with just a hot reload.
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//         useMaterial3: true,
//       ),
//       home: const MyHomePage(title: 'Flutter Demo Home Page'),
//     );
//   }
// }

// class MyHomePage extends StatefulWidget {
//   const MyHomePage({super.key, required this.title});

//   // This widget is the home page of your application. It is stateful, meaning
//   // that it has a State object (defined below) that contains fields that affect
//   // how it looks.

//   // This class is the configuration for the state. It holds the values (in this
//   // case the title) provided by the parent (in this case the App widget) and
//   // used by the build method of the State. Fields in a Widget subclass are
//   // always marked "final".

//   final String title;

//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   int _counter = 0;

//   void _incrementCounter() {
//     setState(() {
//       // This call to setState tells the Flutter framework that something has
//       // changed in this State, which causes it to rerun the build method below
//       // so that the display can reflect the updated values. If we changed
//       // _counter without calling setState(), then the build method would not be
//       // called again, and so nothing would appear to happen.
//       _counter++;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     // This method is rerun every time setState is called, for instance as done
//     // by the _incrementCounter method above.
//     //
//     // The Flutter framework has been optimized to make rerunning build methods
//     // fast, so that you can just rebuild anything that needs updating rather
//     // than having to individually change instances of widgets.
//     return Scaffold(
//       appBar: AppBar(
//         // TRY THIS: Try changing the color here to a specific color (to
//         // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
//         // change color while the other colors stay the same.
//         backgroundColor: Theme.of(context).colorScheme.inversePrimary,
//         // Here we take the value from the MyHomePage object that was created by
//         // the App.build method, and use it to set our appbar title.
//         title: Text(widget.title),
//       ),
//       body: Center(
//         // Center is a layout widget. It takes a single child and positions it
//         // in the middle of the parent.
//         child: Column(
//           // Column is also a layout widget. It takes a list of children and
//           // arranges them vertically. By default, it sizes itself to fit its
//           // children horizontally, and tries to be as tall as its parent.
//           //
//           // Column has various properties to control how it sizes itself and
//           // how it positions its children. Here we use mainAxisAlignment to
//           // center the children vertically; the main axis here is the vertical
//           // axis because Columns are vertical (the cross axis would be
//           // horizontal).
//           //
//           // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
//           // action in the IDE, or press "p" in the console), to see the
//           // wireframe for each widget.
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             const Text(
//               'You have pushed the button this many times:',
//             ),
//             Text(
//               '$_counter',
//               style: Theme.of(context).textTheme.headlineMedium,
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _incrementCounter,
//         tooltip: 'Increment',
//         child: const Icon(Icons.add),
//       ), // This trailing comma makes auto-formatting nicer for build methods.
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:qringer_web_stream_io/callscreen_view.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';
import 'dart:math';
import 'package:universal_html/html.dart' as html;
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stream Video Call',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
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
  late final StreamVideo _streamVideo;
  Call? call;
  bool _isCallingUser = false;
  late final String randomString;
  late final String calleeId;

  @override
  void initState() {
    super.initState();
    randomString = generateRandomString(10);
    extractPhoneNumberandToken();
    _initializeStreamVideo();
  }

  String generateRandomString(int len) {
    var r = Random();
    return String.fromCharCodes(
        List.generate(len, (index) => r.nextInt(33) + 89));
  }

  void extractPhoneNumberandToken() {
    // Get the current URL
    final uri = Uri.base;

    // Extract the phone parameter
    final String? extractedPhone = uri.queryParameters['userId'];

    // Set the callee ID
    setState(() {
      calleeId = extractedPhone ?? '';
    });
  }

  Future<String> fetchToken(String userId) async {
    final response = await http.get(
      Uri.parse('https://jwt-token-server.onrender.com/get-token/$userId'),
    );

    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      return jsonDecode(response.body)['token'];
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to load token');
    }
  }

  Future<void> _initializeStreamVideo() async {
    // Fetch token - token is working
    final token = await fetchToken('$calleeId-visitor-$randomString');
    // final token = await fetchToken('8586035683');
    print(token);

    // Initialize Stream Video client

    _streamVideo = StreamVideo(
      'y8h5754fwgma', // Replace with your Stream API key
      user: User.regular(
          userId: '$calleeId-visitor-$randomString',
          name: "Visitor" // Replace with your user ID
          ),
      userToken: token,
      options: const StreamVideoOptions(
        keepConnectionsAliveWhenInBackground: true,
      ),
    );

    // _streamVideo = StreamVideo(
    //     'y8h5754fwgma', // Replace with your Stream API key
    //     user: User.regular(
    //         userId: '8586035683', name: "visitor" // Replace with your user ID
    //         ),
    //     userToken: token,
    //     options: const StreamVideoOptions(
    //       keepConnectionsAliveWhenInBackground: true,
    //     ));

    await _streamVideo.connect();
    _startCall();
  }

  Future<void> _startCall() async {
    try {
      setState(() {
        _isCallingUser = true;
      });

      // Create and join a call
      final callId = "call-$randomString";

      call = _streamVideo.makeCall(
        callType: StreamCallType.defaultType(),
        id: callId,
      );

      await call!
          .getOrCreate(memberIds: [calleeId], ringing: true, video: true);

      await call!.join();

      setState(() {
        _isCallingUser = false;
      });
    } catch (e) {
      debugPrint('Error starting call: $e');
      setState(() {
        _isCallingUser = false;
      });
    }
  }

  Future<void> _endCall() async {
    try {
      await call!.leave();
      await call!.end();
      setState(() {
        call = null;
      });
    } catch (e) {
      debugPrint('Error ending call: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (call != null) ...[
            StreamCallContainer(
              // Stream's pre-made component
              call: call!,
              callConnectOptions: CallConnectOptions(
                camera: TrackOption.enabled(),
                screenShare: TrackOption.disabled(),
                microphone: TrackOption.enabled(),
              ),

              callContentBuilder: (context, call, callState) {
                return StreamCallContent(
                  call: call,
                  callState: callState,
                  layoutMode: ParticipantLayoutMode.spotlight,
                  callAppBarBuilder: (context, call, callState) {
                    return AppBar(
                      actions: const [],
                    );
                  },
                  callControlsBuilder: (context, call, callState) {
                    return const StreamCallControls(options: [
                      // LeaveCallOption(call: call, onLeaveCallTap: call.leave)
                    ]);
                  },
                );
              },
            ),
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FloatingActionButton(
                    backgroundColor: Colors.red,
                    onPressed: _endCall,
                    child: const Icon(Icons.call_end),
                  ),
                ],
              ),
            ),
          ] else if (_isCallingUser)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Connecting to call...'),
                ],
              ),
            )
          else
            const Center(
              child: Text('Call ended'),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    call?.end();
    super.dispose();
  }
}
