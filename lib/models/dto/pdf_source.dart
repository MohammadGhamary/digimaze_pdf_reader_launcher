import '../enums/pdf_type.dart';

class PdfSource {
  final int bookId;
  final String? attachmentId;
  final String title;
  String filePath;
  final String? password;
  final Function? onDocumentClosed;
  final PdfType type;

  PdfSource.book({
    required this.bookId,
    required this.title,
    required this.filePath,
    required this.password,
    this.onDocumentClosed,
  }) : type = PdfType.book,
       attachmentId = null;

  PdfSource.attachment({
    required this.bookId,
    required this.attachmentId,
    required this.title,
    required this.filePath,
    required this.password,
    this.onDocumentClosed,
  }) : type = PdfType.attachment;

  PdfSource.sample({
    required this.bookId,
    required this.title,
    required this.filePath,
    this.password,
    this.onDocumentClosed,
  }) : type = PdfType.sample,
       attachmentId = null;

  bool get isSample => type == PdfType.sample;

  bool get isBook => type == PdfType.book;

  bool get isAttachment => type == PdfType.attachment;
}
