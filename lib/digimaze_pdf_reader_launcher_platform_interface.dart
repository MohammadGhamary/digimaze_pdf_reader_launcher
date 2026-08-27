import 'package:digimaze_pdf_reader_launcher/models/dto/open_document_request.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _DefaultUnimplementedPlatform extends DigimazePdfReaderLauncherPlatform {}

abstract class DigimazePdfReaderLauncherPlatform extends PlatformInterface {

  DigimazePdfReaderLauncherPlatform() : super(token: _token);

  static final Object _token = Object();

  static DigimazePdfReaderLauncherPlatform _instance = _DefaultUnimplementedPlatform();

  static DigimazePdfReaderLauncherPlatform get instance => _instance;

  static set instance(DigimazePdfReaderLauncherPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<void> openDocument({required OpenDocumentRequest request}) {
    throw UnimplementedError('openDocument() has not been implemented.');
  }
}
