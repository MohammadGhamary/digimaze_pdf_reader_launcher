import 'dart:io';

import 'package:digimaze_pdf_reader_launcher/models/enums/pdf_reader_type.dart';
import 'package:flutter/foundation.dart';

import 'digimaze_pdf_reader_launcher_platform_interface.dart';
import 'models/dto/open_document_request.dart';
import 'services/encryption_service.dart';

class DigimazePdfReaderLauncherWindows extends DigimazePdfReaderLauncherPlatform {

  static void registerWith() {
    DigimazePdfReaderLauncherPlatform.instance = DigimazePdfReaderLauncherWindows();
  }

  @override
  Future<String?> getPlatformVersion() async {
    return 'Windows ${Platform.operatingSystemVersion}';
  }

  @override
  Future<void> openDocument({required OpenDocumentRequest request}) async {
    try {

      switch (request.pdfReaderType) {
        case PdfReaderType.advanced:
          {
            final String secureParams = await EncryptionService.generateAdvancedPdfReaderParams(request);
            final exeDir = File(Platform.resolvedExecutable).parent;
            await Process.run('digimaze_pdf_reader_tauri.exe', ['--params', secureParams], workingDirectory: exeDir.path);
            break;
          }
        case PdfReaderType.classic:
          {
            final String secureParams = await EncryptionService.generateClassicPdfReaderParams(request);
            final exeDir = File(Platform.resolvedExecutable).parent;
            await Process.run('Digimaze_PDF_Reader.exe', [secureParams], workingDirectory: exeDir.path);
            break;
          }
      }

      if (request.onDocumentClosed != null) {
        await request.onDocumentClosed!();
      }
    } catch (e) {
      debugPrint("Windows Advanced Process Error: $e");
    }
  }
}
