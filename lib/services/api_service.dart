import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // -----------------------------------------------------------------
  // !! MAHALAGA !!
  // Palitan ang URL na ito ng iyong NGROK URL.
  // Ito ay dapat ang "Forwarding" URL na nagsisimula sa "https://"
  // -----------------------------------------------------------------
  String apiUrl = 'https://54aa2cdf6e65.ngrok-free.app';

  // Siguraduhin na ang endpoint ay "/check"
  String get checkUrl => '$apiUrl/check';

  /// Tinatawagan ang Python API para i-check ang text.
  /// Ito ay inaasahan na ngayong magbalik ng ISANG LISTA ng JSON objects.
  Future<List<dynamic>> checkPlagiarism(String text) async {
    try {
      final response = await http.post(
        Uri.parse(checkUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          // Header na kailangan ng ngrok kung gumagamit ng libreng account
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({'text': text}),
      );

      if (response.statusCode == 200) {
        // Ang API ay magbabalik na ngayon ng isang List<dynamic>
        // (Listahan ng mga JSON object, isa para sa bawat sentence)
        final List<dynamic> results = jsonDecode(response.body);
        return results;
      } else {
        // Nagka-error sa server (e.g., 500 Internal Server Error)
        throw Exception(
            'Failed to check plagiarism. Status code: ${response.statusCode}');
      }
    } catch (e) {
      // Nagka-error sa network (e.g., hindi ma-konekta, timeout)
      print('Network error: $e');
      throw Exception('Failed to connect to the plagiarism API. Error: $e');
    }
  }
}

