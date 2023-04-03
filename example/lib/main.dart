import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_controller/media_controller.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _mediaControllerPlugin = MediaController();
  StreamSubscription<Map<String, dynamic>>? _subscription;
  List<String> sessions = [];
  String? currentToken;
  String? currentPlaybackState;

  @override
  void initState() {
    super.initState();
  }

  void startListening() {
    try {
      _subscription = _mediaControllerPlugin.mediaStream?.listen((data) {
        data.forEach((key, value) {
          switch (key) {
            case "sessions":
              {
                if (value != null) {
                  List<Object?> objectList = value;
                  List<String> stringList =
                      objectList.map((obj) => obj?.toString() ?? '').toList();
                  setState(() {
                    sessions = stringList;
                  });
                  print("sessions = $sessions");
                  if (sessions.isNotEmpty) {
                    setSession(sessions.first);
                  }
                }
              }
              break;
            case "PlaybackState":
              {
                if (value != null) {
                  setState(() {
                    currentPlaybackState = value;
                  });
                  print("PlaybackState = $currentPlaybackState");
                }
              }
              break;
            default:
              break;
          }
        });
      });
      if (_subscription != null) {
        setState(() {
          print('start listening');
        });
      }
    } on Exception catch (exception) {
      print(exception);
    }
  }

  void stopListening() {
    if (_subscription != null) {
      setState(() {
        _subscription?.cancel();
        _subscription = null;
        print('stop listening');
      });
    }
  }

  Widget sessionList(List<String> stringList) {
    return ListView.builder(
      itemCount: stringList.length,
      itemBuilder: (BuildContext context, int index) {
        return ListTile(
          title: Text(stringList[index].split("@").last),
          onTap: () async {
            await setSession(stringList[index]);
          },
        );
      },
    );
  }

  Future<void> setSession(String? token) async {
    if (token == null) {
      return;
    }
    if (sessions.isEmpty) {
      return;
    }
    currentToken = await _mediaControllerPlugin.setCurrentMediaSession(token);
    setState(() {
      print("setSession => $currentToken");
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Media Controller Demo'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.queue_music),
                onPressed: () async {
                  if (_subscription == null) {
                    startListening();
                  } else {
                    stopListening();
                  }
                },
              ),
              SizedBox(height: 100, child: sessionList(sessions)),
              IconButton(
                icon: const Icon(Icons.check),
                onPressed: () async {
                  if (sessions.isNotEmpty) {
                    await setSession(sessions.first);
                  }
                },
              ),
              Text(currentToken ?? "No token"),
              IconButton(
                icon: const Icon(Icons.play_arrow),
                onPressed: () {
                  _mediaControllerPlugin.play();
                },
              ),
              IconButton(
                icon: const Icon(Icons.pause),
                onPressed: () {
                  _mediaControllerPlugin.pause();
                },
              ),
              IconButton(
                icon: const Icon(Icons.stop),
                onPressed: () {
                  _mediaControllerPlugin.stop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
