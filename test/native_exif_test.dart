import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:native_exif/native_exif.dart';

void main() {
  const MethodChannel channel = MethodChannel('native_exif');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await NativeExif.platformVersion, '42');
  });
}
