import 'package:digimaze_pdf_reader_launcher/models/dto/open_document_request.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digimaze_pdf_reader_launcher/digimaze_pdf_reader_launcher.dart';
import 'package:digimaze_pdf_reader_launcher/digimaze_pdf_reader_launcher_platform_interface.dart';
import 'package:digimaze_pdf_reader_launcher/digimaze_pdf_reader_launcher_android.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockDigimazePdfReaderLauncherPlatform
    with MockPlatformInterfaceMixin
    implements DigimazePdfReaderLauncherPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<void> openDocument({required OpenDocumentRequest request}) {
    // TODO: implement openDocument
    throw UnimplementedError();
  }
}

void main() {
  final DigimazePdfReaderLauncherPlatform initialPlatform = DigimazePdfReaderLauncherPlatform.instance;

  test('$DigimazePdfReaderLauncherAndroid is the default instance', () {
    expect(initialPlatform, isInstanceOf<DigimazePdfReaderLauncherAndroid>());
  });

  test('getPlatformVersion', () async {
    MockDigimazePdfReaderLauncherPlatform fakePlatform = MockDigimazePdfReaderLauncherPlatform();
    DigimazePdfReaderLauncherPlatform.instance = fakePlatform;

    expect(await DigimazePdfReaderLauncher.getPlatformVersion(), '42');
  });
}
