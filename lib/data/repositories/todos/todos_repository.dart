import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/domain/models/todo.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The todos module of the server.
abstract interface class TodosRepository {
  /// The todos of the signed-in account on [server].
  Future<Result<List<Todo>>> todos(
    ServerAddress server, {
    bool openOnly = true,
    String source = '',
  });

  /// Creates a to-do.
  Future<Result<Todo>> create(
    ServerAddress server, {
    required String title,
    DateTime? due,
    String source = '',
  });

  /// Stores the changes of [todo].
  Future<Result<Todo>> update(
    ServerAddress server,
    Todo todo, {
    String source = '',
  });

  /// Deletes a to-do.
  Future<Result<void>> delete(
    ServerAddress server,
    String id, {
    String source = '',
  });

  /// Deletes all ticked-off to-dos.
  Future<Result<void>> clearCompleted(
    ServerAddress server, {
    String source = '',
  });
}
