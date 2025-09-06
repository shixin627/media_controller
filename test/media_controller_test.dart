import 'package:flutter_test/flutter_test.dart';
import 'package:media_controller/media_controller.dart';
import 'package:media_controller/media_controller_platform_interface.dart';
import 'package:media_controller/media_controller_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:flutter/services.dart';

class MockMediaControllerPlatform
    with MockPlatformInterfaceMixin
    implements MediaControllerPlatform {

  @override
  Future<void> pause() {
    return Future.value();
  }

  @override
  Future<void> play() {
    return Future.value();
  }

  @override
  Future<void> stop() {
    return Future.value();
  }

  @override
  Future<void> previous() {
    return Future.value();
  }

  @override
  Future<void> next() {
    return Future.value();
  }

  @override
  Future<List<String>> getActiveMediaSessions() {
    return Future.value(['session1@com.example.app', 'session2@com.spotify.music']);
  }

  @override
  Future<String?> setCurrentMediaSession(String? sessionToken) {
    return Future.value(sessionToken);
  }

  @override
  Stream<Map<String, dynamic>>? get mediaStream => Stream.fromIterable([
    {
      'PlaybackState': 'STATE_PLAYING',
      'Title': 'Test Song',
      'Artist': 'Test Artist',
      'Package': 'com.example.app',
    }
  ]);
}

void main() {
  final MediaControllerPlatform initialPlatform = MediaControllerPlatform.instance;

  test('$MethodChannelMediaController is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelMediaController>());
  });

  group('Legacy MediaController', () {
    late MockMediaControllerPlatform mockPlatform;
    late MediaController controller;

    setUp(() {
      mockPlatform = MockMediaControllerPlatform();
      MediaControllerPlatform.instance = mockPlatform;
      controller = MediaController();
    });

    tearDown(() {
      MediaControllerPlatform.instance = initialPlatform;
    });

    test('play calls platform play', () async {
      await controller.play();
      // No exceptions should be thrown
    });

    test('pause calls platform pause', () async {
      await controller.pause();
      // No exceptions should be thrown
    });

    test('stop calls platform stop', () async {
      await controller.stop();
      // No exceptions should be thrown
    });

    test('previous calls platform previous', () async {
      await controller.previous();
      // No exceptions should be thrown
    });

    test('next calls platform next', () async {
      await controller.next();
      // No exceptions should be thrown
    });

    test('getActiveMediaSessions returns session list', () async {
      final sessions = await controller.getActiveMediaSessions();
      expect(sessions, isA<List<String>>());
      expect(sessions.length, 2);
      expect(sessions[0], 'session1@com.example.app');
    });

    test('setCurrentMediaSession returns session token', () async {
      const testToken = 'test_session_token';
      final result = await controller.setCurrentMediaSession(testToken);
      expect(result, testToken);
    });

    test('mediaStream provides updates', () async {
      final stream = controller.mediaStream;
      expect(stream, isNotNull);
      
      final event = await stream!.first;
      expect(event['PlaybackState'], 'STATE_PLAYING');
      expect(event['Title'], 'Test Song');
      expect(event['Artist'], 'Test Artist');
    });
  });

  group('MediaControllerManager', () {
    late MediaControllerManager controller;

    setUp(() {
      controller = MediaControllerManager();
    });

    tearDown(() async {
      if (controller.isInitialized) {
        await controller.dispose();
      }
    });

    test('starts uninitialized', () {
      expect(controller.isInitialized, false);
    });

    test('throws error when accessing methods before initialization', () {
      expect(
        () => controller.play(),
        throwsA(isA<PlatformException>()
            .having((e) => e.code, 'code', 'not_initialized')),
      );
    });

    test('throws error when accessing mediaUpdates before initialization', () {
      expect(
        () => controller.mediaUpdates,
        throwsA(isA<PlatformException>()
            .having((e) => e.code, 'code', 'not_initialized')),
      );
    });

    test('initializes successfully', () async {
      // Mock the method channel to avoid platform errors in test
      const channel = MethodChannel('flutter.io/media_controller/methodChannel');
      channel.setMockMethodCallHandler((call) async => null);
      
      await controller.initialize();
      expect(controller.isInitialized, true);
    });

    test('throws error on double initialization', () async {
      const channel = MethodChannel('flutter.io/media_controller/methodChannel');
      channel.setMockMethodCallHandler((call) async => null);
      
      await controller.initialize();
      
      expect(
        () => controller.initialize(),
        throwsA(isA<PlatformException>()
            .having((e) => e.code, 'already_initialized')),
      );
    });

    test('disposes properly', () async {
      const channel = MethodChannel('flutter.io/media_controller/methodChannel');
      channel.setMockMethodCallHandler((call) async => null);
      
      await controller.initialize();
      await controller.dispose();
      expect(controller.isInitialized, false);
    });
  });

  group('Data Models', () {
    test('MediaSessionInfo fromMap works correctly', () {
      final map = {
        'sessionToken': 'token123',
        'packageName': 'com.example.app',
        'state': 'STATE_PLAYING',
        'title': 'Test Song',
        'artist': 'Test Artist',
        'album': 'Test Album',
      };

      final info = MediaSessionInfo.fromMap(map);
      expect(info.sessionToken, 'token123');
      expect(info.packageName, 'com.example.app');
      expect(info.state, 'STATE_PLAYING');
      expect(info.title, 'Test Song');
      expect(info.artist, 'Test Artist');
      expect(info.album, 'Test Album');
    });

    test('MediaSessionInfo displayName extracts correctly', () {
      final info = MediaSessionInfo(
        sessionToken: 'token',
        packageName: 'com.spotify.music',
        state: 'STATE_PLAYING',
      );
      expect(info.displayName, 'music');
    });

    test('MediaPlaybackState fromMap works correctly', () {
      final map = {
        'PlaybackState': 'STATE_PLAYING',
        'Title': 'Test Song',
        'Artist': 'Test Artist',
        'Package': 'com.example.app',
        'positionMs': 30000,
        'durationMs': 180000,
      };

      final state = MediaPlaybackState.fromMap(map);
      expect(state.playbackState, 'STATE_PLAYING');
      expect(state.title, 'Test Song');
      expect(state.artist, 'Test Artist');
      expect(state.packageName, 'com.example.app');
      expect(state.positionMs, 30000);
      expect(state.durationMs, 180000);
    });

    test('MediaPlaybackState formatting works correctly', () {
      final state = MediaPlaybackState(
        playbackState: 'STATE_PLAYING',
        positionMs: 75000,  // 1:15
        durationMs: 195000,  // 3:15
      );

      expect(state.formattedPosition, '01:15');
      expect(state.formattedDuration, '03:15');
      expect(state.progress, closeTo(0.38, 0.01));
    });

    test('PlaybackStatus fromString works correctly', () {
      expect(
        PlaybackStatusExtension.fromString('STATE_PLAYING'),
        PlaybackStatus.playing,
      );
      expect(
        PlaybackStatusExtension.fromString('STATE_PAUSED'),
        PlaybackStatus.paused,
      );
      expect(
        PlaybackStatusExtension.fromString('INVALID_STATE'),
        PlaybackStatus.idle,
      );
    });

    test('PlaybackStatus displayName works correctly', () {
      expect(PlaybackStatus.playing.displayName, 'Playing');
      expect(PlaybackStatus.paused.displayName, 'Paused');
      expect(PlaybackStatus.buffering.displayName, 'Buffering');
    });
  });
}
