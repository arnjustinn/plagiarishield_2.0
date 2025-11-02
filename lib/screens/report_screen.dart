import 'package:flutter/material.dart';
import 'package:plagiarishield_sim/storage/history_storage.dart';
import 'package:plagiarishield_sim/storage/credential_storage.dart';
import 'package:plagiarishield_sim/storage/uuid.dart';
import '../models/history_entry.dart';
import '../services/api_service.dart'; // Import ang totoong API service
import 'dart:convert'; // Para sa jsonEncode

/// Screen that generates and displays a plagiarism report
class ReportScreen extends StatefulWidget {
  final String content; // The submitted text content to analyze
  final bool isFromHistory; // Flag if report is opened from history

  // -----------------------------------------------------------------
  // BINAGO: Ito ay isa na ngayong List<dynamic> (ang buong API response)
  // -----------------------------------------------------------------
  final List<dynamic>? historyDataJson; // Previous saved report data (List)

  const ReportScreen({
    Key? key,
    required this.content,
    this.isFromHistory = false,
    this.historyDataJson,
  }) : super(key: key);

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  // Report-related variables
  List<InlineSpan> spans = []; // Hindi na 'late'
  int totalSentences = 0;
  int plagiarizedSentences = 0;
  double plagiarismPercentage = 0.0;
  String aiExplanation = '';
  bool _loading = true;
  String _errorMessage = ''; // Para sa error handling

  // -----------------------------------------------------------------
  // ITO ANG AYOS: Gumawa ng instance ng ApiService
  // -----------------------------------------------------------------
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _prepareReport(); // Start preparing report
  }

  /// Prepares plagiarism report (fresh or from history)
  Future<void> _prepareReport() async {
    try {
      List<dynamic> apiResponse;

      // 🟩 Case 1: Fresh plagiarism detection (Tawagin ang API)
      if (!widget.isFromHistory) {
        // -----------------------------------------------------------------
        // ITO ANG AYOS: Gamitin ang instance variable na `_apiService`
        // -----------------------------------------------------------------
        apiResponse = await _apiService.checkPlagiarism(widget.content);
        if (apiResponse.isEmpty && mounted) {
          setState(() {
            _loading = false;
            _errorMessage =
                "Could not process text. The API returned an empty result.";
          });
          return;
        }
        await _saveToHistory(apiResponse);
      }
      // 🟨 Case 2: Load from saved history
      else {
        if (widget.historyDataJson == null || widget.historyDataJson!.isEmpty) {
          throw Exception("History data is empty or null.");
        }
        apiResponse = widget.historyDataJson!;
      }

      // -----------------------------------------------------------------
      // BAGONG LOGIC: I-proseso ang listahan ng results
      // -----------------------------------------------------------------
      _processApiResponse(apiResponse);
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  /// Helper function para i-save ang bagong report sa history
  Future<void> _saveToHistory(List<dynamic> apiResponse) async {
    final userId = await CredentialService.instance.getActiveUserId();
    if (userId == null) return;

    // Kalkulahin ang summary mula sa API response
    int total = apiResponse.length;
    int plagCount =
        apiResponse.where((res) => res['label'] != 'Original').length;
    double percent = (total == 0) ? 0.0 : (plagCount / total) * 100;

    final newReportId = UuidHelper.generate();
    final entry = HistoryEntry(
      reportId: newReportId,
      userId: userId,
      source: widget.content, // Ang buong text na sinubmit
      summary:
          'Plagiarism: ${percent.toStringAsFixed(1)}% ($plagCount/$total sentences)',
      timestamp: DateTime.now().toIso8601String(),
      apiResponse: apiResponse, // I-save ang buong list response
    );

    await HistoryStorage.instance.saveReport(
      userId: userId,
      reportId: newReportId,
      reportData: entry.toJson(),
    );
  }

  /// Helper function para i-proseso ang API response (bago man o galing history)
  void _processApiResponse(List<dynamic> apiResponse) {
    if (apiResponse.isEmpty) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = "Received empty results, cannot generate report.";
        });
      }
      return;
    }

    // Kalkulahin ang stats
    totalSentences = apiResponse.length;
    plagiarizedSentences =
        apiResponse.where((res) => res['label'] != 'Original').length;
    plagiarismPercentage = (totalSentences == 0)
        ? 0.0
        : (plagiarizedSentences / totalSentences) * 100;

    // Bumuo ng AI Explanation at Text Highlights
    aiExplanation = _generateAIExplanation(apiResponse);
    spans = _highlightText(apiResponse);

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  // -----------------------------------------------------------------
  // BINAGO: Ang function na ito ay gumagamit na ngayon ng list response
  // -----------------------------------------------------------------
  List<InlineSpan> _highlightText(List<dynamic> apiResponse) {
    List<InlineSpan> builtSpans = [];

    for (var result in apiResponse) {
      final text = result['text'] as String? ?? '';
      final label = result['label'] as String? ?? 'Original';
      final isPlagiarized = (label == 'Suspicious' || label == 'Plagiarized');

      builtSpans.add(
        TextSpan(
          text: '$text ', // Idagdag ang sentence at isang space
          style: TextStyle(
            color: isPlagiarized ? Colors.red : Colors.black,
            fontWeight: isPlagiarized ? FontWeight.bold : FontWeight.normal,
            backgroundColor:
                isPlagiarized ? Colors.red.withOpacity(0.15) : null,
          ),
        ),
      );
    }
    return builtSpans;
  }

  /// Builds the summary card showing stats
  Widget _buildSummaryCard(int total, int plagiarized, double percentage) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildSummaryItem("Total Sentences", total.toString(), Icons.article),
          _buildSummaryItem(
              "Flagged", plagiarized.toString(), Icons.warning_amber),
          _buildSummaryItem(
              "Plagiarized", "${percentage.toStringAsFixed(1)}%", Icons.percent),
        ],
      ),
    );
  }

  /// Helper for summary stats
  Widget _buildSummaryItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 30, color: const Color(0xFF43C5FC)),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          title,
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
      ],
    );
  }

  // -----------------------------------------------------------------
  // BINAGO: Ang function na ito ay gumagamit na rin ng list response
  // -----------------------------------------------------------------
  String _generateAIExplanation(List<dynamic> apiResponse) {
    if (widget.isFromHistory) {
      return 'Loaded from history: ${plagiarizedSentences > 0 ? "Suspicious" : "Original"} (${plagiarismPercentage.toStringAsFixed(1)}%)';
    }

    if (plagiarizedSentences == 0) {
      return 'Great! The AI found no significant similarities to known sources. This document appears to be original.';
    }

    // Hanapin ang unang plagiarized sentence
    var firstFlagged = apiResponse.firstWhere(
      (res) => res['label'] != 'Original',
      orElse: () => null,
    );

    if (firstFlagged == null) {
      return 'AI analysis complete. Please review the highlighted text.';
    }
    
    // Tiyakin na ang 'confidence' ay double
    double confidence = 0.0;
    if (firstFlagged['confidence'] is num) {
      confidence = (firstFlagged['confidence'] as num).toDouble();
    }

    String closestText = firstFlagged['closest_text'] ?? 'a known source';
    if (closestText.length > 70) {
      closestText = '${closestText.substring(0, 70)}...';
    }

    return 'The AI detected a ${plagiarismPercentage.toStringAsFixed(1)}% similarity. At least $plagiarizedSentences sentence(s) matched known sources, starting with a text similar to: "$closestText" (Confidence: ${confidence.toStringAsFixed(1)}%)';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
            title: const Text('Generating Report...'),
            backgroundColor: const Color(0xFF43C5FC),
            iconTheme: const IconThemeData(color: Colors.white),
            titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        backgroundColor: const Color(0xFFF5F9FC),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Analyzing text, please wait...',
                  style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
            title: const Text('Error'),
            backgroundColor: const Color(0xFF43C5FC),
            iconTheme: const IconThemeData(color: Colors.white),
            titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        backgroundColor: const Color(0xFFF5F9FC),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 20),
                const Text('Failed to Generate Report',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text(_errorMessage, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Go Back'),
                )
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF43C5FC),
        centerTitle: true,
        elevation: 3,
        shadowColor: Colors.black.withOpacity(0.2),
        title: Text(
          'Plagiarism Report',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: const Color(0xFFF5F9FC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryCard(
                  totalSentences, plagiarizedSentences, plagiarismPercentage),
              const Text(
                'AI Explanation:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade100)),
                child: Text(
                  aiExplanation,
                  style: const TextStyle(
                      fontSize: 14, color: Colors.black87, height: 1.4),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Detected Text with Highlights:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200)),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                        fontSize: 16, height: 1.5, color: Colors.black),
                    children: spans,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Dito mo pwedeng ilagay ang listahan ng "Possible Sources"
              // kung ibabalik ng API mo
            ],
          ),
        ),
      ),
    );
  }
}

