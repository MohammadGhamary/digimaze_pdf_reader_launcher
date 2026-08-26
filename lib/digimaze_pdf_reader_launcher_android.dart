import 'package:digimaze_pdf_reader_launcher/services/encryption_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'digimaze_pdf_reader_launcher_platform_interface.dart';
import 'models/dto/open_document_request.dart';
import 'models/enums/pdf_reader_type.dart';

/// An implementation of [DigimazePdfReaderLauncherPlatform] that uses method channels.
class DigimazePdfReaderLauncherAndroid
    extends DigimazePdfReaderLauncherPlatform {
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
    try {

      switch (request.pdfReaderType) {
        case PdfReaderType.advanced:
          {
            final String targetPath = await methodChannel.invokeMethod(
              'getFileContentUri',
              {"path": request.pdfSource.filePath},
            );

            request.pdfSource.filePath = targetPath;

            final String secureParams =
            await EncryptionService.generateAdvancedPdfReaderParams(
              request,
            );
            methodChannel.invokeMethod('openDocumentWithAdvancedPdfReader', {
              'params': secureParams,
              'path': targetPath
            });
          }
        case PdfReaderType.classic:
          {
            methodChannel.setMethodCallHandler((call) async {
              if (call.method == "documentClosed") {
                if (request.pdfSource.onDocumentClosed != null) {
                  await request.pdfSource.onDocumentClosed!();
                }
              }
            });

            final String secureParams =
                await EncryptionService.generateAdvancedPdfReaderParams(
                  request,
                );
            methodChannel.invokeMethod('openDocumentWithClassicPdfReader', {
              'params': secureParams,
            });
          }
      }

      if (request.pdfSource.onDocumentClosed != null) {
        await request.pdfSource.onDocumentClosed!();
      }
    } catch (e) {
      debugPrint("Windows Advanced Process Error: $e");
    }
  }
}
