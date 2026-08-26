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

      await DigimazePdfReaderLauncher.openDocument(
        OpenDocumentRequest(
          pdfReaderType: PdfReaderType.advanced,
          sdkLicense: SdkLicense(
              serialNumber: "Z0FBQUFBQnBteXhHdnZZbDdLaF9Vc2djd2F1MkN5MDY3UTAwMERoMUZZWlZIdFRfZ0lpOGxmUHlIUDU1QlBPakdiUEVOU09kcG9kSFdQblZ0YzkxQW80U3l4MFU4OUZyT2JOOWNLTHlZS3ZOZnNDWVBsaXJodjNGWWRnV0VSX1NJcGMzbVJnaFZnU1VBWWRTTTc4cTFvRk0za1dscVltZzVGMlBRSEJQUm1rUjNOOUxTX2FiTEN5YUNCOWFXM3pzdmlXUlpTdzA1OVBGSDhwQm1aQmRFc1R3UU42cWRiNExIam82b1JjaUIxRjFMTGVGcXJRM1I3djdwR0hBSFFxTmhpUWpPd1Y5NmlDMjIyNTdMYkttNlNIUU5FY01aMkhSbDB0aTR6SnZxLW9Gc1NEOGlxQXlaNzgtZF9xMEt4bzZWZUozdndFRWM5TFRxT1J2XzRla05PLVFrNEd4ZGtkbmRrem1oUWM1QTdGd3JlMnBBRzkwWlgwPQ==",
              key: "Z0FBQUFBQnBteXpIcUkxaVJkNXI4d0N3ay0ySXBUc1ZpQjJvelNBdnJZdzhsU1JRckNnZ0lHMmI4LVdiNS1hZV8zbEROQ3p2OERQR0g5ZUVMSFAwZUJnNWJoRFBhUFg2cXFlVnRLS0Nuekc0OGNObUh3VkVNMi0zZDY4dDI0QnBsU3dyNVVVb19JYW1ra1R1VGlVa2xqRkFvVUxNc3NjaUg3QzdRN0NMUk1nZnFXY3VBZW9ndDZlTXhUQVFQOEo3VUFhaF93YXl1X3dva2txSFdWa1ZvS2RCaFZQR0tuSGF3S3AwcTJ4V1IyZGg3cmRTeU1VdktETGNVdUNLN1ViT0V0OGNRenQ3ajNLX2V3NGo5blBLT1FkQ21MNE9CcEtEUVY4blZRWFpXdl93eFFKamRmR18xbU5WNEN5aTdsZHRlaXlkWVBUYjlVakJta1NqM1A5MlZ0RjBlejZ2V0d4cGVEMkxkU0xHM1g2YzZnaEpJYXZ6YUR6ZnUxSGxlbXhBblczR3IzTTZsR05qQzRualJwY2VuUXI5T01yM0dWMnZxM01zakRmc2RibHYxOEFhZFFnakJ4Y05jTDE4QkF3TWFIZDNCbmFvbF91bEZwYWdZb1poNEszTHl4X2tsVmdzV3JickJEZmFoRWJGZ0NaWG5URGZBdnJFRGxmakJINHlkcjJxaVJTRjZYUUFpZ0piU2FDODYtYlFvaWhzRTdsTWFBaWNqeWdyN01ZeHRjMjc1ZnYxMU1VRFl0WURmUElmRVhjMzZBZFJkS1hzdHVZMmJkLUdoTm1rUFpUUGUxT0RTWm9YekNLdm4xa1RUWl9WOVNVd2RKN3BHb0NsQktQVXYycmFlN0dEeEJKZ3h0dHZwa3lnck16d2Y4SEVKb040Y1pYeTlGRFp2VUtuNi1NRkNwblRLMkhIRlpOTnZITmVteFdRMlp5c2d1VUVtWm5fTmJDN3FwMVFEZ0RLSFd5WmxOSGdsWjJpZE1OaGhZUzN5VktFaXJLVTllQ08zLWt6d2Faa00waWk5QURMSW9GQ1dGa1RCMjJxOS1SdkUtLVVZNTl4Vk9rUkVsVWJ2Zi0yRHUtRklWaHhENC1QcWdZUzJhdnJxUEluemlSTWpGMklSbmFlYzQwUVliWHItMVQ4bHlQbWk0U3BmM1FpZWVhOG5sVkh5ZUhxZGxDWkhaRnZWZ1pBSWFOT2NOWmxhMXZwSE1ja0JDNkhBd0lsVml5QlJkcGt5dGlIYUZnN2U2X2FzU1RVTjQwYmZEZHBnMVJQOGtBVXo5RkNuV0xWT21welFVU0tpUFBreWdyLUVkZl81X0RERjQ1VnNaQ0RKa05xVzluQzcwZFAtNjlNVF95WEV0NmFrUEpYb0ptbVJRWlMtTEdraWdXdEM0dlRDM1lCNE81Nk5LVGRHOGNiM01CVXZQZnNvN1QtOU1INkw4eVJlTjRHaEhSTjZlODNyOGNQN1VHcXYybUJmU2IzMVlhenFwV3JBdEdjQmdpcS12UUlNWWVOVkdLTktJbTFMek1XV25GQl94N2hPaW0yMWtkcjlEVzFzQ19vMTNIZEpyck1ETFc5MXU0NHduVnh1bDc5TXZxUkg0RWNYZ2wwMTdReDFWTm04VkJNeFZHZXBZT2VIVVlfV2xGWlNMaTRlZkNtVHBOTEdQSnlBcEFxeUQ5b1IxOVNoNHhwcEZiNmtIS2l0LVRGdG9sN2twV05lVW84TVlxSTl1MmRuenBxNC1JbnIwcW9KbkhHdE95R0l1LXlaVGItb3RJZ2FPbVJjYUhZa2dGQWJnODdtM3kwLXRwR0FyWEJnQ0FqVVRaY3Vndm03VS0xOXo3b3ptS05tRERzWmZjU1VNMFRxeTNhWlcwYW1HUzRCWVVHdmNBblIwaXotc1NXMUM1bUJmRUpUZEhLLWdZelFIbEpkS0NDZWdLOXZBUEcwem9rb1VQSzZCUm1ScFo5Q1JoSU9yUWRxSEJZa0RUVm03ekdLdmdCcGl2ckx0ck1WZ3RmYm5DRkUyY2F1TkhYWTU5OFFoeGFZQXJqbHgzU0t2azNZWEpxanltYmNSdHpISUhpamdlYjR6UGROaE5DNzNOUlJuTFItNUlmOFRwbm4yNzVUTjk1VTJaOS1XNjlEaTgyeHBRTThvX2I2bTdwaXFvbWxqeEtXRWJEenFQWnc2dzBJNVlVRXZ5WHJqMUpjcElMTUxXWC1MbVVKS19uVHJTa1pvLS1HcVg5MXpicE1tODVWNXJYSXFpZ3UtSnBQMUQ0bThSNjNhLURZT29SZ1NndTdCVzhqVWEyYjczakVfWFRRU2NVdHRzd0d5d3Rfa1V1aUhiaHZpQzlEdz09",
              encryptionKey: "39bb053719f593fdf8851fc73367834d"
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
      _platformVersion = "platformVersion";
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
