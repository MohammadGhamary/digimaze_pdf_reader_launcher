import 'package:digimaze_pdf_reader_launcher/services/encryption_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'digimaze_pdf_reader_launcher_platform_interface.dart';
import 'models/dto/open_document_request.dart';
import 'models/enums/pdf_reader_type.dart';

class DigimazePdfReaderLauncherAndroid
    extends DigimazePdfReaderLauncherPlatform {

  static void registerWith() {
    DigimazePdfReaderLauncherPlatform.instance = DigimazePdfReaderLauncherAndroid();
  }

  @visibleForTesting
  final methodChannel = const MethodChannel('digimaze_pdf_reader_launcher');

  final _classicPdfReaderConfigurations = {
    "modules": {
      "readingbookmark": true,
      "outline": true,
      "annotations": {
        "highlight": true,
        "underline": true,
        "squiggly": true,
        "strikeout": true,
        "insert": true,
        "replace": true,
        "line": true,
        "rectangle": true,
        "oval": true,
        "arrow": true,
        "pencil": true,
        "eraser": true,
        "typewriter": true,
        "textbox": true,
        "callout": true,
        "note": true,
        "stamp": true,
        "polygon": true,
        "cloud": true,
        "polyline": true,
        "measure": true,
        "image": true,
        "audio": true,
        "redaction": true,
      },
      "thumbnail": false,
      "attachment": true,
      "signature": false,
      "fillSign": false,
      "search": true,
      "navigation": true,
      "form": false,
      "selection": true,
      "encryption": true,
      "multipleSelection": true,
    },
    "permissions": {
      "runJavaScript": false,
      "copyText": false,
      "disableLink": false,
    },
    "uiSettings": {
      "pageMode": "Single",
      "continuous": true,
      "rightToLeft": true,
      "reflowBackgroundColor": "#FFFFFF",
      "zoomMode": "FitWidth",
      "colorMode": "Normal",
      "mapForegroundColor": "#5d5b71",
      "mapBackgroundColor": "#00001b",
      "disableFormNavigationBar": false,
      "highlightForm": true,
      "highlightFormColor": "#200066cc",
      "highlightLink": true,
      "highlightLinkColor": "#16007fff",
      "fullscreen": true,
      "showPenOnlySwitch": true,
      "enableHandwritingRecognition": false,
      "enableTopbarDraggable": 2,
      "annotations": {
        "continuouslyAdd": true,
        "highlight": {"color": "#ffff00", "opacity": 1.0},
        "areaHighlight": {"color": "#ffff00", "opacity": 1.0},
        "underline": {"color": "#66cc33", "opacity": 1.0},
        "squiggly": {"color": "#993399", "opacity": 1.0},
        "strikeout": {"color": "#ff0000", "opacity": 1.0},
        "insert": {"color": "#993399", "opacity": 1.0},
        "replace": {"color": "#0000ff", "opacity": 1.0},
        "line": {"color": "#ff0000", "opacity": 1.0, "thickness": 2},
        "rectangle": {
          "color": "#ff0000",
          "opacity": 1.0,
          "thickness": 2,
          "fillColor": null,
        },
        "oval": {
          "color": "#ff0000",
          "opacity": 1.0,
          "thickness": 2,
          "fillColor": null,
        },
        "arrow": {"color": "#ff0000", "opacity": 1.0, "thickness": 2},
        "pencil": {"color": "#ff0000", "opacity": 1.0, "thickness": 2},
        "polygon": {
          "color": "#ff0000",
          "opacity": 1.0,
          "thickness": 2,
          "fillColor": null,
        },
        "cloud": {
          "color": "#ff0000",
          "opacity": 1.0,
          "thickness": 2,
          "fillColor": null,
        },
        "polyline": {"color": "#ff0000", "opacity": 1.0, "thickness": 2},
        "typewriter": {
          "textColor": "#0000ff",
          "opacity": 1.0,
          "textFace": "Courier",
          "textSize": 18,
        },
        "textbox": {
          "color": "#ff0000",
          "textColor": "#0000ff",
          "opacity": 1.0,
          "textFace": "Courier",
          "textSize": 18,
        },
        "callout": {
          "color": "#ff0000",
          "textColor": "#0000ff",
          "opacity": 1.0,
          "textFace": "Courier",
          "textSize": 18,
        },
        "note": {"color": "#ff0000", "opacity": 1.0, "icon": "Comment"},
        "attachment": {"color": "#ff0000", "opacity": 1.0, "icon": "PushPin"},
        "image": {"rotation": 0, "opacity": 1.0},
        "measure": {
          "color": "#ff0000",
          "opacity": 1.0,
          "thickness": 2,
          "scaleFromUnit": "inch",
          "scaleToUnit": "inch",
          "scaleFromValue": 1,
          "scaleToValue": 1,
        },
        "redaction": {
          "fillColor": "#000000",
          "textColor": "#ff0000",
          "textFace": "Courier",
          "textSize": 12,
        },
      },
      "form": {
        "textField": {
          "textColor": "#000000",
          "textFace": "Courier",
          "textSize": 0,
        },
        "checkBox": {"textColor": "#000000"},
        "radioButton": {"textColor": "#000000"},
        "comboBox": {
          "textColor": "#000000",
          "textFace": "Courier",
          "textSize": 0,
          "customText": false,
        },
        "listBox": {
          "textColor": "#000000",
          "textFace": "Courier",
          "textSize": 0,
          "multipleSelection": false,
        },
      },
      "signature": {"color": "#000000", "thickness": 8},
    },
    "optimizations": {"optimizeEmbeddedFontsForAnnots": false},
  };

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
            methodChannel.setMethodCallHandler((call) async {
              if (call.method == "documentClosed") {
                if (request.onDocumentClosed != null) {
                  await request.onDocumentClosed!();
                }
              }
            });

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
                if (request.onDocumentClosed != null) {
                  await request.onDocumentClosed!();
                }
              }
            });

            final String? secureParams = await EncryptionService.generateClassicPdfReaderParams(request);

            if(secureParams != null) {
              methodChannel.invokeMethod('openDocumentWithClassicPdfReader', {
                'params': secureParams,
                "configurations": _classicPdfReaderConfigurations
              });
            }
          }
      }
    } catch (e) {
      debugPrint("Windows Advanced Process Error: $e");
    }
  }
}
