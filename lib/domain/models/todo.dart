/// A to-do of the signed-in account (`GET /api/todos`).
final class Todo {
  /// Creates the to-do.
  const Todo({
    required this.id,
    required this.title,
    this.due,
    this.done = false,
    this.overdue = false,
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
}
