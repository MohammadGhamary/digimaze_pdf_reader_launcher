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
          await DigimazePdfReaderLauncher.getPlatformVersion() ??
          'Unknown platform version';

      await DigimazePdfReaderLauncher.openDocument(
        OpenDocumentRequest(
          pdfReaderType: PdfReaderType.classic,
          sdkLicense: SdkLicense(
              serialNumber: "Z0FBQUFBQnFmd2JmVTdlamVpUHlMZTJDQ2JhTmhjTU5nWlljZFBCZmpYb1hlMEgxeDZkMWZzZHZVQzRQdURFQUhZT1FYa2hXVUYyb2g1TDV3TXZCWENHd1B5aVR4aVFZMTNQdjBfSDEyd1JpM1F0SnE1N2daeFZhb1RuemktWEE5dzFFTVVEamxmV21FQWxQZ2hJYm80aW9uc01tbXAzMlhzSzNSTGJlWUFLN3FlT2x1SU4yeVBjVGZjdE1kbmJfN0pBdDhlNHdOdThSTXpwTGw5eWZfenhFMk9scW4xZlpRZUY2SExMZ19UMWY0RHh0NHBMNk5QMDMyWXJvWlY2LS1GYVp4MTJSem00S0Vib1hlSFcxX3gyaWEyb3BmTEhEeGpsMEtZWjlkZlpMTnY1bUQ1c3oyV1hZVi04N3dxU0w4NEViS2lZWk9Gd2dSRXRQMHRtSEhoaEdvWWIxeDVyaFdkak9KRXd1YVdmd1V5aEdFdWdOcnZRPQ==",
              key: "Z0FBQUFBQnFmd2RMN2Z1NWYtRWZXTk9QZ095UjRUUTdtU2JHNkg0T0syNGRCbkdnUHEzbWRhM2tLd01RdFZ6cFZnQWNJYUF4bzlqWmwycDRzdzNrcGhMSG55bnhBWjgtT0JJUnBVQTBLY3ZnSGlyRDFaU2ExWmpkZ3luRGRaMDdTUXZwaG1zZUVtTGVKNWx0VmxNWUFRV2pBd0lNdTNpMjlmNkhQdVNocFRNZjNZcjlfS08ydzY4VkR1aW12YWFGQ01UVzNRdXViR0tBZWx1ejBaejJHX204eEFjNUc1TFZEa2N1SGJBQjNfeFpVT0ZhREUxeGlvWlJ5WVRpTjJMbkxUR2lHUm5Qb1YtcGZqMWdHbURLdlBiaUpBZnZ0U04xWlA2XzZsVXlpTkdBaWJqNDhBTkl3eHdZbkhKcHRQNDh4Wm96MXZmZHotYWx1RW5BczRZcVFfcG13UV9KOW8zcVRuZHp1b0hMQTQ4SVJfajVGN3BSbTBZSzU2ODBzQUhQcC1VZ01NVlg3ajJubVUyWi1Cbm9TSU9aVkhZaGJkVEZZU2pDX2NJSGNYLUt5S2lLWVk1N1VUNDc1NTludkdaN09kSjRuUmNmNW1UMmw2MVhrRFJzMlVPenY4WkxEbFVwY0pCYnNKcThJRVFoTGpyWHV0bHpoVU1Gb3pySURDNk5LRFVINkF4OWVpemNPOE5uSzl5WXRtRnE0Y1JSYk9wQXl0cUd1dFVmTFBPODlQd1dwSGJLSV9mbEJGUDRza0tHTDRiZjh2VEJobThld3VFOFdQTUVZRUFGTXhMemViYVJWZDBLWkp2QmRvMWYxLWh6UEs0SlhmNzVua3VsU1g1eFl4bHpQN3o5YmNKM0ZMWEtrSzJ6dkwyMl9qTlBPN0drbDc0WXJIWHE3cDVWa3N0WUV6TDMwcDZBRWNuUkNzZkd6d05vQkpzcExTdF9YZmNVVFlSdjZLTGstYUFMd0Z0ZGVHTmFnSlZDWWZlUm1YcWQzUS02LUxhYlAxbkFaMWpVdzg5dGRKdU9HeGxGdk9yVWNJdnFiVnlodHNfVmxJRXV0VC1sWWpPdnF6Z0FYZWRKN0E4NWcyVWgxYjhlbEh0cTYtekRGNWNiVnd5ZXlORzZhano5Ynl1eVI1U1Y0bDRfNzdGcDJiWjEzZWFfME9RT0Y3XzFkd3Y4b2lHQlhNVXNDWUgtT3JEb2dnRzV2OTcwVmdzZnRVellrR2JPQVZlc3dzdktYcWhZR3BjamxVTTJwTGVTS3NkNWc1blg1RHg1Mk9sQTRPN2tiT0E0ODRGc29ndk41ZmdONkdfRUllZGRjNWdMUU9EWjFyWGxjSE82enNHZmxKaThVVDljODdUTnNELWdKT0c3c3dWY3NfYkpwdlJSUG9tOUhFemdXRFJNSThWWHJuMzBWRWZIYWVZeGhibllaM25xMGg1cjhuNE1lNTRyTW5VUndNaS1ERFdrbF9lb0U4OWNvWnh6YlhLeC1XaUJ6Mmo5TXpnRGNkcVdhNktpeVZQd2F6S0haNFV3VzlfOC04akdFLXRXR0FqNk8tay1LenV3aEpBbVVLYmJOX3pYMm8yOFZSNG1Ob01UN3IzV2ZDRjVZY0dGRXRpX1U0VnFWbWJlbGM4Nk1IN21VNURqek5SS2RrZWt0TnR0bWI3SGJKX0ltbUtMVXR0dkxDVFZ4bjVMekdxbHYyQWVpU1JtN1JjOEtTNmZlZU1IZjFfWEhoS3I1d0pwWnZJMjMyTTAtbEgyb1NSbC1tcm83eFVUV2Znd253bjJyLTNiVGJ0TXpYSzNiaThvazBpaENpam5tbTZRQmZiMUhpa0FBaTRnZUVDbVJvX1l5R0RfZVc0em51cFd3ZkRJWV96VjZUb0tzTUkzQmRGX0ZDQ1BCQnpBLXJfVS1RM1lBeTVOR0hlOGRyLWdvQjFSdmQyREFsTnllX29SQV9RbmxtQlUxcVN1c0o4ZGlXamJEelBrMzFyejdoWDZ6dGc4dTZnVzBRSXRadkY3RzU0WVhXQ05PNXBTRjBFOXJlc3JhWTBsa2lWckpXMEZDOWdIVVJlRFVCQUVpWTI0cWEtOVlGS0hISWpVOXA5Qlo1OHB1MzFGVlBKTk1odFV1am5kdlBUdTV6eDEzNFJObzJ6VHFUZXJsMkl6NXdNbEdHU0UwdWNSeGJnRkJIQUFUUE5GMHhyUlVpV3NTeWh6Tm9WY3ZQMTFSS3kzZTVFOGoyX3JEUHZlalluUGZ6cV9McjBWZm04T1MtU1QzcnpiZHFXLUNhWmhnMlRpWXljeGVCZVRjdlBrbTdYM0RmeFZJb2dE",
              encryptionKey: "8b4d4fde9aae6deb93655f9028a3585f"
          ),
          studyLogApiDetails: StudyLogApiDetails(logApiUrl: "logApiUrl", authToken: "authToken", deviceUID: "deviceUID", appVersion: "appVersion"),
          pdfSource: PdfSource.attachment(
            bookId: 1029,
            attachmentId: "685d8f2d79587b2eb81357ef",
            title: "بانک کنکور ریاضی دوازدهم (فصل۱: تابع)",
            filePath: "/data/user/0/com.vnegar.digimaze/app_flutter/attachment_1029_685d8f2d79587b2eb81357ef.pdf",
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
