import 'package:waylight_mobile/domain/models/compact_state.dart';
import 'package:waylight_mobile/domain/models/departure.dart';
import 'package:waylight_mobile/domain/models/waste_collection.dart';
import 'package:waylight_mobile/domain/models/weather.dart';

/// Compact states the app derives from a widget's full data (#242) for
/// widget kinds whose module has no `/compact` endpoint. Their texts carry
/// keys of the app's own catalogue ([DerivedCompactKey]) with English
/// fallbacks, so the UI can show them in the app's language.
abstract final class DerivedCompactKey {
  /// "{temp} °C, feels like {feels} °C".
  static const weather = 'app.compact.weather';

  /// "{min} to {max} °C, {rain}% rain".
  static const weatherToday = 'app.compact.weatherToday';

  /// "{line} to {headsign} in {minutes} min".
  static const departure = 'app.compact.departure';

  /// "{line} to {headsign} cancelled".
  static const departureCancelled = 'app.compact.departureCancelled';

  /// "{delay} min late".
  static const departureDelay = 'app.compact.departureDelay';

  /// "No departures".
  static const noDepartures = 'app.compact.noDepartures';

  /// "{label} today".
  static const wasteToday = 'app.compact.wasteToday';

  /// "{label} tomorrow".
  static const wasteTomorrow = 'app.compact.wasteTomorrow';

  /// "{label} in {days} days".
  static const wasteInDays = 'app.compact.wasteInDays';

  /// "No collections ahead".
  static const noCollections = 'app.compact.noCollections';
}

CompactText _text(
  String key,
  String english, [
  Map<String, String> params = const {},
]) {
  var text = english;
  for (final MapEntry(key: name, :value) in params.entries) {
    text = text.replaceAll('{$name}', value);
  }
  return CompactText(key: key, text: text, params: params);
}

/// The current temperature, and today's range and chance of rain when the
/// forecast has today. Weather never needs attention by itself.
CompactState compactWeather(Weather weather, DateTime now) {
  final today = weather.days
      .where(
        (d) =>
            d.date.year == now.year &&
            d.date.month == now.month &&
            d.date.day == now.day,
      )
      .firstOrNull;
  return CompactState(
    title: _text(
      DerivedCompactKey.weather,
      '{temp} °C, feels like {feels} °C',
      {
        'temp': '${weather.temperature.round()}',
        'feels': '${weather.apparentTemperature.round()}',
      },
    ),
    detail: today == null
        ? null
        : _text(
            DerivedCompactKey.weatherToday,
            '{min} to {max} °C, {rain}% rain',
            {
              'min': '${today.min.round()}',
              'max': '${today.max.round()}',
              'rain': '${today.precipitationProbability}',
            },
          ),
    updatedAt: now,
  );
}

/// The next departure and how many follow. A delay asks for attention, a
/// cancelled next departure is a problem.
CompactState compactDepartures(List<Departure> departures, DateTime now) {
  final next = departures.firstOrNull;
  if (next == null) {
    return CompactState(
      title: _text(DerivedCompactKey.noDepartures, 'No departures'),
      count: 0,
      updatedAt: now,
    );
  }
  final names = {'line': next.line, 'headsign': next.headsign};
  if (next.cancelled) {
    return CompactState(
      title: _text(
        DerivedCompactKey.departureCancelled,
        '{line} to {headsign} cancelled',
        names,
      ),
      level: CompactLevel.problem,
      count: departures.length,
      updatedAt: now,
    );
  }
  final minutes = next.expected.difference(now).inMinutes;
  return CompactState(
    title: _text(
      DerivedCompactKey.departure,
      '{line} to {headsign} in {minutes} min',
      {...names, 'minutes': '${minutes < 0 ? 0 : minutes}'},
    ),
    detail: next.delayMinutes > 0
        ? _text(DerivedCompactKey.departureDelay, '{delay} min late', {
            'delay': '${next.delayMinutes}',
          })
        : null,
    level: next.delayMinutes > 0 ? CompactLevel.attention : CompactLevel.ok,
    count: departures.length,
    updatedAt: now,
  );
}

/// The next collection day with every bin collected that day. Today and
/// tomorrow ask for attention, so the bins go out in time.
CompactState compactWaste(List<WasteCollection> collections, DateTime now) {
  final ahead = collections.where((c) => c.daysUntil >= 0).toList();
  if (ahead.isEmpty) {
    return CompactState(
      title: _text(DerivedCompactKey.noCollections, 'No collections ahead'),
      count: 0,
      updatedAt: now,
    );
  }
  final days = ahead.map((c) => c.daysUntil).reduce((a, b) => a < b ? a : b);
  final label = [
    for (final c in ahead)
      if (c.daysUntil == days) c.label,
  ].join(', ');
  final title = switch (days) {
    0 => _text(DerivedCompactKey.wasteToday, '{label} today', {'label': label}),
    1 => _text(DerivedCompactKey.wasteTomorrow, '{label} tomorrow', {
      'label': label,
    }),
    _ => _text(DerivedCompactKey.wasteInDays, '{label} in {days} days', {
      'label': label,
      'days': '$days',
    }),
  };
  return CompactState(
    title: title,
    level: days <= 1 ? CompactLevel.attention : CompactLevel.none,
    count: ahead.length,
    updatedAt: now,
  );
}
