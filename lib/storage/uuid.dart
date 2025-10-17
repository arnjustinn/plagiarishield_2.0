// uuid.dart
import 'package:uuid/uuid.dart';

/// A helper class for generating UUID (Universally Unique Identifier) strings.
/// This is useful for creating unique IDs for reports, users, or any entity
/// that needs to be distinct across the application.
class UuidHelper {
  // Private constructor to prevent instantiation (singleton-style utility class).
  UuidHelper._();

  // Instance of the Uuid generator from the 'uuid' package.
  static final _uuid = Uuid();

  /// Generate a new version 4 UUID string.
  /// v4 UUIDs are randomly generated, ensuring uniqueness.
  static String generate() => _uuid.v4();
}
