import 'package:flutter/foundation.dart';

import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/data/repositories/todos/todos_repository.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/todo.dart';
import 'package:waylight_mobile/utils/command.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The settings of a to-do widget, as the web interface stores them.
final class TodosConfig {
  /// Creates the settings.
  const TodosConfig({this.showDone = false, this.source = ''});

  /// Reads the widget configuration; unknown values fall back to defaults.
  factory TodosConfig.fromJson(Map<String, Object?> json) => TodosConfig(
    showDone: json['showDone'] == true,
    source: switch (json['source']) {
      // "local" and anything that is not an id mean the built-in list.
      final String s when s != 'local' && _id.hasMatch(s) => s,
      _ => '',
    },
  );

  static final _id = RegExp(r'^[A-Za-z0-9_-]{1,64}$');

  /// Whether ticked-off to-dos are shown too.
  final bool showDone;

  /// The connected external list; empty for the built-in one.
  final String source;
}

/// The state of a to-do widget (#64, #20).
///
/// Changes show at once and are undone when the server refuses them; the
/// failure is then kept for a message, see [takeLastError].
class TodosViewModel extends ChangeNotifier {
  /// Creates the view model and starts loading.
  TodosViewModel({
    required this.config,
    required this._serverRepository,
    required this._todosRepository,
    this._now = DateTime.now,
  }) {
    load = Command0(_load)..execute().ignore();
    _loadRole().ignore();
  }

  /// The settings of the widget.
  final TodosConfig config;
  final ServerRepository _serverRepository;
  final TodosRepository _todosRepository;
  final DateTime Function() _now;

  List<Todo> _todos = const [];
  bool _canEdit = false;
  Exception? _lastError;

  /// Loads the to-dos; run again to reload.
  late final Command0<List<Todo>> load;

  /// The to-dos as shown, with changes not yet confirmed by the server.
  List<Todo> get todos => _todos;

  /// Whether the account may change to-dos; guests and kiosks may not.
  bool get canEdit => _canEdit;

  /// The last change the server refused, for a message; cleared when read.
  Exception? takeLastError() {
    final error = _lastError;
    _lastError = null;
    return error;
  }

  /// Today's date, to word due dates as "today" and "tomorrow".
  DateTime get today {
    final now = _now();
    return DateTime(now.year, now.month, now.day);
  }

  Future<Result<List<Todo>>> _load() async {
    final server = _serverRepository.current;
    if (server == null) return const Result.error(NotConnectedException());
    final result = await _todosRepository.todos(
      server,
      openOnly: !config.showDone,
      source: config.source,
    );
    if (result case Ok(:final value)) _setTodos(value);
    return result;
  }

  Future<void> _loadRole() async {
    if (await _serverRepository.status() case Ok(:final value)) {
      _canEdit = value.role != 'guest' && value.role != 'kiosk';
      notifyListeners();
    }
  }

  void _setTodos(List<Todo> todos) {
    _todos = List.unmodifiable(todos);
    notifyListeners();
  }

  /// Adds a to-do; the server's answer replaces the placeholder. Returns
  /// the error for the field, if the server refused the input.
  Future<Exception?> add(String title, {DateTime? due}) async {
    final server = _serverRepository.current;
    final text = title.trim();
    if (server == null || text.isEmpty) return null;
    final placeholder = Todo(
      id: '_new_${_now().microsecondsSinceEpoch}',
      title: text,
      due: due,
    );
    _setTodos([..._todos, placeholder]);
    final result = await _todosRepository.create(
      server,
      title: text,
      due: due,
      source: config.source,
    );
    return _settle(
      result,
      undo: () => _without(placeholder.id),
      apply: (todo) {
        _setTodos([for (final t in _todos) t.id == placeholder.id ? todo : t]);
      },
    );
  }

  /// Ticks [todo] off, or unticks it.
  Future<void> toggle(Todo todo) =>
      save(todo.copyWith(done: !todo.done), previous: todo);

  /// Stores a changed [todo]; [previous] is restored if that fails. Returns
  /// the error for the field, if the server refused the input.
  Future<Exception?> save(Todo todo, {required Todo previous}) async {
    final server = _serverRepository.current;
    if (server == null) return null;
    _replace(todo);
    final result = await _todosRepository.update(
      server,
      todo,
      source: config.source,
    );
    return _settle(
      result,
      undo: () => _replace(previous),
      apply: (stored) {
        // Ticked-off to-dos leave the list when only open ones are shown.
        if (stored.done && !config.showDone) {
          _without(stored.id);
        } else {
          _replace(stored);
        }
      },
    );
  }

  /// Deletes [todo].
  Future<void> delete(Todo todo) async {
    final server = _serverRepository.current;
    if (server == null) return;
    final before = _todos;
    _without(todo.id);
    final result = await _todosRepository.delete(
      server,
      todo.id,
      source: config.source,
    );
    await _settle(result, undo: () => _setTodos(before), apply: (_) {});
  }

  /// Deletes all ticked-off to-dos.
  Future<void> clearCompleted() async {
    final server = _serverRepository.current;
    if (server == null) return;
    final before = _todos;
    _setTodos([
      for (final t in _todos)
        if (!t.done) t,
    ]);
    final result = await _todosRepository.clearCompleted(
      server,
      source: config.source,
    );
    await _settle(result, undo: () => _setTodos(before), apply: (_) {});
  }

  /// Whether any shown to-do is ticked off.
  bool get hasCompleted => _todos.any((t) => t.done);

  void _replace(Todo todo) =>
      _setTodos([for (final t in _todos) t.id == todo.id ? todo : t]);

  void _without(String id) => _setTodos([
    for (final t in _todos)
      if (t.id != id) t,
  ]);

  // Applies a confirmed change or undoes it. A conflict means someone else
  // changed the list, so it is loaded again.
  Future<Exception?> _settle<T>(
    Result<T> result, {
    required void Function() undo,
    required void Function(T value) apply,
  }) async {
    switch (result) {
      case Ok(:final value):
        apply(value);
        return null;
      case Error(:final error):
        undo();
        _lastError = error;
        notifyListeners();
        if (error case ApiException(failure: ApiFailure.conflict)) {
          await load.execute();
        }
        return error;
    }
  }

  @override
  void dispose() {
    load.dispose();
    super.dispose();
  }
}
