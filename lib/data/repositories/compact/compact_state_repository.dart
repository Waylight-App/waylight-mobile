import 'package:waylight_mobile/data/repositories/transit/transit_repository.dart';
import 'package:waylight_mobile/data/repositories/waste/waste_repository.dart';
import 'package:waylight_mobile/data/repositories/weather/weather_repository.dart';
import 'package:waylight_mobile/data/services/api/module_api.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/compact_derived.dart';
import 'package:waylight_mobile/domain/models/compact_state.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The short state of a widget (#228), as the server computes it
/// (`GET /api/<module>/compact`), so small tiles, home screen widgets,
/// Quick Settings tiles and the watch say the same. For kinds without a
/// server endpoint the app derives it from the full data (#242).
abstract interface class CompactStateRepository {
  /// Whether a compact state exists for widgets of [kind].
  bool supports(String kind);

  /// The compact state of the widget kind [kind]; the offline copy when
  /// the server cannot be reached. [config] is the widget's configuration,
  /// which derived states need (e.g. the stop of a transit widget).
  Future<Result<CompactState>> state(
    ServerAddress server,
    String kind, {
    Map<String, Object?> config,
  });
}

/// A [CompactStateRepository] on the modules' `/compact` endpoints, and
/// on the full data of weather, transit and waste for their derived
/// states.
class CompactStateRepositoryRemote implements CompactStateRepository {
  /// Creates the repository; a missing repository leaves its kind without
  /// a derived state.
  CompactStateRepositoryRemote({
    required this._api,
    this._weather,
    this._transit,
    this._waste,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final ModuleApi _api;
  final WeatherRepository? _weather;
  final TransitRepository? _transit;
  final WasteRepository? _waste;
  final DateTime Function() _clock;

  /// The widget kinds whose module answers `GET /api/<kind>/compact`
  /// (Waylight-App/waylight#604). Kind and module share their name.
  static const kinds = {'todos', 'habits', 'focus'};

  /// How many departures a derived transit state reads.
  static const departureCount = 3;

  @override
  bool supports(String kind) =>
      kinds.contains(kind) ||
      switch (kind) {
        'weather' => _weather != null,
        'transit' => _transit != null,
        'waste' => _waste != null,
        _ => false,
      };

  @override
  Future<Result<CompactState>> state(
    ServerAddress server,
    String kind, {
    Map<String, Object?> config = const {},
  }) async {
    // The kind becomes part of the path, so only known names go there.
    assert(supports(kind), 'No compact state for $kind.');
    if (kinds.contains(kind)) {
      return _api.read(server, '/api/$kind/compact', parseCompactState);
    }
    return switch (kind) {
      'weather' => _weatherState(server, config),
      'transit' => _transitState(server, config),
      'waste' => _wasteState(server),
      _ => const Result.error(ApiException(ApiFailure.notFound)),
    };
  }

  Future<Result<CompactState>> _weatherState(
    ServerAddress server,
    Map<String, Object?> config,
  ) async {
    final (lat, lon) = (config['lat'], config['lon']);
    if (lat is! num || lon is! num) {
      return const Result.error(CompactConfigMissing());
    }
    return switch (await _weather!.weather(
      server,
      lat: lat.toDouble(),
      lon: lon.toDouble(),
    )) {
      Ok(:final value) => Result.ok(compactWeather(value, _clock())),
      Error(:final error) => Result.error(error),
    };
  }

  Future<Result<CompactState>> _transitState(
    ServerAddress server,
    Map<String, Object?> config,
  ) async {
    final stop = config['stopId'];
    if (stop is! String || stop.isEmpty) {
      return const Result.error(CompactConfigMissing());
    }
    return switch (await _transit!.departures(
      server,
      stop: stop,
      count: departureCount,
    )) {
      Ok(:final value) => Result.ok(compactDepartures(value, _clock())),
      Error(:final error) => Result.error(error),
    };
  }

  Future<Result<CompactState>> _wasteState(ServerAddress server) async =>
      switch (await _waste!.upcoming(server)) {
        Ok(:final value) => Result.ok(compactWaste(value, _clock())),
        Error(:final error) => Result.error(error),
      };
}

/// A derived compact state needs a setting the widget does not have yet,
/// such as the place of a weather widget.
final class CompactConfigMissing implements Exception {
  /// Creates the error.
  const CompactConfigMissing();
}

/// Maps `GET /api/<module>/compact`; `null` for an answer of another
/// shape.
CompactState? parseCompactState(Object? json) {
  if (json case {'title': final Object? t} && final Map<String, Object?> o) {
    final title = _text(t);
    if (title == null) return null;
    return CompactState(
      title: title,
      detail: _text(o['detail']),
      level: CompactLevel.parse(o['level']),
      count: switch (o['count']) {
        final int n => n,
        _ => null,
      },
      updatedAt: switch (o['updatedAt']) {
        final String s => DateTime.tryParse(s),
        _ => null,
      },
      action: _action(o['action']),
    );
  }
  return null;
}

CompactText? _text(Object? json) => switch (json) {
  {'text': final String text} && final Map<String, Object?> o => CompactText(
    text: text,
    key: switch (o['key']) {
      final String k => k,
      _ => '',
    },
    params: switch (o['params']) {
      final Map<String, Object?> p => {
        for (final MapEntry(:key, :value) in p.entries)
          if (value is String) key: value,
      },
      _ => const {},
    },
  ),
  _ => null,
};

Map<String, Object?>? _body(Object? json) => switch (json) {
  final Map<String, Object?> body => body,
  _ => null,
};

CompactAction? _action(Object? json) {
  if (json
      case {
            'id': final String id,
            'method': final String method,
            'path': final String path,
          } &&
          final Map<String, Object?> o
      when path.startsWith('/api/')) {
    return CompactAction(
      id: id,
      label: _text(o['label']) ?? CompactText(text: id),
      method: method.toUpperCase(),
      path: path,
      body: _body(o['body']),
      choices: switch (o['choices']) {
        final List<Object?> choices => [
          for (final c in choices)
            if (c case {'id': final String cid} && final Map<String, Object?> m)
              CompactChoice(
                id: cid,
                label: _text(m['label']) ?? CompactText(text: cid),
                body: _body(m['body']),
                selected: m['selected'] == true,
              ),
        ],
        _ => const [],
      },
    );
  }
  return null;
}
