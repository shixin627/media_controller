/// A Flutter plugin for controlling media sessions on Android devices.
/// 
/// This library provides interfaces for discovering and controlling active
/// media sessions, allowing your app to interact with media playback from
/// other applications.
library media_controller;

// Export main controller classes
export 'src/controller.dart';

// Export model classes
export 'src/models/media_playback_state.dart';
export 'src/models/media_session_info.dart';
export 'src/models/playback_state.dart';

// Export platform constants
export 'src/platform/channel_constants.dart';

// Legacy compatibility exports
export 'media_controller_platform_interface.dart';

import 'media_controller_platform_interface.dart';

/// Legacy MediaController class for backward compatibility.
/// 
/// **Deprecated**: Use [MediaControllerManager] instead for better type safety,
/// error handling, and additional features.
/// 
/// This class maintains the original API to ensure existing code continues
/// to work, but new development should use the improved [MediaControllerManager].
@Deprecated('Use MediaControllerManager instead')
class MediaController {
  /// Gets a list of active media session tokens.
  /// 
  /// **Deprecated**: Use [MediaControllerManager.getActiveMediaSessions] instead.
  @Deprecated('Use MediaControllerManager.getActiveMediaSessions instead')
  Future<List<String>> getActiveMediaSessions() async {
    return MediaControllerPlatform.instance.getActiveMediaSessions();
  }

  /// Sets the current media session to control.
  /// 
  /// **Deprecated**: Use [MediaControllerManager.setCurrentMediaSession] instead.
  @Deprecated('Use MediaControllerManager.setCurrentMediaSession instead')
  Future<String?> setCurrentMediaSession(String? sessionToken) async {
    return MediaControllerPlatform.instance
        .setCurrentMediaSession(sessionToken);
  }

  /// Starts or resumes playback.
  /// 
  /// **Deprecated**: Use [MediaControllerManager.play] instead.
  @Deprecated('Use MediaControllerManager.play instead')
  Future<void> play() {
    return MediaControllerPlatform.instance.play();
  }

  /// Pauses playback.
  /// 
  /// **Deprecated**: Use [MediaControllerManager.pause] instead.
  @Deprecated('Use MediaControllerManager.pause instead')
  Future<void> pause() {
    return MediaControllerPlatform.instance.pause();
  }

  /// Stops playback.
  /// 
  /// **Deprecated**: Use [MediaControllerManager.stop] instead.
  @Deprecated('Use MediaControllerManager.stop instead')
  Future<void> stop() {
    return MediaControllerPlatform.instance.stop();
  }

  /// Skips to the previous track.
  /// 
  /// **Deprecated**: Use [MediaControllerManager.previous] instead.
  @Deprecated('Use MediaControllerManager.previous instead')
  Future<void> previous() {
    return MediaControllerPlatform.instance.previous();
  }

  /// Skips to the next track.
  /// 
  /// **Deprecated**: Use [MediaControllerManager.next] instead.
  @Deprecated('Use MediaControllerManager.next instead')
  Future<void> next() {
    return MediaControllerPlatform.instance.next();
  }

  /// Gets a stream of media state updates.
  /// 
  /// **Deprecated**: Use [MediaControllerManager.mediaUpdates] instead.
  @Deprecated('Use MediaControllerManager.mediaUpdates instead')
  Stream<Map<String, dynamic>>? get mediaStream =>
      MediaControllerPlatform.instance.mediaStream;
}
