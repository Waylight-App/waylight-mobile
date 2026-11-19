/// A departure at a stop (`GET /api/transit/departures`).
final class Departure {
  /// Creates the departure.
  const Departure({
    required this.line,
    required this.headsign,
    required this.mode,
    required this.planned,
    required this.expected,
    this.delayMinutes = 0,
    this.track = '',
    this.cancelled = false,
  });

  /// The line, e.g. `RE 18` or `310`.
  final String line;

  /// Where it goes.
  final String headsign;

  /// The kind of vehicle.
  final TransitMode mode;

  /// The time in the timetable.
  final DateTime planned;

  /// The time it is expected to leave, with delays.
  final DateTime expected;

  /// The delay in minutes; 0 when on time.
  final int delayMinutes;

  /// The platform or bay, or empty.
  final String track;

  /// Whether it does not run.
  final bool cancelled;
}

/// The kinds of vehicles the server tells apart.
enum TransitMode {
  /// Bus.
  bus,

  /// Tram.
  tram,

  /// Underground.
  subway,

  /// Suburban train.
  suburban,

  /// Regional train.
  regionalRail,

  /// Long-distance or high-speed train.
  highspeedRail,

  /// Ferry.
  ferry,

  /// Anything else.
  other;

  /// The mode of the server's name, e.g. `regional_rail`.
  static TransitMode fromName(String name) => switch (name) {
    'bus' => bus,
    'tram' => tram,
    'subway' => subway,
    'suburban' => suburban,
    'regional_rail' => regionalRail,
    'highspeed_rail' || 'long_distance' => highspeedRail,
    'ferry' => ferry,
    _ => other,
  };
}
