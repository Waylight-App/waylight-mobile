/// What kind of absence it is (`GET /api/absences`, #201).
enum AbsenceKind {
  /// On holiday.
  holiday,

  /// Sick.
  sick,

  /// Working remotely.
  remote,

  /// Away for another reason.
  other,

  /// Someone else's private absence: only "away" is shown.
  away;

  /// Reads the server's value; unknown kinds count as [other].
  static AbsenceKind parse(Object? value) => switch (value) {
    'holiday' => holiday,
    'sick' => sick,
    'remote' => remote,
    'away' => away,
    _ => other,
  };

  /// The kinds a person can enter.
  static const enterable = [holiday, sick, remote, other];
}

/// An absence of someone on the instance.
final class Absence {
  /// Creates the absence.
  const Absence({
    required this.id,
    required this.name,
    required this.from,
    required this.to,
    required this.kind,
    this.accountId = '',
    this.note = '',
    this.private = false,
    this.editable = false,
  });

  /// The server's id.
  final String id;

  /// Whose absence it is.
  final String accountId;

  /// The person's display name.
  final String name;

  /// The first day.
  final DateTime from;

  /// The last day, included.
  final DateTime to;

  /// What kind it is.
  final AbsenceKind kind;

  /// An optional note; empty for someone else's private absence.
  final String note;

  /// Whether others see only "away".
  final bool private;

  /// Whether the viewer may change or delete it, as the server says.
  final bool editable;

  /// Whether it covers [day] (dates only).
  bool covers(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return !d.isBefore(from) && !d.isAfter(to);
  }
}

/// What the form sends to create or change an absence.
final class AbsenceInput {
  /// Creates the input.
  const AbsenceInput({
    required this.from,
    required this.to,
    required this.kind,
    this.note = '',
    this.private = false,
  });

  /// The most characters of a note.
  static const maxNote = 200;

  /// The first day.
  final DateTime from;

  /// The last day, included.
  final DateTime to;

  /// The kind.
  final AbsenceKind kind;

  /// The note.
  final String note;

  /// Whether others see only "away".
  final bool private;
}
