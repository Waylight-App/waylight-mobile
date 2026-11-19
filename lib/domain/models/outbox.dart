/// The offline outbox of to-dos (#24), the same rules as the web app
/// (`web/src/shared/offline/domain/outbox.ts` of the server): changes made
/// without a connection wait here and are replayed in order. Pure
/// functions; persistence and replay live in the repository.
library;

import 'package:waylight_mobile/domain/models/todo.dart';

/// What a waiting change does.
enum OutboxOp {
  /// Creates the to-do with its client-generated id.
  create,

  /// Changes title, due date or completion.
  update,

  /// Deletes the to-do.
  delete,
}

/// One waiting change of a to-do.
final class PendingChange {
  /// Creates the change.
  const PendingChange({
    required this.key,
    required this.op,
    required this.todo,
    required this.baseVersion,
    this.source = '',
  });

  /// The id of the change itself.
  final String key;

  /// What the change does.
  final OutboxOp op;

  /// The to-do as it should be on the server (for delete: which one).
  final Todo todo;

  /// The version the change was made from; 0 for no check.
  final int baseVersion;

  /// The connected list; empty for the built-in one.
  final String source;

  /// A copy with other values.
  PendingChange copyWith({OutboxOp? op, Todo? todo, int? baseVersion}) =>
      PendingChange(
        key: key,
        op: op ?? this.op,
        todo: todo ?? this.todo,
        baseVersion: baseVersion ?? this.baseVersion,
        source: source,
      );
}

/// Why the server refused a change.
enum ConflictKind {
  /// The to-do was changed elsewhere in the meantime.
  changed,

  /// The server rejected the change, e.g. invalid input.
  rejected,
}

/// A change the server refused; the user decides what happens.
final class Conflict {
  /// Creates the conflict.
  const Conflict({
    required this.change,
    required this.kind,
    this.serverVersion = 0,
    this.message = '',
  });

  /// The refused change.
  final PendingChange change;

  /// Why it was refused.
  final ConflictKind kind;

  /// The server's current version (changed).
  final int serverVersion;

  /// The server's message (rejected).
  final String message;
}

/// The waiting changes and the refused ones.
final class OutboxState {
  /// Creates the state.
  const OutboxState({this.queue = const [], this.conflicts = const []});

  /// Changes waiting to be sent, oldest first.
  final List<PendingChange> queue;

  /// Changes the server refused.
  final List<Conflict> conflicts;

  /// Whether nothing waits and nothing needs a decision.
  bool get isEmpty => queue.isEmpty && conflicts.isEmpty;
}

/// Adds [change], merged with what already waits for the same to-do:
/// create + update → one create; update + update → one update from the
/// first version; create + delete → nothing; update + delete → one delete
/// from the first version.
OutboxState enqueue(OutboxState state, PendingChange change) {
  final queue = [...state.queue];
  final i = queue.indexWhere(
    (c) => c.source == change.source && c.todo.id == change.todo.id,
  );
  if (i < 0) {
    return OutboxState(queue: [...queue, change], conflicts: state.conflicts);
  }
  final prev = queue[i];
  if (change.op == OutboxOp.update && prev.op != OutboxOp.delete) {
    queue[i] = prev.copyWith(todo: change.todo);
  } else if (change.op == OutboxOp.delete && prev.op == OutboxOp.create) {
    queue.removeAt(i);
  } else if (change.op == OutboxOp.delete) {
    queue[i] = change.copyWith(baseVersion: prev.baseVersion);
  } else {
    queue.add(change);
  }
  return OutboxState(queue: queue, conflicts: state.conflicts);
}

/// The result of sending the first waiting change.
sealed class ReplayResult {
  const ReplayResult();
}

/// The server took it, or the to-do no longer exists.
final class ReplayDone extends ReplayResult {
  /// Creates the result.
  const ReplayDone();
}

/// The to-do was changed elsewhere; the server has [serverVersion].
final class ReplayChanged extends ReplayResult {
  /// Creates the result.
  const ReplayChanged(this.serverVersion);

  /// The version on the server.
  final int serverVersion;
}

/// The server rejected the change with [message].
final class ReplayRejected extends ReplayResult {
  /// Creates the result.
  const ReplayRejected(this.message);

  /// The server's message.
  final String message;
}

/// Still offline; the change keeps waiting.
final class ReplayOffline extends ReplayResult {
  /// Creates the result.
  const ReplayOffline();
}

/// Applies the result of sending the first waiting change.
OutboxState settle(OutboxState state, ReplayResult result) {
  if (state.queue.isEmpty || result is ReplayOffline) return state;
  final [first, ...rest] = state.queue;
  return switch (result) {
    ReplayDone() ||
    ReplayOffline() => OutboxState(queue: rest, conflicts: state.conflicts),
    ReplayChanged(:final serverVersion) => OutboxState(
      queue: rest,
      conflicts: [
        ...state.conflicts,
        Conflict(
          change: first,
          kind: ConflictKind.changed,
          serverVersion: serverVersion,
        ),
      ],
    ),
    ReplayRejected(:final message) => OutboxState(
      queue: rest,
      conflicts: [
        ...state.conflicts,
        Conflict(change: first, kind: ConflictKind.rejected, message: message),
      ],
    ),
  };
}

/// "Keep mine": sends the change again on top of the server's version.
OutboxState keepMineChange(OutboxState state, String key) {
  final c = state.conflicts.where((x) => x.change.key == key).firstOrNull;
  if (c == null || c.kind != ConflictKind.changed) return state;
  return OutboxState(
    conflicts: [
      for (final x in state.conflicts)
        if (x != c) x,
    ],
    queue: [
      ...state.queue,
      c.change.copyWith(baseVersion: c.serverVersion),
    ],
  );
}

/// "Keep the server's" (or drop a rejected change).
OutboxState discard(OutboxState state, String key) => OutboxState(
  queue: state.queue,
  conflicts: [
    for (final x in state.conflicts)
      if (x.change.key != key) x,
  ],
);

/// Shows the waiting changes of [source] on top of [todos], so what was
/// changed offline does not disappear on the next load.
List<Todo> overlay(List<Todo> todos, OutboxState state, String source) {
  var out = [...todos];
  for (final c in state.queue.where((x) => x.source == source)) {
    final i = out.indexWhere((t) => t.id == c.todo.id);
    if (c.op == OutboxOp.delete) {
      if (i >= 0) out.removeAt(i);
    } else if (i >= 0) {
      out[i] = c.todo;
    } else if (c.op == OutboxOp.create) {
      out = [...out, c.todo];
    }
  }
  return out;
}
