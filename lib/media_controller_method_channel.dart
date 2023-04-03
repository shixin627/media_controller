import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'media_controller_platform_interface.dart';

/// An implementation of [MediaControllerPlatform] that uses method channels.
class MethodChannelMediaController extends MediaControllerPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel(
      'flutter.io/media_controller/methodChannel');
  final eventChannel = const EventChannel(
      'flutter.io/media_controller/eventChannel');

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

  Map<String, dynamic> convertMap(dynamic data) {
    return Map<String, dynamic>.from(data as Map<dynamic, dynamic>).cast<String, dynamic>();
  }

  @override
  Stream<Map<String, dynamic>>? get mediaStream {
    if (Platform.isAndroid) {
      Stream<Map<String, dynamic>> stream = eventChannel
          .receiveBroadcastStream()
          .map((event) {
        Map<String, dynamic> data = convertMap(event);
        return data;
      });
      return stream;
    }

    return null;
  }


}
