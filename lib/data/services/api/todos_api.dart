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

  /// Creates a to-do (`POST /api/todos`).
  Future<Result<Todo>> create(
    ServerAddress server, {
    required String title,
    DateTime? due,
    String source = '',
  }) async => _one(
    await _client.postJson(
      _uri(server, '/api/todos', source),
      body: {'title': title, 'due': _date(due)},
    ),
  );

  /// Stores title, due date and completion of [todo] (`PUT
  /// /api/todos/{id}`), refused with `ApiFailure.conflict` when the stored
  /// version is newer.
  Future<Result<Todo>> update(
    ServerAddress server,
    Todo todo, {
    String source = '',
  }) async => _one(
    await _client.putJson(
      _uri(server, '/api/todos/${Uri.encodeComponent(todo.id)}', source),
      body: {
        'title': todo.title,
        'due': _date(todo.due),
        'done': todo.done,
        if (todo.version > 0) 'version': todo.version,
      },
    ),
  );

  /// Deletes a to-do.
  Future<Result<void>> delete(
    ServerAddress server,
    String id, {
    String source = '',
  }) => _client.delete(
    _uri(server, '/api/todos/${Uri.encodeComponent(id)}', source),
  );

  /// Deletes all ticked-off to-dos.
  Future<Result<void>> clearCompleted(
    ServerAddress server, {
    String source = '',
  }) async => switch (await _client.postJson(
    _uri(server, '/api/todos/clear-completed', source),
  )) {
    Ok() => const Result.ok(null),
    Error(:final error) => Result.error(error),
  };

  static Uri _uri(ServerAddress server, String path, String source) => server
      .resolve(path)
      .replace(queryParameters: source.isEmpty ? null : {'source': source});

  static String _date(DateTime? d) => d == null
      ? ''
      : '${d.year.toString().padLeft(4, '0')}-'
            '${d.month.toString().padLeft(2, '0')}-'
            '${d.day.toString().padLeft(2, '0')}';

  static Result<Todo> _one(Result<Object?> result) => switch (result) {
    Ok(:final value) => switch (parseTodos([value])) {
      [final todo] => Result.ok(todo),
      _ => const Result.error(ApiException(ApiFailure.server)),
    },
    Error(:final error) => Result.error(error),
  };
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
          version: switch (item['version']) {
            final int v => v,
            _ => 0,
          },
        ),
      );
    } else {
      return null;
    }
  }
  return todos;
}
