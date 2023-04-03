import 'media_controller_platform_interface.dart';

class MediaController {
  Future<List<String>> getActiveMediaSessions() async {
    return MediaControllerPlatform.instance.getActiveMediaSessions();
  }

  Future<String?> setCurrentMediaSession(String sessionToken) async {
    return MediaControllerPlatform.instance
        .setCurrentMediaSession(sessionToken);
  }

  Future<void> play() {
    return MediaControllerPlatform.instance.play();
  }

  Future<void> pause() {
    return MediaControllerPlatform.instance.pause();
  }

  Future<void> stop() {
    return MediaControllerPlatform.instance.stop();
  }

  Stream<Map<String, dynamic>>? get mediaStream =>
      MediaControllerPlatform.instance.mediaStream;
}
