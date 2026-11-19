/// The next collections of one kind of waste (`GET /api/waste/upcoming`).
final class WasteCollection {
  /// Creates the collection.
  const WasteCollection({
    required this.label,
    required this.dates,
    required this.daysUntil,
    this.icon = '',
  });

  /// The kind of waste, e.g. "Paper".
  final String label;

  /// The next dates, the first one is the next collection.
  final List<DateTime> dates;

  /// Days until the next collection; 0 is today. Counted by the server in
  /// the time zone of the instance.
  final int daysUntil;

  /// An emoji for the kind of waste, or empty.
  final String icon;
}
