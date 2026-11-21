import 'package:waylight_mobile/domain/models/departure.dart';

/// Example departures for the gallery preview (#251), counted from [now]:
/// a tram on time, a late bus, a suburban train and a cancelled bus.
List<Departure> exampleDepartures(DateTime now) {
  Departure at(
    int minutes,
    String line,
    String headsign,
    TransitMode mode, {
    int delay = 0,
    String track = '',
    bool cancelled = false,
  }) {
    final planned = now.add(Duration(minutes: minutes));
    return Departure(
      line: line,
      headsign: headsign,
      mode: mode,
      planned: planned,
      expected: planned.add(Duration(minutes: delay)),
      delayMinutes: delay,
      track: track,
      cancelled: cancelled,
    );
  }

  return [
    at(3, '4', 'Central Station', TransitMode.tram),
    at(7, '270', 'University', TransitMode.bus, delay: 2),
    at(12, 'S1', 'Airport', TransitMode.suburban, track: '2'),
    at(18, '310', 'Harbour', TransitMode.bus, cancelled: true),
  ];
}
