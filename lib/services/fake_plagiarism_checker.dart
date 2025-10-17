/// A fake plagiarism checker used for simulation purposes only.
/// It randomly flags every 3rd sentence as plagiarized.
class FakePlagiarismChecker {
  /// Simulates a plagiarism check.
  /// Returns a map containing analysis results such as
  /// total sentences, flagged sentences, and plagiarism percentage.
  static Map<String, dynamic> check(String text) {
    // Split text into sentences using punctuation as delimiters.
    // Trim whitespace and remove empty strings.
    List<String> sentences = text
        .split(RegExp(r'[.!?]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    // Holds the sentences that are flagged as plagiarized.
    List<String> flagged = [];

    // Fake detection logic: flag every 3rd sentence (index % 3 == 0).
    for (int i = 0; i < sentences.length; i++) {
      if (i % 3 == 0) flagged.add(sentences[i]);
    }

    // Return structured results.
    return {
      'totalSentences': sentences.length, // total number of sentences
      'plagiarizedCount': flagged.length, // number of flagged sentences
      'plagiarizedSentences': flagged,    // list of flagged sentences
      'sentences': sentences,             // all extracted sentences
      'plagiarismPercentage':
          ((flagged.length / sentences.length) * 100).toStringAsFixed(2), // percentage
    };
  }
}
