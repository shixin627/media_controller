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
  List<String> sessions = [];
  String? currentToken;

  @override
  void initState() {
    super.initState();
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
      print(currentToken);
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
                  await setSession(sessions.first);
                },
              ),
              SizedBox(height: 100, child: sessionList(sessions)),
              IconButton(
                icon: const Icon(Icons.check),
                onPressed: () async {
                  await setSession(sessions.first);
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
