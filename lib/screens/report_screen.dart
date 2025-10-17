import 'dart:math';
import 'package:flutter/material.dart';
import 'package:plagiarishield_sim/storage/history_storage.dart';
import 'package:plagiarishield_sim/storage/credential_storage.dart';
import 'package:plagiarishield_sim/storage/uuid.dart';
import '../models/history_entry.dart';

/// Screen that generates and displays a plagiarism report
class ReportScreen extends StatefulWidget {
  final String content; // The submitted text content to analyze
  final bool isFromHistory; // Flag if report is opened from history
  final Map<String, dynamic>? historyDataJson; // Previous saved report data

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
  late List<InlineSpan> spans = const [];
  late List<int> indexes = [];
  late int totalSentences = 0;
  late int plagiarizedSentences = 0;
  late double plagiarismPercentage = 0.0;
  late String aiExplanation = '';
  bool _loading = true;

  late List<Widget> _cachedSources = []; // ✅ persistent fake sources per report

  /// Cleans and splits the input text into sentences
  List<String> _cleanAndSplitText(String text) {
    final cleaned =
        text.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleaned.split(RegExp(r'(?<=[.!?])\s+'));
  }

  @override
  void initState() {
    super.initState();
    _prepareReport(); // Start preparing report
  }

  /// Prepares plagiarism report (fresh or from history)
  Future<void> _prepareReport() async {
    final userId = await CredentialService.instance.getActiveUserId();
    if (userId == null) return;

    final sentences = _cleanAndSplitText(widget.content);
    final total = sentences.length;

    List<InlineSpan> localSpans;
    List<int> localIndexes;
    int plagCount;
    double percent;
    String explanation;
    List<Widget> localSources;

    // 🟩 Case 1: Fresh plagiarism detection
    if (!widget.isFromHistory) {
      final random = Random();
      plagCount = max(1, (total * (0.1 + random.nextDouble() * 0.3)).toInt());
      percent = total == 0 ? 0.0 : (plagCount / total) * 100;

      final result = _highlightPlagiarizedSentences(widget.content, plagCount);
      localSpans = result['spans']!;
      localIndexes = result['indexes']!;
      explanation = _generateAIExplanation();
      localSources = _generateFakeSources(); // ✅ generate once

      final newReportId = UuidHelper.generate(); // ✅ consistent UUID
      final entry = HistoryEntry(
        reportId: newReportId,
        userId: userId,
        source: widget.content,
        summary: 'Plagiarism: ${percent.toStringAsFixed(1)}%',
        timestamp: DateTime.now().toIso8601String(),
        plagiarismPercentage: percent,
        plagiarizedIndexes: localIndexes,
        totalSentences: total,
      );

      await HistoryStorage.instance.saveReport(
        userId: userId,
        reportId: newReportId,
        reportData: entry.toJson(),
      );
    }

    // 🟨 Case 2: Load from saved history
    else {
      final entry = widget.historyDataJson != null
          ? HistoryEntry.fromJson(widget.historyDataJson!)
          : null;

      final storedIndexes = entry?.plagiarizedIndexes ?? [];
      final storedPercentage = entry?.plagiarismPercentage ?? 0.0;

      final result = _highlightPlagiarizedSentences(
        widget.content,
        storedIndexes.length,
        overrideIndexes: storedIndexes.isNotEmpty ? storedIndexes : null,
      );

      localSpans = result['spans']!;
      localIndexes = result['indexes']!;
      plagCount = localIndexes.length;
      percent = storedPercentage > 0.0
          ? storedPercentage
          : (total == 0 ? 0.0 : (plagCount / total) * 100);
      explanation = 'Plagiarism result loaded from history.';
      localSources = _generateFakeSources(); // same fake sources logic
    }

    if (!mounted) return;
    setState(() {
      totalSentences = total;
      spans = localSpans;
      indexes = localIndexes;
      plagiarizedSentences = plagCount;
      plagiarismPercentage = percent;
      aiExplanation = explanation;
      _cachedSources = localSources;
      _loading = false;
    });
  }

  /// Highlights plagiarized sentences in red and bold
  Map<String, dynamic> _highlightPlagiarizedSentences(
    String text,
    int count, {
    List<int>? overrideIndexes,
  }) {
    final cleaned =
        text.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    final sentences = cleaned.split(RegExp(r'(?<=[.!?])\s+'));
    final total = sentences.length;

    final plagiarizedIndexes = overrideIndexes?.toSet() ?? <int>{};
    final rand = Random();

    // Randomly mark sentences as plagiarized if needed
    while (plagiarizedIndexes.length < count &&
        plagiarizedIndexes.length < total) {
      plagiarizedIndexes.add(rand.nextInt(total));
    }

    // Build styled spans
    final spans = List<InlineSpan>.generate(sentences.length, (i) {
      var sentence = sentences[i].trim();
      if (!sentence.endsWith('.') &&
          !sentence.endsWith('!') &&
          !sentence.endsWith('?')) {
        sentence += '.';
      }

      final isPlagiarized = plagiarizedIndexes.contains(i);
      return TextSpan(
        text: '$sentence ',
        style: TextStyle(
          color: isPlagiarized ? Colors.red : Colors.black,
          fontWeight: isPlagiarized ? FontWeight.bold : FontWeight.normal,
        ),
      );
    });

    return {
      'spans': spans,
      'indexes': plagiarizedIndexes.toList(),
    };
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
              "Plagiarized", plagiarized.toString(), Icons.warning_amber),
          _buildSummaryItem(
              "Plagiarism", "${percentage.toStringAsFixed(1)}%", Icons.percent),
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

  /// Fake plagiarism sources (2–4)
  List<Widget> _generateFakeSources() {
    final rand = Random();
    final sources = [
      {
        'title': 'Academic Research Paper on AI Ethics',
        'url': 'https://journals.example.edu/ai-ethics',
      },
      {
        'title': 'Wikipedia: Artificial Intelligence',
        'url': 'https://en.wikipedia.org/wiki/Artificial_intelligence',
      },
      {
        'title': 'Medium Blog on Machine Learning Basics',
        'url': 'https://medium.com/@author/ml-basics',
      },
      {
        'title': 'News Article: Rise of Chatbots',
        'url': 'https://news.example.com/chatbots-trend',
      },
      {
        'title': 'Github README on Neural Networks',
        'url': 'https://github.com/user/neural-networks',
      },
    ];

    final count = rand.nextInt(3) + 2;
    sources.shuffle();

    return List.generate(count, (i) {
      final source = sources[i];
      final match = (rand.nextDouble() * 30 + 10).toStringAsFixed(1);
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          title: Text(
            source['title']!,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(source['url']!,
              style: const TextStyle(color: Colors.blueAccent)),
          trailing: Text(
            '$match%',
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      );
    });
  }

  /// Random AI explanation
  String _generateAIExplanation() {
    final explanations = [
      "AI detected high similarity due to repeated phrases found in common public datasets.",
      "The system flagged semantic patterns aligned with previously published academic content.",
      "Machine learning analysis found syntactic and lexical overlaps with known sources.",
      "Similarity detected in both structure and phrasing, indicating partial reuse of content.",
      "AI identified recurring sentence construction similar to training corpus data."
    ];
    explanations.shuffle();
    return explanations.first;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F9FC),
        body: Center(child: CircularProgressIndicator()),
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
  actions: [
    IconButton(
      icon: const Icon(Icons.share_outlined, color: Colors.white),
      tooltip: 'Share Report',
      onPressed: () {
        // You can implement sharing or export feature here later
      },
    ),
  ],
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
              Text(
                aiExplanation,
                style: const TextStyle(
                    fontSize: 14, color: Colors.black87, height: 1.4),
              ),

              const SizedBox(height: 20),

              const Text(
                'Detected Text with Highlights:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 16, height: 1.5),
                  children: spans,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Possible Sources:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Column(children: _cachedSources),
            ],
          ),
        ),
      ),
    );
  }
}
