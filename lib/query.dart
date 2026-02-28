/// Maps a Record/Class to a SQLite named parameter map.
typedef ParamMapper<P> = Map<String, Object?> Function(P params);

/// Best-effort schema definition using Dart's Type objects (e.g., int, String).
typedef ResultSchema = Map<String, Type>;

/// [P] defines the input Parameter type.
/// [R] defines the expected output Record type (serves as a token for custom linting).
class Query<P, R extends Record> {
  final String sql;
  final ResultSchema schema;
  final ParamMapper<P>? params;

  const Query(
    this.sql, {
    required this.schema,
    this.params,
  });

  /// Factory for parameterless queries.
  static Query<void, R> empty<R extends Record>(
    String sql, {
    required ResultSchema schema,
  }) {
    return Query<void, R>(sql, schema: schema);
  }
}

/// A command that mutates data (INSERT, UPDATE, DELETE).
class Command<P> {
  final String? _sql;
  final ParamMapper<P>? params;

  const Command(String sql, {this.params}) : _sql = sql;

  /// Internal constructor for subclasses that generate SQL dynamically.
  const Command._dynamic({this.params}) : _sql = null;

  /// Returns the SQL string for this command.
  /// Subclasses can override this to generate SQL based on the parameters [p].
  String getSql(P? p) => apply(p).$1;

  /// Returns the SQL string and the mapped parameters for this command.
  (String, Map<String, Object?>) apply(P? p) {
    if (_sql == null) {
      throw StateError('Command does not have a static SQL string.');
    }
    final map = params?.call(p as P) ?? const <String, Object?>{};
    return (_sql!, map);
  }

  /// Factory for parameterless mutations.
  static Command<void> empty(String sql) => Command<void>(sql);
}

/// A specialized [Command] for "patch" updates.
///
/// It dynamically generates an UPDATE statement based on the non-null values
/// provided in the [params] record. Keys specified in [primaryKeys] are used
/// in the WHERE clause and are expected to be non-null.
class UpdateCommand<P> extends Command<P> {
  final String table;
  final List<String> primaryKeys;

  const UpdateCommand({
    required this.table,
    required this.primaryKeys,
    required ParamMapper<P> params,
  }) : super._dynamic(params: params);

  @override
  (String, Map<String, Object?>) apply(P? p) {
    if (p == null || params == null) {
      throw ArgumentError('UpdateCommand requires parameters.');
    }

    final map = params!(p);
    final updates = <String>[];
    final where = <String>[];

    for (final key in map.keys) {
      if (primaryKeys.contains(key)) {
        where.add('$key = @$key');
        continue;
      }

      // Skip nulls for patching
      if (map[key] != null) {
        updates.add('$key = @$key');
      }
    }

    if (updates.isEmpty) {
      // Return a no-op SQL if no fields were provided for update.
      return ('SELECT 1 WHERE 0', map);
    }

    if (where.isEmpty) {
      throw ArgumentError('UpdateCommand requires at least one primary key.');
    }

    final sql =
        'UPDATE $table SET ${updates.join(', ')} WHERE ${where.join(' AND ')}';
    return (sql, map);
  }
}

/// A specialized [Command] for dynamic inserts.
///
/// It dynamically generates an INSERT statement using only the non-null values
/// provided in the [params] record, allowing the database to apply default values
/// for omitted columns.
class InsertCommand<P> extends Command<P> {
  final String table;

  const InsertCommand({
    required this.table,
    required ParamMapper<P> params,
  }) : super._dynamic(params: params);

  @override
  (String, Map<String, Object?>) apply(P? p) {
    if (p == null || params == null) {
      throw ArgumentError('InsertCommand requires parameters.');
    }

    final map = params!(p);
    final cols = <String>[];
    final vals = <String>[];

    for (final entry in map.entries) {
      if (entry.value != null) {
        cols.add(entry.key);
        vals.add('@${entry.key}');
      }
    }

    if (cols.isEmpty) {
      throw ArgumentError('InsertCommand requires at least one non-null value.');
    }

    final sql =
        'INSERT INTO $table (${cols.join(', ')}) VALUES (${vals.join(', ')})';
    return (sql, map);
  }
}
