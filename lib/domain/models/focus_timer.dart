/// A phase of the focus timer (#191).
enum FocusPhase {
  /// 25 minutes of focus; recorded on the server when finished.
  focus,

  /// A 5-minute break; not recorded.
  rest,
}

/// The running or paused phase of the focus timer.
final class FocusTimerState {
  /// Creates the state; exactly one of [endsAt] and [remaining] is set.
  const FocusTimerState({
    required this.phase,
    required this.length,
    this.endsAt,
    this.remaining,
  });

  /// Focus or break.
  final FocusPhase phase;

  /// How long the phase lasts in total.
  final Duration length;

  /// When it ends while running.
  final DateTime? endsAt;

  /// What is left while paused.
  final Duration? remaining;

  /// Whether the phase is paused.
  bool get paused => remaining != null;

  /// What is left at [now], never negative.
  Duration left(DateTime now) {
    final left = remaining ?? endsAt!.difference(now);
    return left.isNegative ? Duration.zero : left;
  }

  @override
  bool operator ==(Object other) =>
      other is FocusTimerState &&
      other.phase == phase &&
      other.length == length &&
      other.endsAt == endsAt &&
      other.remaining == remaining;

  @override
  int get hashCode => Object.hash(phase, length, endsAt, remaining);
}

/// A finished focus phase, to be recorded on the server.
final class FinishedFocus {
  /// Creates the record.
  const FinishedFocus({required this.minutes, required this.endedAt});

  /// Its length in minutes.
  final int minutes;

  /// When it ended.
  final DateTime endedAt;
}
