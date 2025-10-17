// Model class that represents one plagiarism check history entry
class HistoryEntry {
  final String reportId; // NEW: unique id for this report
  final String userId; // ID of the user who owns this history entry
  final String source; // Original input (e.g., file name or typed text)
  final String summary; // Short summary of the content checked
  final String timestamp; // When this entry was created (ISO string recommended)
  final double plagiarismPercentage; // Percentage of plagiarized content
  final List<int> plagiarizedIndexes; // Stores indexes of plagiarized sentences/words
  final int totalSentences; // Total number of sentences in the text

  // Constructor
  HistoryEntry({
    required this.reportId,
    required this.userId,
    required this.source,
    required this.summary,
    required this.timestamp,
    required this.plagiarismPercentage,
    required this.plagiarizedIndexes,
    required this.totalSentences,
  });

  // Converts HistoryEntry object → JSON (Map form)
  Map<String, dynamic> toJson() => {
        'reportId': reportId,
        'userId': userId,
        'source': source,
        'summary': summary,
        'timestamp': timestamp,
        'plagiarismPercentage': plagiarismPercentage,
        'plagiarizedIndexes': plagiarizedIndexes,
        'totalSentences': totalSentences,
      };

  // Creates a HistoryEntry object from JSON (Map form)
  // If the stored JSON has no reportId (old entries), we create a fallback id
  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    final userId = json['userId'] ?? '';
    final timestamp = json['timestamp'] ?? DateTime.now().toIso8601String();
    final fallbackId = '${userId}_$timestamp';

    return HistoryEntry(
      reportId: json['reportId'] ?? fallbackId,
      userId: userId,
      source: json['source'] ?? '',
      summary: json['summary'] ?? '',
      timestamp: timestamp,
      plagiarismPercentage:
          (json['plagiarismPercentage'] ?? 0).toDouble(),
      plagiarizedIndexes:
          json['plagiarizedIndexes'] == null ? <int>[] : List<int>.from(json['plagiarizedIndexes']),
      totalSentences: json['totalSentences'] ?? 1,
    );
  }

  // Creates a copy of this HistoryEntry with updated fields
  HistoryEntry copyWith({
    String? reportId,
    String? userId,
    String? source,
    String? summary,
    String? timestamp,
    double? plagiarismPercentage,
    List<int>? plagiarizedIndexes,
    int? totalSentences,
  }) {
    return HistoryEntry(
      reportId: reportId ?? this.reportId,
      userId: userId ?? this.userId,
      source: source ?? this.source,
      summary: summary ?? this.summary,
      timestamp: timestamp ?? this.timestamp,
      plagiarismPercentage: plagiarismPercentage ?? this.plagiarismPercentage,
      plagiarizedIndexes: plagiarizedIndexes ?? this.plagiarizedIndexes,
      totalSentences: totalSentences ?? this.totalSentences,
    );
  }
}
