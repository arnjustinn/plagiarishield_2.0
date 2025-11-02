// Model class that represents one plagiarism check history entry
class HistoryEntry {
  final String reportId; // NEW: unique id for this report
  final String userId; // ID of the user who owns this history entry
  final String source; // Original input (e.g., file name or typed text)
  final String summary; // Short summary of the content checked
  final String timestamp; // When this entry was created (ISO string recommended)

  // -----------------------------------------------------------------
  // BINAGO: Imbes na isang resulta lang, ise-save na natin ang buong
  // listahan ng JSON response mula sa API.
  // -----------------------------------------------------------------
  final List<dynamic> apiResponse; // Stores the full JSON list from the API

  // Constructor
  HistoryEntry({
    required this.reportId,
    required this.userId,
    required this.source,
    required this.summary,
    required this.timestamp,
    required this.apiResponse, // Updated
  });

  // Converts HistoryEntry object → JSON (Map form)
  Map<String, dynamic> toJson() => {
        'reportId': reportId,
        'userId': userId,
        'source': source,
        'summary': summary,
        'timestamp': timestamp,
        'apiResponse': apiResponse, // Updated
      };

  // Creates a HistoryEntry object from JSON (Map form)
  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    final userId = json['userId'] ?? '';
    final timestamp = json['timestamp'] ?? DateTime.now().toIso8601String();
    final fallbackId = '${userId}_$timestamp';

    // -----------------------------------------------------------------
    // Tinitiyak na ang 'apiResponse' ay palaging isang List.
    // Kung luma ang data (single map lang), ibabalot natin ito sa list.
    // -----------------------------------------------------------------
    dynamic rawResponse = json['apiResponse'];
    List<dynamic> parsedResponse;

    if (rawResponse is List) {
      parsedResponse = rawResponse;
    } else if (rawResponse is Map) {
      // Ito ay para sa lumang data format. I-convert natin ito.
      parsedResponse = [rawResponse];
    } else {
      // Fallback para kung sakaling corrupt o wala ang data
      parsedResponse = [
        {
          "label": "Error",
          "confidence": 0.0,
          "closest_text": "Could not load history data.",
          "text": json['source'] ?? "No text found."
        }
      ];
    }

    return HistoryEntry(
      reportId: json['reportId'] ?? fallbackId,
      userId: userId,
      source: json['source'] ?? '',
      summary: json['summary'] ?? 'History Entry',
      timestamp: timestamp,
      apiResponse: parsedResponse, // Updated
    );
  }
}

