import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_controller/media_controller.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Media Controller Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MediaControllerDemo(),
    );
  }
}

class MediaControllerDemo extends StatefulWidget {
  const MediaControllerDemo({super.key});

  @override
  State<MediaControllerDemo> createState() => _MediaControllerDemoState();
}

class _MediaControllerDemoState extends State<MediaControllerDemo> {
  // Use the new MediaControllerManager for better functionality
  final _controller = MediaControllerManager();
  
  // Legacy controller for backward compatibility demonstration
  final _legacyController = MediaController();
  
  StreamSubscription<MediaPlaybackState>? _subscription;
  List<MediaSessionInfo> _sessions = [];
  MediaPlaybackState? _currentState;
  bool _isInitialized = false;
  bool _isListening = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initializeController() async {
    try {
      await _controller.initialize();
      setState(() {
        _isInitialized = true;
        _errorMessage = null;
      });
      await _loadSessions();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize: $e';
      });
    }
  }

  Future<void> _loadSessions() async {
    if (!_isInitialized) return;
    
    try {
      final sessions = await _controller.getActiveMediaSessions();
      setState(() {
        _sessions = sessions;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load sessions: $e';
      });
    }
  }

  void _startListening() {
    if (!_isInitialized || _isListening) return;
    
    try {
      _subscription = _controller.mediaUpdates.listen(
        (state) {
          setState(() {
            _currentState = state;
            _errorMessage = null;
          });
        },
        onError: (error) {
          setState(() {
            _errorMessage = 'Stream error: $error';
          });
        },
      );
      
      setState(() {
        _isListening = true;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to start listening: $e';
      });
    }
  }

  void _stopListening() {
    _subscription?.cancel();
    _subscription = null;
    setState(() {
      _isListening = false;
    });
  }

  Future<void> _selectSession(MediaSessionInfo session) async {
    try {
      await _controller.setCurrentMediaSession(session.sessionToken);
      setState(() {
        _errorMessage = null;
      });
      
      // Start listening automatically when a session is selected
      if (!_isListening) {
        _startListening();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to select session: $e';
      });
    }
  }

  Future<void> _executeMediaAction(Future<void> Function() action, String actionName) async {
    try {
      await action();
      setState(() {
        _errorMessage = null;
      });
    } on PlatformException catch (e) {
      setState(() {
        _errorMessage = '$actionName failed: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _errorMessage = '$actionName failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Media Controller Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Initialization status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Controller Status',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _isInitialized ? Icons.check_circle : Icons.error,
                          color: _isInitialized ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(_isInitialized ? 'Initialized' : 'Not Initialized'),
                      ],
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Sessions list
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Active Media Sessions (${_sessions.length})',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        IconButton(
                          onPressed: _isInitialized ? _loadSessions : null,
                          icon: const Icon(Icons.refresh),
                          tooltip: 'Refresh Sessions',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_sessions.isEmpty)
                      const Text('No active media sessions found')
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _sessions.length,
                        itemBuilder: (context, index) {
                          final session = _sessions[index];
                          return ListTile(
                            leading: const Icon(Icons.music_note),
                            title: Text(session.displayName),
                            subtitle: Text('State: ${session.state}'),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: () => _selectSession(session),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Current playback state
            if (_currentState != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Now Playing',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      if (_currentState!.title != null) ...[
                        Text(
                          _currentState!.title!,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 4),
                      ],
                      if (_currentState!.artist != null) ...[
                        Text(
                          _currentState!.artist!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        'State: ${PlaybackStatusExtension.fromString(_currentState!.playbackState).displayName}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (_currentState!.positionMs != null && _currentState!.durationMs != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          '${_currentState!.formattedPosition} / ${_currentState!.formattedDuration}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (_currentState!.progress != null)
                          LinearProgressIndicator(
                            value: _currentState!.progress,
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Listening controls
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Media Updates',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isInitialized && !_isListening ? _startListening : null,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Start Listening'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _isListening ? _stopListening : null,
                          icon: const Icon(Icons.stop),
                          label: const Text('Stop Listening'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Media controls
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Playback Controls',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          onPressed: _isInitialized 
                              ? () => _executeMediaAction(_controller.previous, 'Previous')
                              : null,
                          icon: const Icon(Icons.skip_previous),
                          iconSize: 32,
                          tooltip: 'Previous',
                        ),
                        IconButton(
                          onPressed: _isInitialized 
                              ? () => _executeMediaAction(_controller.play, 'Play')
                              : null,
                          icon: const Icon(Icons.play_arrow),
                          iconSize: 48,
                          tooltip: 'Play',
                        ),
                        IconButton(
                          onPressed: _isInitialized 
                              ? () => _executeMediaAction(_controller.pause, 'Pause')
                              : null,
                          icon: const Icon(Icons.pause),
                          iconSize: 48,
                          tooltip: 'Pause',
                        ),
                        IconButton(
                          onPressed: _isInitialized 
                              ? () => _executeMediaAction(_controller.stop, 'Stop')
                              : null,
                          icon: const Icon(Icons.stop),
                          iconSize: 32,
                          tooltip: 'Stop',
                        ),
                        IconButton(
                          onPressed: _isInitialized 
                              ? () => _executeMediaAction(_controller.next, 'Next')
                              : null,
                          icon: const Icon(Icons.skip_next),
                          iconSize: 32,
                          tooltip: 'Next',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
