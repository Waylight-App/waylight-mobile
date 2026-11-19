/// A habit with its streaks (`GET /api/habits`).
final class Habit {
  /// Creates the habit.
  const Habit({
    required this.id,
    required this.name,
    required this.doneToday,
    this.emoji = '',
    this.dueToday = true,
    this.current = 0,
    this.best = 0,
  });

  /// The server's id.
  final String id;

  /// What the habit is.
  final String name;

  /// An emoji, or empty.
  final String emoji;

  /// Whether it is ticked off today.
  final bool doneToday;

  /// Whether it is due today (habits can be limited to weekdays).
  final bool dueToday;

  /// The current and the best streak in days.
  final int current;

  /// The best streak in days.
  final int best;

  /// The same habit with today ticked off or not; the streak follows like
  /// on the server, so the change shows before the answer arrives.
  Habit toggled() => Habit(
    id: id,
    name: name,
    emoji: emoji,
    doneToday: !doneToday,
    dueToday: dueToday,
    current: doneToday ? (current - 1).clamp(0, current) : current + 1,
    best: best,
  );
}
