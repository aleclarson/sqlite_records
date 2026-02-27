import 'safe_row.dart';

extension SafeRowConvenience on SafeRow {
  // --- STRING ENUMS ---

  /// Parses a SQLite String into a Dart Enum using its name.
  T parseEnumByName<T extends Enum>(String key, Iterable<T> values) {
    return parse<T, String>(key, (dbVal) => values.byName(dbVal));
  }

  /// Parses an optional SQLite String into a Dart Enum using its name.
  T? parseEnumByNameOptional<T extends Enum>(String key, Iterable<T> values) {
    return parseOptional<T, String>(key, (dbVal) => values.byName(dbVal));
  }

  // --- DATETIME (Example assuming Milliseconds Since Epoch) ---

  /// Parses a SQLite integer (epoch) into a Dart DateTime.
  DateTime parseDateTime(String key) {
    return parse<DateTime, int>(key, DateTime.fromMillisecondsSinceEpoch);
  }

  /// Parses an optional SQLite integer (epoch) into a Dart DateTime.
  DateTime? parseDateTimeOptional(String key) {
    return parseOptional<DateTime, int>(
        key, DateTime.fromMillisecondsSinceEpoch);
  }
}
