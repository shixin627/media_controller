import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'media_controller_method_channel.dart';

abstract class MediaControllerPlatform extends PlatformInterface {
  /// Constructs a MediaControllerPlatform.
  MediaControllerPlatform() : super(token: _token);

  static final Object _token = Object();

  static MediaControllerPlatform _instance = MethodChannelMediaController();

  /// The default instance of [MediaControllerPlatform] to use.
  ///
  /// Defaults to [MethodChannelMediaController].
  static MediaControllerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [MediaControllerPlatform] when
  /// they register themselves.
  static set instance(MediaControllerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<List<String>> getActiveMediaSessions() {
    throw UnimplementedError('getActiveMediaSessions() has not been implemented.');
  }

  Future<String?> setCurrentMediaSession(String? sessionToken) {
    throw UnimplementedError(
        'setCurrentMediaSession() has not been implemented.');
  }

  Future<void> play() {
    throw UnimplementedError('play() has not been implemented.');
  }

  Future<void> pause() {
    throw UnimplementedError('pause() has not been implemented.');
  }

  Future<void> stop() {
    throw UnimplementedError('stop() has not been implemented.');
  }

  Future<void> previous() {
    throw UnimplementedError('previous() has not been implemented.');
  }

  Future<void> next() {
    throw UnimplementedError('next() has not been implemented.');
  }

  Future<bool> isNotificationListenerEnabled() {
    throw UnimplementedError('isNotificationListenerEnabled() has not been implemented.');
  }

  Future<bool> openNotificationListenerSettings() {
    throw UnimplementedError('openNotificationListenerSettings() has not been implemented.');
  }

  Stream<Map<String, dynamic>>? get mediaStream;
}
