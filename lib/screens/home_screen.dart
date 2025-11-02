import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'report_screen.dart';
import 'package:plagiarishield_sim/widgets/bottom_nav_bar.dart';
import '../utils/extractor.dart';
import 'package:plagiarishield_sim/storage/credential_storage.dart'; // <-- IMPORT ITO

/// HomeScreen - Main screen for checking plagiarism
/// Allows users to input text manually, upload documents, or extract text from images.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// Global controllers & state values
final TextEditingController _manualController = TextEditingController();
int _charCount = 0; // Tracks live character count in manual text input

class _HomeScreenState extends State<HomeScreen> {
  String inputText = '';
  String _username = ''; // <-- BAGONG STATE VARIABLE

  @override
  void initState() {
    super.initState();
    _loadUsername(); // <-- TAWAGIN ANG FUNCTION PARA KUNIN ANG USERNAME

    // Listen for text changes in manual input
    _manualController.addListener(() {
      setState(() {
        _charCount = _manualController.text.length;
        inputText = _manualController.text;
      });
    });
  }

  // --- BAGONG FUNCTION ---
  /// Kukunin ang pangalan ng active user mula sa storage
  Future<void> _loadUsername() async {
    final userId = await CredentialService.instance.getActiveUserId();
    if (userId == null) return;
    final username = await CredentialService.instance.getUsernameById(userId);
    if (username != null && mounted) {
      setState(() {
        _username = username;
      });
    }
  }
  // --- END NG BAGONG FUNCTION ---

  /// Navigates to the ReportScreen with the provided text for plagiarism checking
  void _checkPlagiarism(String text) {
    if (!mounted) return; // Check if the widget is still mounted
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportScreen(content: text),
      ),
    );
  }

  /// Opens file picker and extracts text from `.txt`, `.docx`, or `.pdf` files
  Future<void> _pickFile() async {
    final typeGroup = XTypeGroup(
      label: 'documents',
      extensions: ['txt', 'docx', 'pdf'],
    );
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return;

    final extension = file.name.split('.').last.toLowerCase();
    final bytes = await file.readAsBytes();
    String extractedText = '';

    try {
      if (extension == 'txt') {
        extractedText = String.fromCharCodes(bytes);
      } else if (extension == 'docx') {
        extractedText = await extractTextFromDocx(bytes);
      } else if (extension == 'pdf') {
        extractedText = await extractTextFromPdf(bytes);
      }
    } catch (e) {
      extractedText = 'Failed to extract text.';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error extracting text from file: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return; // Stop if extraction failed
    }

    _checkPlagiarism(extractedText);
  }

  /// Picks an image file and extracts text using Google ML Kit OCR
  Future<void> _pickImageAndRecognizeText() async {
    final recognizedText = await extractTextFromImage();

    // --- BAGONG ERROR HANDLING ---
    if (recognizedText == null || recognizedText.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                      "The image doesn't have recognizable text. Try another one."),
                ),
              ],
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            margin: const EdgeInsets.all(10),
          ),
        );
      }
      return; // Huwag ituloy kung walang text
    }
    // --- END NG BAGONG ERROR HANDLING ---

    // Ituloy lang kung may text
    _checkPlagiarism(recognizedText);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF43C5FC),
        centerTitle: true,
        title: Text(
          'PlagiariShield',
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0), // Home tab

      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Manual Text Input Section ---
              Text(
                'Hello, $_username!', // <-- BINAGO NA ANG TEXT DITO
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _manualController,
                maxLines: 8,
                maxLength: 10000,
                decoration: InputDecoration(
                  hintText: 'Type or paste text here...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  fillColor: Colors.white,
                  filled: true,
                  counterText: '$_charCount / 10000',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => _manualController.clear(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: inputText.trim().isNotEmpty
                    ? () => _checkPlagiarism(inputText)
                    : null,
                icon: const Icon(Icons.search),
                label: const Text('Check Plagiarism'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF43C5FC),
                  foregroundColor: Colors.white, // Tiniyak na puti ang text
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),

              const Divider(height: 40),

              // --- File Upload Section ---
              Text(
                'Or Upload File',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.file_upload),
                label: const Text('Choose .txt / .docx / .pdf'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),

              const SizedBox(height: 24),

              // --- Image OCR Section ---
              Text(
                'Or Extract from Image',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _pickImageAndRecognizeText,
                icon: const Icon(Icons.image_search),
                label: const Text('Choose Image (.jpg / .png)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

