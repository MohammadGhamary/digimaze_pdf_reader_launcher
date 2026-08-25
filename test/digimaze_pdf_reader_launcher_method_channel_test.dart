import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digimaze_pdf_reader_launcher/digimaze_pdf_reader_launcher_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelDigimazePdfReaderLauncher platform = MethodChannelDigimazePdfReaderLauncher();
  const MethodChannel channel = MethodChannel('digimaze_pdf_reader_launcher');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return '42';
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
