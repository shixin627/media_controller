import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'media_controller_platform_interface.dart';

/// An implementation of [MediaControllerPlatform] that uses method channels.
class MethodChannelMediaController extends MediaControllerPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('media_controller');

  @override
  Future<List<String>> getActiveMediaSessions() async {
    List<Object?>? list = await methodChannel
        .invokeMethod<List<Object?>>('getActiveMediaSessions');
    if (list != null) {
      List<String>? sessions = list.whereType<String>().toList();
      return sessions ?? [];
    }
    return [];
  }

  @override
  Future<String?> setCurrentMediaSession(String sessionToken) async {
    final data = {"sessionToken": sessionToken};
    return await methodChannel.invokeMethod<String>(
        'setCurrentMediaSession', data);
  }

  @override
  Future<void> play() async {
    await methodChannel.invokeMethod<void>('play');
  }

  @override
  Future<void> pause() async {
    await methodChannel.invokeMethod<void>('pause');
  }

  @override
  Future<void> stop() async {
    await methodChannel.invokeMethod<void>('stop');
  }
}
