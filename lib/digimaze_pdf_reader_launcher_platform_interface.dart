import 'package:digimaze_pdf_reader_launcher/digimaze_pdf_reader_launcher_android.dart';
import 'package:digimaze_pdf_reader_launcher/models/dto/open_document_request.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

abstract class DigimazePdfReaderLauncherPlatform extends PlatformInterface {

  DigimazePdfReaderLauncherPlatform() : super(token: _token);

  static final Object _token = Object();

  static DigimazePdfReaderLauncherPlatform _instance = DigimazePdfReaderLauncherAndroid();

  static DigimazePdfReaderLauncherPlatform get instance => _instance;

  static set instance(DigimazePdfReaderLauncherPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<void> openDocument({required OpenDocumentRequest request}) async {
    await _instance.openDocument(request: request);
  }
}
