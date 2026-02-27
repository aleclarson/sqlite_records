import 'dart:async';
import 'package:powersync/powersync.dart';
import 'package:sqlite_async/sqlite_async.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'query.dart';
import 'safe_row.dart';

part 'powersync_records.dart';

/// Context for read-only operations.
abstract interface class SqliteRecordsReadonly {
  /// Fetches all rows matching the query.
  Future<SafeResultSet<R>> getAll<P, R extends Record>(
    Query<P, R> query, [
    P? params,
  ]);

  /// Fetches exactly one row. Throws if no row is found.
  Future<SafeRow<R>> get<P, R extends Record>(
    Query<P, R> query, [
    P? params,
  ]);

  /// Fetches an optional row. Returns null if not found.
  Future<SafeRow<R>?> getOptional<P, R extends Record>(
    Query<P, R> query, [
    P? params,
  ]);
}

/// The core executor interface, supporting mutations and transactions.
abstract interface class SqliteRecords implements SqliteRecordsReadonly {
  /// Creates a [SqliteRecords] instance from a [PowerSyncDatabase].
  factory SqliteRecords.fromPowerSync(PowerSyncDatabase db) =>
      _PowerSyncWriteContext(db);

  /// Executes a single mutation.
  Future<sqlite.ResultSet> execute<P>(
    Command<P> mutation, [
    P? params,
  ]);

  /// Executes a mutation multiple times in a single batch operation.
  Future<void> executeBatch<P>(
    Command<P> mutation,
    List<P> paramsList,
  );

  /// Reactively watches a query for changes.
  /// NOTE: This is only supported on the main database connection, not in transactions.
  Stream<SafeResultSet<R>> watch<P, R extends Record>(
    Query<P, R> query, {
    P? params,
    Duration throttle = const Duration(milliseconds: 30),
    Iterable<String>? triggerOnTables,
  });

  /// Opens a read-write transaction.
  Future<T> writeTransaction<T>(Future<T> Function(SqliteRecords tx) action);

  /// Opens a read-only transaction.
  Future<T> readTransaction<T>(
      Future<T> Function(SqliteRecordsReadonly tx) action);
}
