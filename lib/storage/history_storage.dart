// lib/storage/history_storage.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/history_entry.dart';

class HistoryStorage {
  HistoryStorage._();
  static final HistoryStorage instance = HistoryStorage._();

  String _userKey(String userId) => 'user_history_$userId';

  /// Returns a Map where keys are reportIds and values are JSON maps for reports.
  /// If stored data was a List (older format), convert list -> map using reportId
  Future<Map<String, dynamic>> getUserHistory(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey(userId));
    if (raw == null || raw.isEmpty) return <String, dynamic>{};

    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    // If it was saved as a List, convert it to a map keyed by reportId (or fallback)
    if (decoded is List) {
      final Map<String, dynamic> out = {};
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          final id = item['reportId'] ??
              '${item['userId'] ?? userId}_${item['timestamp'] ?? ''}';
          out[id] = item;
        }
      }
      return out;
    }

    return <String, dynamic>{};
  }

  /// Save a single report (stores as a Map keyed by reportId)
  Future<void> saveReport({
    required String userId,
    required String reportId,
    required Map<String, dynamic> reportData,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _userKey(userId);

    Map<String, dynamic> map = {};
    final raw = prefs.getString(key);
    if (raw != null && raw.isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        map = decoded;
      } else if (decoded is List) {
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            final id = item['reportId'] ??
                '${item['userId'] ?? userId}_${item['timestamp'] ?? ''}';
            map[id] = item;
          }
        }
      }
    }

    map[reportId] = reportData;
    await prefs.setString(key, jsonEncode(map));
  }

  /// Delete multiple reports by id
  Future<void> deleteReports({
    required String userId,
    required List<String> reportIds,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _userKey(userId);
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return;

    final decoded = jsonDecode(raw);
    Map<String, dynamic> map = {};
    if (decoded is Map<String, dynamic>) {
      map = decoded;
    } else if (decoded is List) {
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          final id = item['reportId'] ??
              '${item['userId'] ?? userId}_${item['timestamp'] ?? ''}';
          map[id] = item;
        }
      }
    }

    for (final id in reportIds) {
      map.remove(id);
    }

    await prefs.setString(key, jsonEncode(map));
  }

  /// Remove all history for the user
  Future<void> clearUserHistory(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey(userId));
  }

  /// Overwrite the stored history for the user with the provided list.
  /// Note: updatedList must be non-null and contain non-null HistoryEntry items.
  Future<void> updateHistory(String userId, List<HistoryEntry> updatedList) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _userKey(userId);

    // Build map keyed by reportId
    final Map<String, dynamic> map = {
      for (final e in updatedList) e.reportId: e.toJson()
    };

    await prefs.setString(key, jsonEncode(map));
  }
}
