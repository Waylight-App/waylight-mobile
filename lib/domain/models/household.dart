/// The records of the family and household modules (chores, meals, gifts,
/// board, contracts, documents, meters). Each model holds what the widgets
/// show; the server's records have more fields.
library;

/// A recurring chore (`GET /api/chores`).
final class Chore {
  /// Creates the chore.
  const Chore({
    required this.id,
    required this.title,
    this.assignee = '',
    this.due,
    this.dueNow = false,
    this.overdue = false,
  });

  /// The server's id.
  final String id;

  /// What to do.
  final String title;

  /// Whose turn it is; empty when nobody is assigned.
  final String assignee;

  /// The day it is due next.
  final DateTime? due;

  /// Whether it is due today or overdue.
  final bool dueNow;

  /// Whether it is overdue.
  final bool overdue;
}

/// A planned dish (`GET /api/meals`).
final class Meal {
  /// Creates the dish.
  const Meal({required this.id, required this.dish, this.date, this.meal = ''});

  /// The server's id.
  final String id;

  /// What is cooked.
  final String dish;

  /// The day.
  final DateTime? date;

  /// `breakfast`, `lunch`, `dinner` or empty.
  final String meal;
}

/// A gift idea (`GET /api/gifts`); always private to its writer.
final class GiftIdea {
  /// Creates the idea.
  const GiftIdea({
    required this.id,
    required this.person,
    required this.title,
    this.link = '',
    this.note = '',
    this.bought = false,
  });

  /// The server's id.
  final String id;

  /// Who the gift is for.
  final String person;

  /// What to give.
  final String title;

  /// A web link to the gift.
  final String link;

  /// A note.
  final String note;

  /// Whether it is bought.
  final bool bought;

  /// The same idea with [bought] changed.
  GiftIdea withBought({required bool bought}) => GiftIdea(
    id: id,
    person: person,
    title: title,
    link: link,
    note: note,
    bought: bought,
  );
}

/// A note on the family board (`GET /api/board`).
final class BoardNote {
  /// Creates the note.
  const BoardNote({
    required this.id,
    required this.text,
    this.pinned = false,
    this.expiresOn,
  });

  /// The server's id.
  final String id;

  /// The text.
  final String text;

  /// Whether it stays on top.
  final bool pinned;

  /// The last day it is shown.
  final DateTime? expiresOn;
}

/// A contract with a cancellation deadline (`GET /api/contracts`).
final class Contract {
  /// Creates the contract.
  const Contract({
    required this.id,
    required this.name,
    this.provider = '',
    this.monthlyCents = 0,
    this.deadline,
    this.open = true,
    this.soon = false,
  });

  /// The server's id.
  final String id;

  /// The name.
  final String name;

  /// The provider.
  final String provider;

  /// The cost per month in the smallest currency unit.
  final int monthlyCents;

  /// The next cancellation deadline.
  final DateTime? deadline;

  /// `false` when the contract ended and its last deadline passed.
  final bool open;

  /// Whether the deadline is inside the reminder period.
  final bool soon;
}

/// How far a document's warranty is.
enum WarrantyStatus {
  /// No warranty entered.
  none,

  /// Running.
  running,

  /// Ends within 30 days.
  ending,

  /// Ended.
  ended;

  /// Reads the server's value; unknown values count as [none].
  static WarrantyStatus parse(Object? value) => switch (value) {
    'running' => running,
    'ending' => ending,
    'ended' => ended,
    _ => none,
  };
}

/// A document with a warranty (`GET /api/documents`).
final class DocumentRecord {
  /// Creates the document.
  const DocumentRecord({
    required this.id,
    required this.title,
    this.status = WarrantyStatus.none,
    this.warrantyEnd,
    this.hasFile = false,
  });

  /// The server's id.
  final String id;

  /// The title.
  final String title;

  /// The state of the warranty.
  final WarrantyStatus status;

  /// The last day of the warranty.
  final DateTime? warrantyEnd;

  /// Whether a file is attached.
  final bool hasFile;
}

/// A meter and its newest reading (`GET /api/meters`).
final class Meter {
  /// Creates the meter.
  const Meter({
    required this.id,
    required this.name,
    this.kind = 'other',
    this.unit = '',
    this.lastDay,
    this.lastValue,
  });

  /// The server's id.
  final String id;

  /// The name, e.g. "Electricity".
  final String name;

  /// `electricity`, `gas`, `water`, `heat` or `other`.
  final String kind;

  /// What the counter counts, e.g. kWh.
  final String unit;

  /// The day of the newest reading.
  final DateTime? lastDay;

  /// The newest reading; `null` while there is none.
  final double? lastValue;
}
