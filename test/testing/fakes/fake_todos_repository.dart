import 'package:waylight_mobile/data/repositories/todos/todos_repository.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/domain/models/todo.dart';
import 'package:waylight_mobile/utils/result.dart';

/// A [TodosRepository] without network for tests.
class FakeTodosRepository implements TodosRepository {
  /// What [todos] returns; an empty list by default.
  Result<List<Todo>> result = const Result.ok([]);

  /// The arguments of every [todos] call.
  final List<({bool openOnly, String source})> calls = [];

  /// When set, every change fails with this error.
  Exception? failWith;

  /// The changes that reached the "server", e.g. `update 1`.
  final List<String> writes = [];

  @override
  Future<Result<List<Todo>>> todos(
    ServerAddress server, {
    bool openOnly = true,
    String source = '',
  }) async {
    calls.add((openOnly: openOnly, source: source));
    return result;
  }

  Result<T> _write<T>(String what, T value) {
    final error = failWith;
    if (error != null) return Result.error(error);
    writes.add(what);
    return Result.ok(value);
  }

  @override
  Future<Result<Todo>> create(
    ServerAddress server, {
    required String title,
    DateTime? due,
    String source = '',
  }) async => _write(
    'create $title',
    Todo(id: 'srv-${writes.length}', title: title, due: due, version: 1),
  );

  @override
  Future<Result<Todo>> update(
    ServerAddress server,
    Todo todo, {
    String source = '',
  }) async =>
      _write('update ${todo.id}', todo.copyWith(version: todo.version + 1));

  @override
  Future<Result<void>> delete(
    ServerAddress server,
    String id, {
    String source = '',
  }) async => _write('delete $id', null);

  @override
  Future<Result<void>> clearCompleted(
    ServerAddress server, {
    String source = '',
  }) async => _write('clear', null);
}
