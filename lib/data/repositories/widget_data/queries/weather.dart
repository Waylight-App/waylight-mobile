import 'package:waylight_mobile/data/repositories/widget_data/queries/json.dart';
import 'package:waylight_mobile/data/repositories/widget_data/widget_data_repository.dart';
import 'package:waylight_mobile/domain/models/weather.dart';

/// `GET /api/weather/warnings`; `lat` and `lon` come from the widget.
const warningsQuery = WidgetQuery<List<WeatherWarning>>(
  '/api/weather/warnings',
  parseWarnings,
);

/// `GET /api/weather/health`; `region`, `city` and `types` come from the
/// widget.
const healthQuery = WidgetQuery<WeatherHealth>(
  '/api/weather/health',
  parseHealth,
);

String _s(Object? v) => v is String ? v : '';

/// Maps `GET /api/weather/warnings`.
List<WeatherWarning>? parseWarnings(Object? json) =>
    listOf<WeatherWarning>(json, (w) {
      if (w case {'headline': final String headline}) {
        return WeatherWarning(
          headline: headline,
          severity: _s(w['severity']),
          description: _s(w['description']),
          expires: asDateTime(w['expires'])?.toLocal(),
        );
      }
      return null;
    });

/// Maps `GET /api/weather/health`; both parts are optional.
WeatherHealth? parseHealth(Object? json) {
  if (json is! Map<String, Object?>) return null;
  final uv = json['uv'];
  return WeatherHealth(
    pollen: [
      if (json['pollen'] case {'days': final List<Object?> days})
        for (final d in days)
          if (d case {'type': final String type, 'today': final String today})
            (type, today),
    ],
    uvToday: switch (uv) {
      {'today': final int t} when t >= 0 => t,
      _ => null,
    },
    uvLevel: switch (uv) {
      {'todayLevel': final String l} => l,
      _ => '',
    },
  );
}
