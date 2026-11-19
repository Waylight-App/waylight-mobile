import 'package:waylight_mobile/data/repositories/todos/todos_repository.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/domain/models/todo.dart';
import 'package:waylight_mobile/utils/result.dart';

/// A [TodosRepository] without network for tests.
class FakeTodosRepository implements TodosRepository {
  /// What [todos] returns; an empty list by default.
  Result<List<Todo>> result = const Result.ok([]);

  /// The arguments of every call.
  final List<({bool openOnly, String source})> calls = [];

  @override
  Future<Result<List<Todo>>> todos(
    ServerAddress server, {
    bool openOnly = true,
    String source = '',
  }) async {
    calls.add((openOnly: openOnly, source: source));
    return result;
  }
}
