import 'package:flutter/foundation.dart';

import 'package:waylight_mobile/data/repositories/dashboard/dashboard_repository.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/data/repositories/weather/weather_repository.dart';
import 'package:waylight_mobile/domain/models/place.dart';
import 'package:waylight_mobile/domain/models/weather.dart';
import 'package:waylight_mobile/utils/command.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The settings of a weather widget, as the web interface stores them.
final class WeatherConfig {
  /// Creates the settings.
  const WeatherConfig({this.lat, this.lon, this.days = 3, this.label = ''});

  /// Reads the widget configuration; unknown values fall back to defaults.
  factory WeatherConfig.fromJson(Map<String, Object?> json) => WeatherConfig(
    lat: switch (json['lat']) {
      final num v => v.toDouble(),
      _ => null,
    },
    lon: switch (json['lon']) {
      final num v => v.toDouble(),
      _ => null,
    },
    days: switch (json['days']) {
      final int d => d.clamp(0, 5),
      _ => 3,
    },
    label: switch (json['label']) {
      final String l => l.trim(),
      _ => '',
    },
  );

  /// The latitude of the place; `null` until it is chosen in the web
  /// interface.
  final double? lat;

  /// The longitude of the place.
  final double? lon;

  /// How many forecast days are shown (0–5).
  final int days;

  /// The name of the place, e.g. "Berlin".
  final String label;
}

/// The widget has no place yet.
final class NoPlaceException implements Exception {
  /// Creates the exception.
  const NoPlaceException();
}

/// The state of a weather widget (#63).
class WeatherViewModel extends ChangeNotifier {
  /// Creates the view model and starts loading.
  WeatherViewModel({
    required this._config,
    required this._serverRepository,
    required this._weatherRepository,
    this._dashboardRepository,
    this.widgetId = '',
    this._widgetConfig = const {},
  }) {
    load = Command0(_load)..execute().ignore();
    choosePlace = Command1(_choosePlace);
  }

  WeatherConfig _config;
  Map<String, Object?> _widgetConfig;

  /// The settings of the widget.
  WeatherConfig get config => _config;

  /// The id of the widget, to store a chosen place; empty where the widget
  /// cannot be changed.
  final String widgetId;

  final DashboardRepository? _dashboardRepository;
  final ServerRepository _serverRepository;
  final WeatherRepository _weatherRepository;

  /// Loads the weather; run again to reload.
  late final Command0<Weather> load;

  /// Stores the place chosen for a widget without one (#230), then loads
  /// its weather.
  late final Command1<void, Place> choosePlace;

  /// Whether a place can be chosen in the app.
  bool get canChoosePlace =>
      _dashboardRepository != null && widgetId.isNotEmpty;

  /// The places whose name matches [query].
  Future<Result<List<Place>>> searchPlaces(String query) async {
    final server = _serverRepository.current;
    if (server == null) return const Result.error(NotConnectedException());
    return _weatherRepository.places(server, query);
  }

  Future<Result<void>> _choosePlace(Place place) async {
    final server = _serverRepository.current;
    final dashboard = _dashboardRepository;
    if (server == null || dashboard == null) {
      return const Result.error(NotConnectedException());
    }
    // The server replaces the whole configuration, so the other settings
    // go along unchanged; the label is the place's name, as on the web.
    final updated = {
      ..._widgetConfig,
      'lat': place.lat,
      'lon': place.lon,
      'label': place.name,
    };
    final result = await dashboard.updateWidget(server, widgetId, updated);
    if (result is Ok<void>) {
      _widgetConfig = updated;
      _config = WeatherConfig.fromJson(updated);
      notifyListeners();
      load.execute().ignore();
    }
    return result;
  }

  Future<Result<Weather>> _load() async {
    final (lat, lon) = (config.lat, config.lon);
    if (lat == null || lon == null) {
      return const Result.error(NoPlaceException());
    }
    final server = _serverRepository.current;
    if (server == null) return const Result.error(NotConnectedException());
    final result = await _weatherRepository.weather(server, lat: lat, lon: lon);
    return switch (result) {
      Ok(:final value) => Result.ok(
        Weather(
          temperature: value.temperature,
          apparentTemperature: value.apparentTemperature,
          condition: value.condition,
          days: value.days.take(config.days).toList(),
        ),
      ),
      Error() => result,
    };
  }

  @override
  void dispose() {
    load.dispose();
    choosePlace.dispose();
    super.dispose();
  }
}
