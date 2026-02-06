import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

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

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final _plugin = MediaController();
  StreamSubscription<Map<String, dynamic>>? _subscription;

  bool _permissionGranted = false;
  List<_SessionInfo> _sessions = [];
  String? _selectedToken;
  String? _currentTitle;
  String? _currentArtist;
  String? _currentPlaybackState;
  Uint8List? _currentAlbumArt;

  bool get _isPlaying => _currentPlaybackState == 'STATE_PLAYING';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermission();
    }
  }

  Future<void> _checkPermission() async {
    final enabled = await _plugin.isNotificationListenerEnabled();
    setState(() => _permissionGranted = enabled);
  }

  // ── Event handling ──────────────────────────────────────────────

  void _startListening() {
    _subscription = _plugin.mediaStream?.listen(_onEvent);
    if (_subscription != null) {
      _plugin.getActiveMediaSessions();
    }
  }

  void _stopListening() {
    _subscription?.cancel();
    _subscription = null;
    setState(() {
      _sessions = [];
      _selectedToken = null;
      _clearMediaInfo();
    });
  }

  void _onEvent(Map<String, dynamic> data) {
    if (data.containsKey('sessions')) {
      _handleSessionsEvent(data);
    } else if (data.containsKey('notifyChanged')) {
      _plugin.getActiveMediaSessions();
    } else {
      _handleMediaUpdate(data);
    }
  }

  void _handleSessionsEvent(Map<String, dynamic> data) {
    final list = data['sessions'] as List<dynamic>;
    if (list.isEmpty) return;
    final inner = Map<String, dynamic>.from(list.first as Map);

    final tokens = List<String>.from(inner['tokens'] as List);
    final packages = List<String>.from(inner['packages'] as List);
    final states = List<String>.from(inner['states'] as List);
    final titles = List<String>.from(inner['titles'] as List);
    final albumArts = inner['albumArts'] != null
        ? List<String>.from(inner['albumArts'] as List)
        : <String>[];

    setState(() {
      _sessions = List.generate(tokens.length, (i) {
        return _SessionInfo(
          token: tokens[i],
          packageName: packages[i],
          state: states[i],
          title: titles[i],
          albumArt: i < albumArts.length && albumArts[i].isNotEmpty
              ? albumArts[i]
              : null,
        );
      });
    });
  }

  void _handleMediaUpdate(Map<String, dynamic> data) {
    setState(() {
      if (data.containsKey('PlaybackState')) {
        _currentPlaybackState = data['PlaybackState'] as String?;
      }
      if (data.containsKey('Title')) {
        _currentTitle = data['Title'] as String?;
      }
      if (data.containsKey('Artist')) {
        _currentArtist = data['Artist'] as String?;
      }
      if (data.containsKey('AlbumArt')) {
        final art = data['AlbumArt'] as String?;
        _currentAlbumArt =
            (art != null && art.isNotEmpty) ? base64Decode(art) : null;
      }
    });
  }

  void _clearMediaInfo() {
    _currentTitle = null;
    _currentArtist = null;
    _currentPlaybackState = null;
    _currentAlbumArt = null;
  }

  Future<void> _selectSession(String token) async {
    final result = await _plugin.setCurrentMediaSession(token);
    if (result != null) {
      setState(() => _selectedToken = token);
    }
  }

  // ── UI ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1C1C1E),
      ),
      home: Scaffold(
        body: SafeArea(
          child: _permissionGranted ? _buildMain() : _buildPermissionPage(),
        ),
      ),
    );
  }

  Widget _buildPermissionPage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.notifications_off_outlined,
                size: 64, color: Colors.white54),
            const SizedBox(height: 16),
            const Text('Notification Listener Required',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text(
              'Enable notification access to control media sessions.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => _plugin.openNotificationListenerSettings(),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMain() {
    final listening = _subscription != null;
    return Column(
      children: [
        // Top bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Text('Media Controller',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const Spacer(),
              IconButton(
                icon: Icon(listening ? Icons.stop_circle : Icons.play_circle,
                    color: listening ? Colors.redAccent : Colors.white),
                onPressed: () {
                  setState(() {
                    listening ? _stopListening() : _startListening();
                  });
                },
              ),
            ],
          ),
        ),
        // Session chips
        if (_sessions.isNotEmpty)
          SizedBox(
            height: 40,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _sessions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final s = _sessions[i];
                final selected = s.token == _selectedToken;
                return ChoiceChip(
                  label: Text(s.packageName.split('.').last),
                  selected: selected,
                  onSelected: (_) => _selectSession(s.token),
                  selectedColor: Colors.white24,
                  backgroundColor: Colors.white10,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : Colors.white70,
                  ),
                );
              },
            ),
          ),
        // Now Playing card
        Expanded(
          child: Center(
            child: _buildNowPlayingCard(),
          ),
        ),
      ],
    );
  }

  Widget _buildNowPlayingCard() {
    if (_selectedToken == null && _sessions.isEmpty) {
      return const Text('No active sessions',
          style: TextStyle(color: Colors.white38));
    }
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Album art
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _currentAlbumArt != null
                ? Image.memory(_currentAlbumArt!,
                    width: 240, height: 240, fit: BoxFit.cover)
                : Container(
                    width: 240,
                    height: 240,
                    color: const Color(0xFF3A3A3C),
                    child: const Icon(Icons.music_note,
                        size: 64, color: Colors.white24),
                  ),
          ),
          const SizedBox(height: 20),
          // Title & Artist
          Text(
            _currentTitle ?? '-',
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            _currentArtist ?? '-',
            style: const TextStyle(fontSize: 15, color: Colors.white54),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 24),
          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                iconSize: 36,
                icon:
                    const Icon(Icons.skip_previous, color: Colors.white),
                onPressed: () => _plugin.previous(),
              ),
              const SizedBox(width: 16),
              _buildPlayPauseButton(),
              const SizedBox(width: 16),
              IconButton(
                iconSize: 36,
                icon: const Icon(Icons.skip_next, color: Colors.white),
                onPressed: () => _plugin.next(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayPauseButton() {
    return GestureDetector(
      onTap: () => _isPlaying ? _plugin.pause() : _plugin.play(),
      child: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(
          _isPlaying ? Icons.pause : Icons.play_arrow,
          color: Colors.black,
          size: 32,
        ),
      ),
    );
  }
}

class _SessionInfo {
  final String token;
  final String packageName;
  final String state;
  final String title;
  final String? albumArt;

  _SessionInfo({
    required this.token,
    required this.packageName,
    required this.state,
    required this.title,
    this.albumArt,
  });
}
