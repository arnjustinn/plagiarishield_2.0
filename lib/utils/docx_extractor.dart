// lib/utils/docx_extractor.dart
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

/// Extracts plain text content from a `.docx` file.
/// 
/// A `.docx` file is essentially a zipped collection of XML files.
/// This function:
///   1. Decodes the zipped bytes.
///   2. Locates `word/document.xml` which holds the actual document text.
///   3. Parses the XML to extract all text nodes (`<w:t>`).
///   4. Concatenates the text into a single string with cleaned spacing.
///
/// [bytes] → The raw bytes of the `.docx` file.
/// Returns a [String] containing the extracted plain text.
Future<String> extractTextFromDocx(List<int> bytes) async {
  // Decode the zipped .docx file.
  final archive = ZipDecoder().decodeBytes(bytes);

  // Find the main document XML inside the archive.
  final documentFile = archive.firstWhere(
    (file) => file.name == 'word/document.xml',
    orElse: () => throw Exception('document.xml not found'),
  );

  // Convert the XML file content into a UTF-8 string.
  final documentXml = utf8.decode(documentFile.content as List<int>);

  // Parse the XML structure of the document.
  final xmlDoc = XmlDocument.parse(documentXml);

  // Collect all text elements inside <w:t> tags.
  final textBuffer = StringBuffer();
  for (final node in xmlDoc.findAllElements('w:t')) {
    textBuffer.write(node.text);
    textBuffer.write(' '); // Ensure words are separated.
  }

  // Normalize whitespace and return the extracted text.
  return textBuffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}
