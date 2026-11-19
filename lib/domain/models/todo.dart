/// A to-do of the signed-in account (`GET /api/todos`).
final class Todo {
  /// Creates the to-do.
  const Todo({
    required this.id,
    required this.title,
    this.due,
    this.done = false,
    this.overdue = false,
    this.version = 0,
  });

  /// The server's id.
  final String id;

  /// What is to be done.
  final String title;

  /// The local due date, or `null`.
  final DateTime? due;

  /// Whether it is ticked off.
  final bool done;

  /// Whether the due date has passed; decided by the server, which knows
  /// the time zone of the account.
  final bool overdue;

  /// The stored version; sent with changes so the server can refuse them
  /// when someone else changed the to-do in the meantime.
  final int version;

  /// A copy with the given values replaced; [clearDue] removes the date.
  Todo copyWith({
    String? title,
    DateTime? due,
    bool clearDue = false,
    bool? done,
    int? version,
  }) => Todo(
    id: id,
    title: title ?? this.title,
    due: clearDue ? null : due ?? this.due,
    done: done ?? this.done,
    // A changed date is no longer known to be overdue; the server says so
    // with the next load.
    overdue: (due != null || clearDue) ? false : overdue,
    version: version ?? this.version,
  );
}
