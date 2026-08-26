import 'package:digimaze_pdf_reader_launcher/models/dto/open_document_request.dart';

import 'digimaze_pdf_reader_launcher_platform_interface.dart';

class DigimazePdfReaderLauncher {
  static Future<String?> getPlatformVersion() {
    return DigimazePdfReaderLauncherPlatform.instance.getPlatformVersion();
  }

  static Future<void> openDocument(OpenDocumentRequest request) {
    return DigimazePdfReaderLauncherPlatform.instance.openDocument(request: request);
  }
}
