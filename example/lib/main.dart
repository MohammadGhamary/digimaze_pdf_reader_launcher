import 'package:digimaze_pdf_reader_launcher/models/dto/open_document_request.dart';
import 'package:digimaze_pdf_reader_launcher/models/dto/pdf_source.dart';
import 'package:digimaze_pdf_reader_launcher/models/dto/sdk_license.dart';
import 'package:digimaze_pdf_reader_launcher/models/dto/study_log_api_details.dart';
import 'package:digimaze_pdf_reader_launcher/models/enums/pdf_reader_type.dart';
import 'package:flutter/material.dart';

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:digimaze_pdf_reader_launcher/digimaze_pdf_reader_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  final _digimazePdfReaderLauncherPlugin = DigimazePdfReaderLauncher();

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion =
          await _digimazePdfReaderLauncherPlugin.getPlatformVersion() ??
          'Unknown platform version';

      await _digimazePdfReaderLauncherPlugin.openDocument(
        OpenDocumentRequest(
          pdfReaderType: PdfReaderType.advanced,
          sdkLicense: SdkLicense(
              serialNumber: "u1+hcYZwEwcTl792/He7A/L7AjtZad6/04O//bYxxt4e3qlOELL14/PqSoSLwF2xvxTx4VAhWxqlYqOyxDpo7omSAEb0SEl+i5+Gw6l4x3A8gWIG24qpTcUxq8jpAYKgEoAojgJUeMP2wyAbXVfUhXI7gmETZN65Hl4Eq1MbAIaci9ALyZYZEk1bBvd85GUySDPYNjK5Kt6ikVfwFS4eLTqWWeOj+ibzCUlKeN2Nt/ALjbhrSMCMqB1T+SeXk+knWiHJ6v+DrDcX4jFngOhLOq7eIEvitslIxAIHdZV6vXlNEkTzS2606Wd+jdcbBRDYi6+X1csl8OiJecGW6LMVGlE0wIditDRUYMk4Gz5sg4+s+A5qnwgsHQytY2WkO124/M+fvo1hidTImAgBrtEckRVMNJyhB5FbUHCypRwG4FPiMPE77oQyYp2h4cDxqt66BuhGOKzn8BP6ciC6U5KkcWh5QdMkw/qvoMDCgCEXnPmi90SWO18z5+npXxHqeJIW4Ykj3FyltN6YKDBxO8bZQNahyX72S+dmfHhYg3c2SOvHQomdL0/XrzjDNOLYgcio7R8LyYOw2RH/2ZZsS/ItmEMAfWghIDdFdsJKCtfHT+wQ4++LSZB8O2fHRNtc/fBp+/xT293gM1k2azTQjWPN50M8Izb69BCtyrbClKOWfLs=",
              key: "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",
              encryptionKey: "lh5aUhEFt1vfGQN0AVr1+zLTWxSKoEdeMTSOEXprwxVKRVVFyx6QDBfAe9uhiJjk"
          ),
          studyLogApiDetails: StudyLogApiDetails(logApiUrl: "logApiUrl", authToken: "authToken", deviceUID: "deviceUID", appVersion: "appVersion"),
          pdfSource: PdfSource.attachment(
            bookId: 1029,
            attachmentId: "685d8f2d79587b2eb81357ef",
            title: "بانک کنکور ریاضی دوازدهم (فصل۱: تابع)",
            filePath: "C:\\Users\\Mohammad\\AppData\\Roaming\\com.vnegar\\digimaze\\attachment_1029_685d8f2d79587b2eb81357ef.pdf",
            password: "KWxqQZaw%&6c^7tbkJ\$&mgFBdcjNN!v8",
          ),
        ),
      );
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Plugin example app')),
        body: Center(child: Text('Running on: $_platformVersion\n')),
      ),
    );
  }
}
