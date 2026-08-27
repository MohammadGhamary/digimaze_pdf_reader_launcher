import 'package:digimaze_pdf_reader_launcher/models/dto/pdf_source.dart';
import 'package:digimaze_pdf_reader_launcher/models/dto/sdk_license.dart';
import 'package:digimaze_pdf_reader_launcher/models/dto/study_log_api_details.dart';
import 'package:digimaze_pdf_reader_launcher/models/enums/pdf_reader_type.dart';

class OpenDocumentRequest {
  final PdfReaderType pdfReaderType;
  final PdfSource pdfSource;
  final Function? onDocumentClosed;
  final SdkLicense? sdkLicense;
  final StudyLogApiDetails? studyLogApiDetails;

  OpenDocumentRequest({
    required this.pdfReaderType,
    required this.pdfSource,
    this.onDocumentClosed,
    this.sdkLicense,
    this.studyLogApiDetails,
  });
}