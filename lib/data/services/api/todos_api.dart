import 'package:waylight_mobile/data/services/api/api_client.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/domain/models/todo.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The to-do endpoints of the server (`api/modules/todos.yaml`).
class TodosApi {
  /// Creates the service on top of an [ApiClient].
  const TodosApi(this._client);

  final ApiClient _client;

  /// Reads `GET /api/todos`; [openOnly] leaves out ticked-off to-dos,
  /// [source] picks a connected external list (empty = the built-in one).
  Future<Result<List<Todo>>> todos(
    ServerAddress server, {
    bool openOnly = true,
    String source = '',
  }) async {
    final uri = server
        .resolve('/api/todos')
        .replace(
          queryParameters: {
            if (openOnly) 'done': 'false',
            if (source.isNotEmpty) 'source': source,
          },
        );
    final result = await _client.getJson(uri);
    switch (result) {
      case Ok(:final value):
        final todos = parseTodos(value);
        return todos == null
            ? const Result.error(ApiException(ApiFailure.server))
            : Result.ok(todos);
      case Error(:final error):
        return Result.error(error);
    }
  }
}

/// Maps the JSON of `GET /api/todos`; `null` if it does not match.
List<Todo>? parseTodos(Object? json) {
  if (json is! List<Object?>) return null;
  final todos = <Todo>[];
  for (final item in json) {
    if (item case {'id': final String id, 'title': final String title}) {
      todos.add(
        Todo(
          id: id,
          title: title,
          due: switch (item['due']) {
            final String due when due.isNotEmpty => DateTime.tryParse(due),
            _ => null,
          },
          done: item['done'] == true,
          overdue: item['overdue'] == true,
        ),
      );
    } else {
      return null;
    }
  }
  return todos;
}
