import 'package:flutter_test/flutter_test.dart';
import 'package:digimaze_pdf_reader_launcher/digimaze_pdf_reader_launcher.dart';
import 'package:digimaze_pdf_reader_launcher/digimaze_pdf_reader_launcher_platform_interface.dart';
import 'package:digimaze_pdf_reader_launcher/digimaze_pdf_reader_launcher_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockDigimazePdfReaderLauncherPlatform
    with MockPlatformInterfaceMixin
    implements DigimazePdfReaderLauncherPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final DigimazePdfReaderLauncherPlatform initialPlatform = DigimazePdfReaderLauncherPlatform.instance;

  test('$MethodChannelDigimazePdfReaderLauncher is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelDigimazePdfReaderLauncher>());
  });

  test('getPlatformVersion', () async {
    DigimazePdfReaderLauncher digimazePdfReaderLauncherPlugin = DigimazePdfReaderLauncher();
    MockDigimazePdfReaderLauncherPlatform fakePlatform = MockDigimazePdfReaderLauncherPlatform();
    DigimazePdfReaderLauncherPlatform.instance = fakePlatform;

    expect(await digimazePdfReaderLauncherPlugin.getPlatformVersion(), '42');
  });
}
