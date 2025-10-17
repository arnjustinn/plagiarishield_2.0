import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Extracts text from an image file using Google ML Kit's OCR (Optical Character Recognition).
///
/// Steps:
/// 1. Convert the input [File] into an [InputImage] for ML Kit.
/// 2. Create a [TextRecognizer] configured for Latin-based scripts.
/// 3. Process the image to detect and extract text.
/// 4. Close the recognizer to free resources.
/// 
/// [imageFile] → The image file (e.g., PNG, JPG) to be processed.
/// Returns a [String] containing the recognized text.
Future<String> extractTextFromImage(File imageFile) async {
  // Convert the file into an ML Kit compatible InputImage.
  final inputImage = InputImage.fromFile(imageFile);

  // Initialize the text recognizer (configured for Latin script).
  final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  // Process the image and extract recognized text.
  final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

  // Always close the recognizer after processing to release resources.
  await textRecognizer.close();

  // Return the extracted plain text.
  return recognizedText.text;
}
