import 'dart:async';

import 'package:flutter/services.dart';

import '../models/media_playback_state.dart';
import '../models/media_session_info.dart';
import '../models/playback_state.dart';
import '../platform/channel_constants.dart';

/// The main controller class for managing media sessions.
/// 
/// This class provides a unified interface for controlling media playback
/// across different media sessions on Android devices. It allows you to:
/// 
/// - Discover active media sessions
/// - Select and control a specific media session
/// - Receive real-time updates about playback state
/// - Control playback (play, pause, stop, skip)
/// 
/// Example usage:
/// ```dart
/// final controller = MediaControllerManager();
/// 
/// // Listen for media updates
/// controller.mediaUpdates.listen((state) {
///   print('Now playing: ${state.title}');
///   print('State: ${state.playbackState}');
/// });
/// 
/// // Get active sessions and select one
/// final sessions = await controller.getActiveMediaSessions();
/// if (sessions.isNotEmpty) {
///   await controller.setCurrentMediaSession(sessions.first.sessionToken);
///   await controller.play();
/// }
/// ```
class MediaControllerManager {
  /// The method channel for communicating with platform implementations.
  static const MethodChannel _methodChannel = MethodChannel(ChannelConstants.methodChannel);
  
  /// The event channel for receiving media state updates.
  static const EventChannel _eventChannel = EventChannel(ChannelConstants.eventChannel);
  
  /// Stream controller for media state updates.
  StreamController<MediaPlaybackState>? _mediaStreamController;
  
  /// Subscription to the platform event stream.
  StreamSubscription<Map<String, dynamic>>? _platformSubscription;
  
  /// Whether the controller is currently initialized.
  bool _isInitialized = false;

  /// Gets a stream of media playback state updates.
  /// 
  /// This stream emits updates whenever the current media session's
  /// playback state changes, including metadata updates, position changes,
  /// and state transitions.
  Stream<MediaPlaybackState> get mediaUpdates {
    _ensureInitialized();
    return _mediaStreamController!.stream;
  }

  /// Gets whether the controller is currently initialized.
  bool get isInitialized => _isInitialized;

  /// Initializes the media controller.
  /// 
  /// This must be called before using any other methods.
  /// Throws a [PlatformException] with code [MediaControllerErrorCodes.alreadyInitialized]
  /// if already initialized.
  Future<void> initialize() async {
    if (_isInitialized) {
      throw PlatformException(
        code: MediaControllerErrorCodes.alreadyInitialized,
        message: 'MediaController has already been initialized',
      );
    }

    try {
      _mediaStreamController = StreamController<MediaPlaybackState>.broadcast();
      
      // Start listening to platform events
      _platformSubscription = _eventChannel
          .receiveBroadcastStream()
          .cast<Map<String, dynamic>>()
          .listen(_handlePlatformUpdate);
      
      _isInitialized = true;
    } catch (e) {
      throw PlatformException(
        code: MediaControllerErrorCodes.internalError,
        message: 'Failed to initialize MediaController: $e',
      );
    }
  }

  /// Disposes of the media controller and releases resources.
  /// 
  /// This should be called when the controller is no longer needed
  /// to prevent memory leaks.
  Future<void> dispose() async {
    await _platformSubscription?.cancel();
    _platformSubscription = null;
    
    await _mediaStreamController?.close();
    _mediaStreamController = null;
    
    _isInitialized = false;
  }

  /// Gets a list of currently active media sessions.
  /// 
  /// Returns a list of [MediaSessionInfo] objects representing
  /// all media sessions that are currently active on the device.
  /// 
  /// Throws a [PlatformException] if not initialized or if an error occurs.
  Future<List<MediaSessionInfo>> getActiveMediaSessions() async {
    _ensureInitialized();
    
    try {
      final List<Object?>? result = await _methodChannel
          .invokeMethod<List<Object?>>('getActiveMediaSessions');
      
      if (result == null) return [];
      
      return result
          .whereType<String>()
          .map((sessionToken) => MediaSessionInfo(
                sessionToken: sessionToken,
                packageName: _extractPackageName(sessionToken),
                state: 'STATE_NONE',
              ))
          .toList();
    } on PlatformException {
      rethrow;
    } catch (e) {
      throw PlatformException(
        code: MediaControllerErrorCodes.internalError,
        message: 'Failed to get active media sessions: $e',
      );
    }
  }

  /// Sets the current media session to control.
  /// 
  /// [sessionToken] is the unique identifier for the media session,
  /// typically obtained from [getActiveMediaSessions].
  /// 
  /// Returns the session token if successful, null otherwise.
  /// 
  /// Throws a [PlatformException] if not initialized, if the session token
  /// is invalid, or if an error occurs.
  Future<String?> setCurrentMediaSession(String sessionToken) async {
    _ensureInitialized();
    
    if (sessionToken.isEmpty) {
      throw PlatformException(
        code: MediaControllerErrorCodes.invalidArgument,
        message: 'Session token cannot be empty',
      );
    }

    try {
      final data = {'sessionToken': sessionToken};
      return await _methodChannel.invokeMethod<String>(
        'setCurrentMediaSession',
        data,
      );
    } on PlatformException {
      rethrow;
    } catch (e) {
      throw PlatformException(
        code: MediaControllerErrorCodes.internalError,
        message: 'Failed to set current media session: $e',
      );
    }
  }

  /// Starts or resumes playback of the current media session.
  /// 
  /// Throws a [PlatformException] if not initialized or if an error occurs.
  Future<void> play() async {
    _ensureInitialized();
    
    try {
      await _methodChannel.invokeMethod<void>('play');
    } on PlatformException {
      rethrow;
    } catch (e) {
      throw PlatformException(
        code: MediaControllerErrorCodes.playerError,
        message: 'Failed to play media: $e',
      );
    }
  }

  /// Pauses playback of the current media session.
  /// 
  /// Throws a [PlatformException] if not initialized or if an error occurs.
  Future<void> pause() async {
    _ensureInitialized();
    
    try {
      await _methodChannel.invokeMethod<void>('pause');
    } on PlatformException {
      rethrow;
    } catch (e) {
      throw PlatformException(
        code: MediaControllerErrorCodes.playerError,
        message: 'Failed to pause media: $e',
      );
    }
  }

  /// Stops playback of the current media session.
  /// 
  /// Throws a [PlatformException] if not initialized or if an error occurs.
  Future<void> stop() async {
    _ensureInitialized();
    
    try {
      await _methodChannel.invokeMethod<void>('stop');
    } on PlatformException {
      rethrow;
    } catch (e) {
      throw PlatformException(
        code: MediaControllerErrorCodes.playerError,
        message: 'Failed to stop media: $e',
      );
    }
  }

  /// Skips to the previous track in the current media session.
  /// 
  /// Throws a [PlatformException] if not initialized or if an error occurs.
  Future<void> previous() async {
    _ensureInitialized();
    
    try {
      await _methodChannel.invokeMethod<void>('previous');
    } on PlatformException {
      rethrow;
    } catch (e) {
      throw PlatformException(
        code: MediaControllerErrorCodes.playerError,
        message: 'Failed to skip to previous track: $e',
      );
    }
  }

  /// Skips to the next track in the current media session.
  /// 
  /// Throws a [PlatformException] if not initialized or if an error occurs.
  Future<void> next() async {
    _ensureInitialized();
    
    try {
      await _methodChannel.invokeMethod<void>('next');
    } on PlatformException {
      rethrow;
    } catch (e) {
      throw PlatformException(
        code: MediaControllerErrorCodes.playerError,
        message: 'Failed to skip to next track: $e',
      );
    }
  }

  /// Ensures the controller is initialized, throwing an exception if not.
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw PlatformException(
        code: MediaControllerErrorCodes.notInitialized,
        message: 'MediaController must be initialized before use. Call initialize() first.',
      );
    }
  }

  /// Handles updates from the platform event stream.
  void _handlePlatformUpdate(Map<String, dynamic> data) {
    try {
      // Handle different types of updates
      if (data.containsKey('PlaybackState') || data.containsKey('Title')) {
        // This is a playback state update
        final state = MediaPlaybackState.fromMap(data);
        _mediaStreamController?.add(state);
      }
      // Additional event types can be handled here in the future
    } catch (e) {
      // Log error but don't crash the stream
      print('Error handling platform update: $e');
    }
  }

  /// Extracts the package name from a session token.
  /// 
  /// Session tokens typically contain package information after '@'.
  String _extractPackageName(String sessionToken) {
    final parts = sessionToken.split('@');
    return parts.length > 1 ? parts.last : 'unknown';
  }
}