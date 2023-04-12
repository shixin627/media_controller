import 'package:flutter_test/flutter_test.dart';
import 'package:media_controller/media_controller.dart';
import 'package:media_controller/media_controller_platform_interface.dart';
import 'package:media_controller/media_controller_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockMediaControllerPlatform
    with MockPlatformInterfaceMixin
    implements MediaControllerPlatform {

  @override
  Future<void> pause() {
    // TODO: implement pause
    throw UnimplementedError();
  }

  @override
  Future<void> play() {
    // TODO: implement play
    throw UnimplementedError();
  }

  @override
  Future<void> stop() {
    // TODO: implement stop
    throw UnimplementedError();
  }

  @override
  Future<void> previous() {
    // TODO: implement previous
    throw UnimplementedError();
  }

  @override
  Future<void> next() {
    // TODO: implement next
    throw UnimplementedError();
  }

  @override
  Future<List<String>> getActiveMediaSessions() {
    // TODO: implement getActiveMediaSessions
    throw UnimplementedError();
  }

  @override
  Future<String?> setCurrentMediaSession(String sessionToken) {
    // TODO: implement setCurrentMediaSession
    throw UnimplementedError();
  }

  @override
  // TODO: implement mediaSessionStream
  Stream<Map<String, dynamic>>? get mediaStream => throw UnimplementedError();
}

void main() {
  final MediaControllerPlatform initialPlatform = MediaControllerPlatform.instance;

  test('$MethodChannelMediaController is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelMediaController>());
  });

  test('play', () async {
    MediaController mediaControllerPlugin = MediaController();
    MockMediaControllerPlatform fakePlatform = MockMediaControllerPlatform();
    MediaControllerPlatform.instance = fakePlatform;
    await mediaControllerPlugin.play();
  });

  test('pause', () async {
    MediaController mediaControllerPlugin = MediaController();
    MockMediaControllerPlatform fakePlatform = MockMediaControllerPlatform();
    MediaControllerPlatform.instance = fakePlatform;
    await mediaControllerPlugin.pause();
  });

  test('stop', () async {
    MediaController mediaControllerPlugin = MediaController();
    MockMediaControllerPlatform fakePlatform = MockMediaControllerPlatform();
    MediaControllerPlatform.instance = fakePlatform;
    await mediaControllerPlugin.stop();
  });
}
