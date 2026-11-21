/// Where someone works today (`GET /api/presence`, #200).
enum PresenceStatus {
  /// In the office.
  office,

  /// Working from home.
  home,

  /// Away (absent).
  away,

  /// Not set today.
  none;

  /// The value the server uses; `none` is the empty string.
  String get wire => this == none ? '' : name;

  /// Reads the server's value; anything unknown counts as not set.
  static PresenceStatus parse(Object? value) => switch (value) {
    'office' => office,
    'home' => home,
    'away' => away,
    _ => none,
  };
}

/// One person on the presence board.
final class PresencePerson {
  /// Creates the entry.
  const PresencePerson({
    required this.accountId,
    required this.name,
    required this.status,
    this.fromAbsence = false,
    this.returnOn,
  });

  /// The account's id.
  final String accountId;

  /// The display name.
  final String name;

  /// Today's status.
  final PresenceStatus status;

  /// Whether a planned absence decided the status, not the person.
  final bool fromAbsence;

  /// The day of return when away, if known.
  final DateTime? returnOn;
}

/// Today's presence of a group or everyone.
final class PresenceBoard {
  /// Creates the board.
  const PresenceBoard({required this.people, required this.counts, this.mine});

  /// Everyone, sorted by the server by status and name.
  final List<PresencePerson> people;

  /// How many people have each status.
  final Map<PresenceStatus, int> counts;

  /// The signed-in account's own entry; `null` for guests and kiosk
  /// displays, who can only read.
  final PresencePerson? mine;
}
