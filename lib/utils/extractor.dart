import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:xml/xml.dart' as xml;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';

/// Extracts text content from a `.docx` file
Future<String> extractTextFromDocx(Uint8List bytes) async {
  final archive = ZipDecoder().decodeBytes(bytes);
  final documentFile = archive.firstWhere((f) => f.name == 'word/document.xml');
  final documentXml = xml.XmlDocument.parse(
    String.fromCharCodes(documentFile.content as List<int>),
  );

  final buffer = StringBuffer();
  for (final node in documentXml.findAllElements('w:p')) {
    for (final text in node.findAllElements('w:t')) {
      buffer.write(text.text);
    }
    buffer.writeln();
  }
  return buffer.toString();
}

/// Extracts text from a PDF file using Syncfusion PDF library
Future<String> extractTextFromPdf(Uint8List bytes) async {
  final document = PdfDocument(inputBytes: bytes);
  final buffer = StringBuffer();
  try {
    for (int i = 0; i < document.pages.count; i++) {
      final text = PdfTextExtractor(document)
          .extractText(startPageIndex: i, endPageIndex: i);
      buffer.writeln(text);
    }
  } finally {
    document.dispose();
  }
  return buffer.toString();
}

/// Picks an image file and extracts text using Google ML Kit OCR
Future<String?> extractTextFromImage() async {
  final imageTypeGroup =
      XTypeGroup(label: 'images', extensions: ['jpg', 'jpeg', 'png']);
  final file = await openFile(acceptedTypeGroups: [imageTypeGroup]);
  if (file == null) return null;

  // Save image temporarily for ML Kit to process
  final tempDir = await getTemporaryDirectory();
  final imagePath = '${tempDir.path}/${file.name}';
  final imageFile = File(imagePath);
  await imageFile.writeAsBytes(await file.readAsBytes());

  // OCR using Google ML Kit
  final inputImage = InputImage.fromFile(imageFile);
  final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final recognizedText = await textRecognizer.processImage(inputImage);
  await textRecognizer.close();

  return recognizedText.text;
}
