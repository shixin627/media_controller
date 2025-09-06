/// Standard error codes used by the media_controller plugin.
class MediaControllerErrorCodes {
  /// Method requires initialization first.
  static const String notInitialized = 'not_initialized';
  
  /// Plugin has already been initialized.
  static const String alreadyInitialized = 'already_initialized';
  
  /// Invalid argument provided (null/empty URL, negative seek, etc.).
  static const String invalidArgument = 'invalid_argument';
  
  /// Platform or feature not implemented.
  static const String unsupportedOperation = 'unsupported_operation';
  
  /// Underlying media player failure.
  static const String playerError = 'player_error';
  
  /// Unexpected internal error.
  static const String internalError = 'internal_error';
}

/// Channel names used for communication with platform implementations.
class ChannelConstants {
  /// The method channel name for media controller operations.
  static const String methodChannel = 'flutter.io/media_controller/methodChannel';
  
  /// The event channel name for media state updates.
  static const String eventChannel = 'flutter.io/media_controller/eventChannel';
}