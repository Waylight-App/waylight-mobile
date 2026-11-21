/// A stop found by the stop search (`GET /api/transit/stops`, #230).
final class Stop {
  /// Creates the stop.
  const Stop({required this.id, required this.name});

  /// The provider's id of the stop.
  final String id;

  /// The name, e.g. "Oldenburg Hbf".
  final String name;
}

/// A place found by the place search (`GET /api/weather/places`, #230).
final class Place {
  /// Creates the place.
  const Place({
    required this.name,
    required this.lat,
    required this.lon,
    this.region = '',
    this.country = '',
  });

  /// The name, e.g. "Berlin".
  final String name;

  /// The state or region, if known.
  final String region;

  /// The country, if known.
  final String country;

  /// The latitude.
  final double lat;

  /// The longitude.
  final double lon;
}
