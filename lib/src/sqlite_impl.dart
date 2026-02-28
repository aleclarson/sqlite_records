import 'dart:async';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:meta/meta.dart';
import 'core.dart';
import 'utils.dart';

export 'core.dart';

/// Creates a [SqlRecords] instance from a [sqlite.Database].
SqlRecords SqlRecordsSqlite(sqlite.Database db) => SqliteWriteContext(db);

@internal
class SqliteRow<R extends Record> extends Row<R> {
  final sqlite.Row _row;
  SqliteRow(this._row, super.schema);

  @override
  Object? operator [](String key) => _row[key];
}

@internal
class SqliteMutationResult implements MutationResult {
  @override
  final int? affectedRows;
  @override
  final Object? lastInsertId;

  SqliteMutationResult({this.affectedRows, this.lastInsertId});
}

@internal
class SqliteReadContext implements SqlRecordsReadonly {
  final sqlite.Database _db;

  SqliteReadContext(this._db);

  @override
  Future<RowSet<R>> getAll<P, R extends Record>(Query<P, R> query,
      [P? params]) async {
    final (sql, args) = prepareSql(query.sql, query.params, params);
    final results = _db.select(sql, args);
    return RowSet<R>(
        results.map((row) => SqliteRow<R>(row, query.schema)));
  }

  @override
  Future<Row<R>> get<P, R extends Record>(Query<P, R> query,
      [P? params]) async {
    final (sql, args) = prepareSql(query.sql, query.params, params);
    final results = _db.select(sql, args);
    return SqliteRow<R>(results.first, query.schema);
  }

  @override
  Future<Row<R>?> getOptional<P, R extends Record>(Query<P, R> query,
      [P? params]) async {
    final (sql, args) = prepareSql(query.sql, query.params, params);
    final results = _db.select(sql, args);
    if (results.isEmpty) return null;
    return SqliteRow<R>(results.first, query.schema);
  }
}

@internal
class SqliteWriteContext extends SqliteReadContext implements SqlRecords {
  SqliteWriteContext(sqlite.Database db) : super(db);

  @override
  Future<MutationResult> execute<P>(Command<P> mutation, [P? params]) async {
    final (sql, map) = mutation.apply(params);
    if (sql == NoOpCommand) return const NoOpMutationResult();
    final (_, args) = translateSql(sql, map);
    _db.execute(sql, args);
    return SqliteMutationResult(
      affectedRows: _db.updatedRows,
      lastInsertId: _db.lastInsertRowId,
    );
  }

  @override
  Future<void> executeBatch<P>(Command<P> mutation, List<P> paramsList) async {
    for (final p in paramsList) {
      final (sql, map) = mutation.apply(p);
      if (sql == NoOpCommand) continue;
      final (_, args) = translateSql(sql, map);
      _db.execute(sql, args);
    }
  }

  @override
  Stream<RowSet<R>> watch<P, R extends Record>(Query<P, R> query,
      {P? params,
      Duration throttle = const Duration(milliseconds: 30),
      Iterable<String>? triggerOnTables}) {
    throw UnsupportedError('watch() is only supported for PowerSync.');
  }

  @override
  Future<T> readTransaction<T>(
      Future<T> Function(SqlRecordsReadonly tx) action) async {
    // Standard SQLite doesn't have a built-in 'read-only' transaction mode
    // like PowerSync, so we just use a normal transaction or just run the action.
    return action(this);
  }

  @override
  Future<T> writeTransaction<T>(
      Future<T> Function(SqlRecords tx) action) async {
    _db.execute('BEGIN TRANSACTION');
    try {
      final result = await action(this);
      _db.execute('COMMIT');
      return result;
    } catch (e) {
      _db.execute('ROLLBACK');
      rethrow;
    }
  }
}
