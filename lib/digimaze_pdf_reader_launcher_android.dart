import 'package:digimaze_pdf_reader_launcher/services/encryption_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'digimaze_pdf_reader_launcher_platform_interface.dart';
import 'models/dto/open_document_request.dart';

/// An implementation of [DigimazePdfReaderLauncherPlatform] that uses method channels.
class DigimazePdfReaderLauncherAndroid extends DigimazePdfReaderLauncherPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('digimaze_pdf_reader_launcher');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }

  @override
  Future<void> openDocument({required OpenDocumentRequest request}) async {
    methodChannel.setMethodCallHandler((call) async {
      if (call.method == "documentClosed") {
        if(request.pdfSource.onDocumentClosed != null){
          await request.pdfSource.onDocumentClosed!();
        }
      }
    });

    final String secureParams = await EncryptionService.generateAdvancedPdfReaderParams(request);

    methodChannel.invokeMethod('openDocument', {'params': secureParams});
  }
}
