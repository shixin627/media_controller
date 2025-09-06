import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_controller/media_controller_method_channel.dart';
import 'package:media_controller/src/platform/channel_constants.dart';

void main() {
  MethodChannelMediaController platform = MethodChannelMediaController();
  const MethodChannel methodChannel = MethodChannel(ChannelConstants.methodChannel);
  const EventChannel eventChannel = EventChannel(ChannelConstants.eventChannel);

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    methodChannel.setMockMethodCallHandler((MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'getActiveMediaSessions':
          return ['session1@com.example.app', 'session2@com.spotify.music'];
        case 'setCurrentMediaSession':
          return methodCall.arguments['sessionToken'];
        case 'play':
        case 'pause':
        case 'stop':
        case 'previous':
        case 'next':
          return null;
        default:
          return null;
      }
    });
  });

  tearDown(() {
    methodChannel.setMockMethodCallHandler(null);
  });

  group('MethodChannelMediaController', () {
    test('getActiveMediaSessions returns list of sessions', () async {
      final sessions = await platform.getActiveMediaSessions();
      expect(sessions, isA<List<String>>());
      expect(sessions.length, 2);
      expect(sessions[0], 'session1@com.example.app');
    });

    test('setCurrentMediaSession returns session token', () async {
      const testToken = 'test_session_token';
      final result = await platform.setCurrentMediaSession(testToken);
      expect(result, testToken);
    });

    test('play method call succeeds', () async {
      await expectLater(platform.play(), completes);
    });

    test('pause method call succeeds', () async {
      await expectLater(platform.pause(), completes);
    });

    test('stop method call succeeds', () async {
      await expectLater(platform.stop(), completes);
    });

    test('previous method call succeeds', () async {
      await expectLater(platform.previous(), completes);
    });

    test('next method call succeeds', () async {
      await expectLater(platform.next(), completes);
    });

    test('mediaStream is available on Android', () {
      // This test assumes we're running on a platform that reports as Android
      // In a real test environment, you'd mock Platform.isAndroid
      final stream = platform.mediaStream;
      expect(stream, isNotNull);
    });
  });
}
