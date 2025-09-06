/// Represents the current playback state of a media session.
enum PlaybackStatus {
  /// No playback state is available.
  idle,
  
  /// The media is currently stopped.
  stopped,
  
  /// The media is currently paused.
  paused,
  
  /// The media is currently playing.
  playing,
  
  /// The media is currently fast forwarding.
  fastForwarding,
  
  /// The media is currently rewinding.
  rewinding,
  
  /// The media is currently buffering.
  buffering,
  
  /// An error occurred during playback.
  error,
  
  /// The media is connecting.
  connecting,
  
  /// The media is skipping to the previous track.
  skippingToPrevious,
  
  /// The media is skipping to the next track.
  skippingToNext,
  
  /// The media is skipping to a specific queue item.
  skippingToQueueItem,
}

/// Extension to convert platform state strings to enum values.
extension PlaybackStatusExtension on PlaybackStatus {
  /// Converts a platform state string to a [PlaybackStatus] enum.
  static PlaybackStatus fromString(String state) {
    switch (state) {
      case 'STATE_NONE':
        return PlaybackStatus.idle;
      case 'STATE_STOPPED':
        return PlaybackStatus.stopped;
      case 'STATE_PAUSED':
        return PlaybackStatus.paused;
      case 'STATE_PLAYING':
        return PlaybackStatus.playing;
      case 'STATE_FAST_FORWARDING':
        return PlaybackStatus.fastForwarding;
      case 'STATE_REWINDING':
        return PlaybackStatus.rewinding;
      case 'STATE_BUFFERING':
        return PlaybackStatus.buffering;
      case 'STATE_ERROR':
        return PlaybackStatus.error;
      case 'STATE_CONNECTING':
        return PlaybackStatus.connecting;
      case 'STATE_SKIPPING_TO_PREVIOUS':
        return PlaybackStatus.skippingToPrevious;
      case 'STATE_SKIPPING_TO_NEXT':
        return PlaybackStatus.skippingToNext;
      case 'STATE_SKIPPING_TO_QUEUE_ITEM':
        return PlaybackStatus.skippingToQueueItem;
      default:
        return PlaybackStatus.idle;
    }
  }
  
  /// Converts the enum to a string representation.
  String get displayName {
    switch (this) {
      case PlaybackStatus.idle:
        return 'Idle';
      case PlaybackStatus.stopped:
        return 'Stopped';
      case PlaybackStatus.paused:
        return 'Paused';
      case PlaybackStatus.playing:
        return 'Playing';
      case PlaybackStatus.fastForwarding:
        return 'Fast Forwarding';
      case PlaybackStatus.rewinding:
        return 'Rewinding';
      case PlaybackStatus.buffering:
        return 'Buffering';
      case PlaybackStatus.error:
        return 'Error';
      case PlaybackStatus.connecting:
        return 'Connecting';
      case PlaybackStatus.skippingToPrevious:
        return 'Skipping to Previous';
      case PlaybackStatus.skippingToNext:
        return 'Skipping to Next';
      case PlaybackStatus.skippingToQueueItem:
        return 'Skipping to Queue Item';
    }
  }
}