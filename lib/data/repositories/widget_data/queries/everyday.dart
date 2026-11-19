import 'package:waylight_mobile/data/repositories/widget_data/queries/json.dart';
import 'package:waylight_mobile/data/repositories/widget_data/widget_data_repository.dart';
import 'package:waylight_mobile/domain/models/everyday.dart';

/// `GET /api/countdowns`, soonest first.
const countdownsQuery = WidgetQuery<List<Countdown>>(
  '/api/countdowns',
  parseCountdowns,
);

/// `GET /api/birthdays`, ordered by the server by the next birthday.
const birthdaysQuery = WidgetQuery<List<Birthday>>(
  '/api/birthdays',
  parseBirthdays,
);

/// `GET /api/electricity/prices`; `zone` comes from the widget's settings.
const electricityQuery = WidgetQuery<ElectricityPrices>(
  '/api/electricity/prices',
  parseElectricity,
);

/// Maps `GET /api/countdowns`.
List<Countdown>? parseCountdowns(Object? json) {
  final list = listOf<Countdown>(json, (c) {
    if (c case {'title': final String title, 'date': final String date}) {
      final day = asDay(date);
      if (day == null) return null;
      return Countdown(
        title: title,
        date: day,
        emoji: switch (c['emoji']) {
          final String e => e,
          _ => '',
        },
        time: switch (c['time']) {
          final String t when t.isNotEmpty => t,
          _ => null,
        },
      );
    }
    return null;
  });
  return list?..sort((a, b) => a.date.compareTo(b.date));
}

/// Maps `GET /api/birthdays`.
List<Birthday>? parseBirthdays(Object? json) => listOf<Birthday>(json, (b) {
  if (b case {
    'name': final String name,
    'next': final String next,
    'inDays': final int inDays,
  }) {
    final day = asDay(next);
    if (day == null) return null;
    return Birthday(
      name: name,
      next: day,
      inDays: inDays,
      age: switch (b['age']) {
        final int a => a,
        _ => null,
      },
    );
  }
  return null;
});

/// Maps `GET /api/electricity/prices`.
ElectricityPrices? parseElectricity(Object? json) {
  if (json case {'zone': final String zone, 'hours': final Object? hours}) {
    final parsed = listOf<PriceHour>(hours, (h) {
      if (h case {'start': final String start, 'centPerKWh': final num cent}) {
        final at = DateTime.tryParse(start);
        if (at == null) return null;
        return PriceHour(
          start: at.toLocal(),
          centPerKWh: cent.toDouble(),
          cheapest: h['cheapest'] == true,
        );
      }
      return null;
    });
    if (parsed == null) return null;
    return ElectricityPrices(
      zone: zone,
      hours: parsed,
      stale: json['stale'] == true,
    );
  }
  return null;
}
