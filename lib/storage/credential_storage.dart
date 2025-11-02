import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// A singleton service that manages user credentials using SharedPreferences.
/// Provides functionality to register, login, logout, and update user accounts.
class CredentialService {
  // Private constructor to enforce singleton pattern
  CredentialService._privateConstructor();

  // Single shared instance of this service
  static final CredentialService instance =
      CredentialService._privateConstructor();

  // Keys used in SharedPreferences
  static const String _accountsKey = 'accounts'; // Key for storing all accounts
  static const String _activeUserKey =
      'active_user'; // Key for currently logged-in user
  final _uuid = const Uuid(); // Utility to generate unique IDs for users

  /// Register a new account with a unique userId.
  /// Returns `true` if registration succeeds, `false` if username already exists.
  Future<bool> register(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = _readAccounts(prefs);

    // Prevent duplicate usernames
    if (accounts.values.any((v) => v['username'] == username)) return false;

    final userId = _uuid.v4(); // Generate unique ID for this user
    accounts[userId] = {
      'username': username,
      'password': password,
      'profileImagePath': null, // Bagong field
    };

    // Save updated accounts and set this user as active
    await prefs.setString(_accountsKey, jsonEncode(accounts));
    await prefs.setString(_activeUserKey, userId);
    return true;
  }

  /// Login using username and password.
  /// Returns `true` if successful, `false` otherwise.
  Future<bool> login(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = _readAccounts(prefs);

    // Find user by username
    final entry = accounts.entries.firstWhere(
      (e) => e.value['username'] == username,
      orElse: () => const MapEntry('', {}),
    );

    // Fail if user does not exist or password is incorrect
    if (entry.key.isEmpty || entry.value['password'] != password) return false;

    // Set this user as active
    await prefs.setString(_activeUserKey, entry.key);
    return true;
  }

  /// Logout the currently active user.
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeUserKey);
  }

  /// Get the ID of the currently active user.
  Future<String?> getActiveUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeUserKey);
  }

  /// Get username by a given userId.
  Future<String?> getUsernameById(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = _readAccounts(prefs);
    return accounts[userId]?['username'];
  }

  /// Get profile image path by a given userId.
  Future<String?> getProfileImagePath(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = _readAccounts(prefs);
    return accounts[userId]?['profileImagePath'];
  }

  /// Retrieve the password of a user by username (for internal use only).
  Future<String?> getPasswordForUser(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = _readAccounts(prefs);

    // Look up user entry
    final entry = accounts.entries.firstWhere(
      (e) => e.value['username'] == username,
      orElse: () => const MapEntry('', {}),
    );

    return entry.value.isEmpty ? null : entry.value['password'];
  }

  /// Update username and/or password without changing userId.
  /// Ensures uniqueness of username across accounts.
  /// Returns `true` if update succeeds, `false` if username conflict or user not found.
  Future<bool> updateCredentials({
    required String userId,
    required String newUsername,
    required String newPassword,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = _readAccounts(prefs);

    // Fail if userId does not exist
    if (!accounts.containsKey(userId)) return false;

    // Prevent username conflicts with other accounts
    if (accounts.values.any((v) =>
        v['username'] == newUsername &&
        accounts.entries.firstWhere((e) => e.value == v).key != userId)) {
      return false;
    }

    // Update credentials and keep user active
    accounts[userId] = {
      'username': newUsername,
      'password': newPassword,
      'profileImagePath':
          accounts[userId]?['profileImagePath'], // Preserve existing image path
    };
    await prefs.setString(_accountsKey, jsonEncode(accounts));
    await prefs.setString(_activeUserKey, userId);
    return true;
  }

  /// Updates only the profile image path for a user.
  Future<bool> updateProfileImagePath(String userId, String imagePath) async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = _readAccounts(prefs);

    if (!accounts.containsKey(userId)) return false;

    accounts[userId]?['profileImagePath'] = imagePath;
    await prefs.setString(_accountsKey, jsonEncode(accounts));
    return true;
  }

  /// Internal helper to safely read stored accounts from SharedPreferences.
  Map<String, dynamic> _readAccounts(SharedPreferences prefs) {
    final raw = prefs.getString(_accountsKey);
    if (raw == null || raw.isEmpty) return <String, dynamic>{};

    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{}; // Return empty if JSON is invalid
    }
  }
}

