import 'package:waylight_mobile/data/repositories/todos/todos_repository.dart';
import 'package:waylight_mobile/data/services/api/todos_api.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/domain/models/todo.dart';
import 'package:waylight_mobile/utils/result.dart';

/// A [TodosRepository] that asks the server every time; keeping data for
/// offline use follows in #23.
class TodosRepositoryRemote implements TodosRepository {
  /// Creates the repository.
  const TodosRepositoryRemote({required this._api});

  final TodosApi _api;

  @override
  Future<Result<List<Todo>>> todos(
    ServerAddress server, {
    bool openOnly = true,
    String source = '',
  }) => _api.todos(server, openOnly: openOnly, source: source);

  @override
  Future<Result<Todo>> create(
    ServerAddress server, {
    required String title,
    DateTime? due,
    String source = '',
  }) => _api.create(server, title: title, due: due, source: source);

  @override
  Future<Result<Todo>> update(
    ServerAddress server,
    Todo todo, {
    String source = '',
  }) => _api.update(server, todo, source: source);

  @override
  Future<Result<void>> delete(
    ServerAddress server,
    String id, {
    String source = '',
  }) => _api.delete(server, id, source: source);

  @override
  Future<Result<void>> clearCompleted(
    ServerAddress server, {
    String source = '',
  }) => _api.clearCompleted(server, source: source);
}
