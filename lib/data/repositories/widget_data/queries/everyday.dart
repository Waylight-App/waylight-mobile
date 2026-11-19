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

/// `GET /api/holidays`.
const holidaysQuery = WidgetQuery<List<Holiday>>(
  '/api/holidays',
  parseHolidays,
);

/// Maps `GET /api/holidays`.
List<Holiday>? parseHolidays(Object? json) {
  if (json case {'entries': final Object? entries}) {
    return listOf<Holiday>(entries, (e) {
      if (e case {
        'kind': final String kind,
        'start': final String start,
        'end': final String end,
        'daysUntil': final int days,
      }) {
        final from = asDay(start);
        final to = asDay(end);
        if (from == null || to == null) return null;
        return Holiday(
          school: kind == 'school',
          key: switch (e['key']) {
            final String k => k,
            _ => '',
          },
          name: switch (e['name']) {
            final String n => n,
            _ => '',
          },
          start: from,
          end: to,
          daysUntil: days,
          current: e['current'] == true,
        );
      }
      return null;
    });
  }
  return null;
}
