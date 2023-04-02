import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_controller/media_controller_method_channel.dart';

void main() {
  MethodChannelMediaController platform = MethodChannelMediaController();
  const MethodChannel channel = MethodChannel('media_controller');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });
}
