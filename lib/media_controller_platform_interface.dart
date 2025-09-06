import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'media_controller_method_channel.dart';

/// The interface that platform-specific implementations of media_controller must implement.
/// 
/// Platform implementations should register themselves using the [instance] setter.
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

  /// Gets a list of currently active media session tokens.
  /// 
  /// Returns a list of string tokens that uniquely identify active
  /// media sessions on the device.
  Future<List<String>> getActiveMediaSessions() {
    throw UnimplementedError('getActiveMediaSessions() has not been implemented.');
  }

  /// Sets the current media session to control.
  /// 
  /// [sessionToken] is a unique identifier for the media session.
  /// Returns the session token if successful, null otherwise.
  Future<String?> setCurrentMediaSession(String? sessionToken) {
    throw UnimplementedError(
        'setCurrentMediaSession() has not been implemented.');
  }

  /// Starts or resumes playback of the current media session.
  Future<void> play() {
    throw UnimplementedError('play() has not been implemented.');
  }

  /// Pauses playback of the current media session.
  Future<void> pause() {
    throw UnimplementedError('pause() has not been implemented.');
  }

  /// Stops playback of the current media session.
  Future<void> stop() {
    throw UnimplementedError('stop() has not been implemented.');
  }

  /// Skips to the previous track in the current media session.
  Future<void> previous() {
    throw UnimplementedError('previous() has not been implemented.');
  }

  /// Skips to the next track in the current media session.
  Future<void> next() {
    throw UnimplementedError('next() has not been implemented.');
  }

  /// Gets a stream of media state updates.
  /// 
  /// Returns a stream that emits updates whenever the current media
  /// session's state changes, including metadata and playback state changes.
  Stream<Map<String, dynamic>>? get mediaStream;
}
