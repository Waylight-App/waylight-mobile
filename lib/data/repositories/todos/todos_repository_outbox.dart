import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'package:waylight_mobile/data/repositories/todos/todos_repository.dart';
import 'package:waylight_mobile/data/services/api/offline_status.dart';
import 'package:waylight_mobile/data/services/storage/key_value_store.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/outbox.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/domain/models/todo.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The waiting and refused to-do changes, for the widget (#24). It
/// notifies its listeners when they change.
abstract class TodoOutbox extends ChangeNotifier {
  /// The changes the server refused; the user decides about each.
  List<Conflict> get conflicts;

  /// Whether [todo] has a change that waits for the server.
  bool isPending(Todo todo);

  /// Sends the change again on top of the server's version.
  Future<void> keepMine(String key);

  /// Drops the change and keeps the server's version.
  Future<void> keepServer(String key);
}

/// A [TodosRepository] that keeps changes made offline in a persistent
/// outbox and replays them in order when the server answers again (#24).
class TodosRepositoryOutbox implements TodosRepository {
  /// Creates the repository around [_remote]; it replays when [_offline]
  /// reports that the server answers again.
  TodosRepositoryOutbox({
    required this._remote,
    required this._store,
    required this._offline,
    required this._server,
  }) {
    _offline.addListener(_onOffline);
  }

  /// The key of the stored outbox.
  static const storageKey = 'todos.outbox';

  final TodosRepository _remote;
  final KeyValueStore _store;
  final OfflineStatus _offline;
  final ServerAddress? Function() _server;
  final _random = Random.secure();

  OutboxState _state = const OutboxState();
  bool _flushing = false;

  /// The outbox for the widget; a separate object, because a repository
  /// handed out through `Provider` must not be a listenable itself.
  late final TodoOutbox outbox = _OutboxView(this);

  void _notify() => (outbox as _OutboxView).changed();

  /// Loads the stored outbox; call once at start.
  Future<void> restore() async {
    try {
      _state = _decode(await _store.read(storageKey));
    } on Exception {
      _state = const OutboxState();
    }
    _notify();
  }

  /// Deletes the outbox, e.g. when signing out.
  Future<void> clear() async {
    _state = const OutboxState();
    try {
      await _store.delete(storageKey);
    } on Exception {
      // Nothing stored.
    }
    _notify();
  }

  void _onOffline() {
    if (_offline.showingDataFrom == null) flush().ignore();
  }

  @override
  Future<Result<List<Todo>>> todos(
    ServerAddress server, {
    bool openOnly = true,
    String source = '',
  }) async {
    if (_state.queue.isNotEmpty) await flush();
    final result = await _remote.todos(
      server,
      openOnly: openOnly,
      source: source,
    );
    return switch (result) {
      Ok(:final value) => Result.ok(overlay(value, _state, source)),
      Error() => result,
    };
  }

  @override
  Future<Result<Todo>> create(
    ServerAddress server, {
    required String title,
    DateTime? due,
    String source = '',
    String id = '',
  }) async {
    final todoId = id.isEmpty ? _newId() : id;
    final result = await _remote.create(
      server,
      title: title,
      due: due,
      source: source,
      id: todoId,
    );
    if (!_isOffline(result)) return result;
    final todo = Todo(id: todoId, title: title, due: due);
    await _enqueue(
      PendingChange(
        key: _newId(),
        op: OutboxOp.create,
        todo: todo,
        baseVersion: 0,
        source: source,
      ),
    );
    return Result.ok(todo);
  }

  @override
  Future<Result<Todo>> update(
    ServerAddress server,
    Todo todo, {
    String source = '',
  }) async {
    final result = await _remote.update(server, todo, source: source);
    if (!_isOffline(result)) return result;
    await _enqueue(
      PendingChange(
        key: _newId(),
        op: OutboxOp.update,
        todo: todo,
        baseVersion: todo.version,
        source: source,
      ),
    );
    return Result.ok(todo);
  }

  @override
  Future<Result<void>> delete(
    ServerAddress server,
    String id, {
    String source = '',
  }) async {
    final result = await _remote.delete(server, id, source: source);
    if (!_isOffline(result)) return result;
    await _enqueue(
      PendingChange(
        key: _newId(),
        op: OutboxOp.delete,
        todo: Todo(id: id, title: ''),
        baseVersion: 0,
        source: source,
      ),
    );
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> clearCompleted(
    ServerAddress server, {
    String source = '',
  }) => _remote.clearCompleted(server, source: source);

  /// Sends the waiting changes in order until one cannot be delivered.
  Future<void> flush() async {
    final server = _server();
    if (_flushing || server == null) return;
    _flushing = true;
    try {
      while (_state.queue.isNotEmpty) {
        final result = await _replay(server, _state.queue.first);
        if (result is ReplayOffline) break;
        _state = settle(_state, result);
        await _save();
        _notify();
      }
    } finally {
      _flushing = false;
    }
  }

  Future<ReplayResult> _replay(ServerAddress server, PendingChange c) async {
    final Result<Object?> result = switch (c.op) {
      OutboxOp.create => await _remote.create(
        server,
        title: c.todo.title,
        due: c.todo.due,
        source: c.source,
        id: c.todo.id,
      ),
      OutboxOp.update => await _remote.update(
        server,
        c.todo.copyWith(version: c.baseVersion),
        source: c.source,
      ),
      OutboxOp.delete => await _remote.delete(
        server,
        c.todo.id,
        source: c.source,
      ),
    };
    switch (result) {
      case Ok():
        return const ReplayDone();
      case Error(error: ApiException(failure: ApiFailure.unreachable)):
        return const ReplayOffline();
      case Error(error: ApiException(failure: ApiFailure.notFound)):
        return const ReplayDone(); // deleted elsewhere: nothing to apply
      case Error(error: ApiException(failure: ApiFailure.conflict)):
        return ReplayChanged(await _serverVersion(server, c));
      case Error(:final error):
        return ReplayRejected(switch (error) {
          ApiException(:final message?) => message,
          _ => '',
        });
    }
  }

  // The version stored on the server, so "keep mine" can send on top of it.
  Future<int> _serverVersion(ServerAddress server, PendingChange c) async {
    final result = await _remote.todos(
      server,
      openOnly: false,
      source: c.source,
    );
    if (result case Ok(:final value)) {
      for (final t in value) {
        if (t.id == c.todo.id) return t.version;
      }
    }
    return 0;
  }

  /// Sends a refused change again on top of the server's version.
  Future<void> keepMine(String key) async {
    _state = keepMineChange(_state, key);
    await _save();
    _notify();
    await flush();
  }

  /// Drops a refused change and keeps the server's version.
  Future<void> keepServer(String key) async {
    _state = discard(_state, key);
    await _save();
    _notify();
  }

  static bool _isOffline(Result<Object?> result) => switch (result) {
    Error(error: ApiException(failure: ApiFailure.unreachable)) => true,
    _ => false,
  };

  Future<void> _enqueue(PendingChange change) async {
    _state = enqueue(_state, change);
    await _save();
    _notify();
  }

  String _newId() => base64Url
      .encode([for (var i = 0; i < 12; i++) _random.nextInt(256)])
      .replaceAll('=', '');

  Future<void> _save() async {
    try {
      await _store.write(storageKey, _encode(_state));
    } on Exception {
      // The outbox stays in memory for this run.
    }
  }

  /// Stops listening for the server; for tests and shutdown.
  void dispose() {
    _offline.removeListener(_onOffline);
    outbox.dispose();
  }

  static Map<String, Object?> _change(PendingChange c) => {
    'key': c.key,
    'op': c.op.name,
    'source': c.source,
    'baseVersion': c.baseVersion,
    'id': c.todo.id,
    'title': c.todo.title,
    'due': c.todo.due?.toIso8601String(),
    'done': c.todo.done,
  };

  static PendingChange? _readChange(Object? json) {
    if (json case {
      'key': final String key,
      'op': final String op,
      'id': final String id,
    }) {
      return PendingChange(
        key: key,
        op: OutboxOp.values.firstWhere(
          (o) => o.name == op,
          orElse: () => OutboxOp.update,
        ),
        source: json['source'] is String ? json['source']! as String : '',
        baseVersion: json['baseVersion'] is int
            ? json['baseVersion']! as int
            : 0,
        todo: Todo(
          id: id,
          title: json['title'] is String ? json['title']! as String : '',
          due: json['due'] is String
              ? DateTime.tryParse(json['due']! as String)
              : null,
          done: json['done'] == true,
        ),
      );
    }
    return null;
  }

  static String _encode(OutboxState s) => jsonEncode({
    'queue': [for (final c in s.queue) _change(c)],
    'conflicts': [
      for (final c in s.conflicts)
        {
          'change': _change(c.change),
          'kind': c.kind.name,
          'serverVersion': c.serverVersion,
          'message': c.message,
        },
    ],
  });

  static OutboxState _decode(String? raw) {
    if (raw == null) return const OutboxState();
    final json = jsonDecode(raw);
    if (json is! Map<String, Object?>) return const OutboxState();
    return OutboxState(
      queue: [
        if (json['queue'] case final List<Object?> q)
          for (final c in q) ?_readChange(c),
      ],
      conflicts: [
        if (json['conflicts'] case final List<Object?> list)
          for (final c in list)
            if (c case {'change': final Object? ch, 'kind': final String kind})
              if (_readChange(ch) case final change?)
                Conflict(
                  change: change,
                  kind: kind == 'rejected'
                      ? ConflictKind.rejected
                      : ConflictKind.changed,
                  serverVersion: c['serverVersion'] is int
                      ? c['serverVersion']! as int
                      : 0,
                  message: c['message'] is String
                      ? c['message']! as String
                      : '',
                ),
      ],
    );
  }
}

class _OutboxView extends TodoOutbox {
  _OutboxView(this._repository);

  final TodosRepositoryOutbox _repository;

  void changed() => notifyListeners();

  @override
  List<Conflict> get conflicts => _repository._state.conflicts;

  @override
  bool isPending(Todo todo) =>
      _repository._state.queue.any((c) => c.todo.id == todo.id);

  @override
  Future<void> keepMine(String key) => _repository.keepMine(key);

  @override
  Future<void> keepServer(String key) => _repository.keepServer(key);
}
