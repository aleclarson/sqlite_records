import 'package:sqlite_records/query.dart';
import 'package:test/test.dart';

void main() {
  group('UpdateCommand', () {
    final patchUser = UpdateCommand<({String id, String? name, int? age})>(
      table: 'users',
      primaryKeys: ['id'],
      params: (p) => {
        'id': p.id,
        'name': p.name,
        'age': p.age,
      },
    );

    test('generates SQL for full update', () {
      final sql = patchUser.getSql((id: '1', name: 'Alec', age: 30));
      expect(sql, equals('UPDATE users SET name = @name, age = @age WHERE id = @id'));
    });

    test('generates SQL for partial update (patching)', () {
      final sql = patchUser.getSql((id: '1', name: 'Alec', age: null));
      expect(sql, equals('UPDATE users SET name = @name WHERE id = @id'));
    });

    test('generates no-op SQL when no fields are updated', () {
      final sql = patchUser.getSql((id: '1', name: null, age: null));
      expect(sql, equals('SELECT 1 WHERE 0'));
    });

    test('throws if primary key is missing', () {
      final invalidPatch = UpdateCommand<({String? name})>(
        table: 'users',
        primaryKeys: [],
        params: (p) => {'name': p.name},
      );
      expect(() => invalidPatch.getSql((name: 'Alec')), throwsArgumentError);
    });
  });

  group('InsertCommand', () {
    final insertUser = InsertCommand<({String id, String? name, int? age})>(
      table: 'users',
      params: (p) => {
        'id': p.id,
        'name': p.name,
        'age': p.age,
      },
    );

    test('generates SQL for full insert', () {
      final sql = insertUser.getSql((id: '1', name: 'Alec', age: 30));
      expect(sql, equals('INSERT INTO users (id, name, age) VALUES (@id, @name, @age)'));
    });

    test('generates SQL for partial insert', () {
      final sql = insertUser.getSql((id: '1', name: 'Alec', age: null));
      expect(sql, equals('INSERT INTO users (id, name) VALUES (@id, @name)'));
    });

    test('throws if no values are provided', () {
      final sqlThrows = InsertCommand<({String? id})>(
        table: 'users',
        params: (p) => {'id': p.id},
      );
      expect(() => sqlThrows.getSql((id: null)), throwsArgumentError);
    });
  });

  group('Command (Legacy/Static)', () {
    test('works with static SQL', () {
      final cmd = Command<({String id})>(
        'DELETE FROM users WHERE id = @id',
        params: (p) => {'id': p.id},
      );
      expect(cmd.getSql((id: '1')), equals('DELETE FROM users WHERE id = @id'));
    });

    test('works with Command.empty', () {
      final cmd = Command.empty('SELECT 1');
      expect(cmd.getSql(null), equals('SELECT 1'));
    });
  });
}
