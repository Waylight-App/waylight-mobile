import 'package:waylight_mobile/data/repositories/transit/transit_repository.dart';
import 'package:waylight_mobile/data/repositories/waste/waste_repository.dart';
import 'package:waylight_mobile/data/repositories/weather/weather_repository.dart';
import 'package:waylight_mobile/data/services/api/compact_text_json.dart';
import 'package:waylight_mobile/data/services/api/module_api.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/compact_derived.dart';
import 'package:waylight_mobile/domain/models/compact_state.dart';
import 'package:waylight_mobile/domain/models/network.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The short state of a widget (#228), as the server computes it
/// (`GET /api/<module>/compact`), so small tiles, home screen widgets,
/// Quick Settings tiles and the watch say the same. For kinds without a
/// server endpoint the app derives it from the full data (#242).
abstract interface class CompactStateRepository {
  /// Reads which modules of [server] have a compact state
  /// (`GET /api/modules`, #274), so [supports] can answer while tiles are
  /// built. Offline it keeps the stored answer. With [reuse] a list
  /// already read for [server] is kept without a request.
  Future<void> load(ServerAddress server, {bool reuse = false});

  /// Whether a compact state exists for a widget of [kind] with [config],
  /// on the server last passed to [load].
  bool supports(String kind, {Map<String, Object?> config});

  /// The compact state of the widget kind [kind]; the offline copy when
  /// the server cannot be reached. [config] is the widget's configuration,
  /// which some states need (e.g. the stop of a transit widget or the
  /// device of a smart home tile).
  Future<Result<CompactState>> state(
    ServerAddress server,
    String kind, {
    Map<String, Object?> config,
  });

  /// Sends the request of [action] from a compact state (#226), with the
  /// body of [choice] when the action offers choices.
  Future<Result<void>> run(
    ServerAddress server,
    CompactAction action, {
    CompactChoice? choice,
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

  /// The modules with a compact state on servers older than
  /// Waylight-App/waylight#634, whose module list does not name them.
  static const fallbackModules = {'todos', 'habits', 'focus'};

  /// The module behind each widget kind whose name differs; every other
  /// kind is served by the module of the same name.
  static const moduleOfKind = {
    'backup-status': 'backupmonitor',
    'status-overview': 'services',
  };

  /// How many departures a derived transit state reads.
  static const departureCount = 3;

  ServerAddress? _server;
  Map<String, CompactEndpoint> _endpoints = _fallback;

  static final Map<String, CompactEndpoint> _fallback = {
    for (final m in fallbackModules)
      m: CompactEndpoint(module: m, path: '/api/$m/compact'),
  };

  @override
  Future<void> load(ServerAddress server, {bool reuse = false}) async {
    if (reuse && server == _server) return;
    final result = await _api.read(server, '/api/modules', parseCompactModules);
    switch (result) {
      case Ok(:final value):
        _endpoints = {
          for (final e in value.endpoints ?? _fallback.values) e.module: e,
        };
        _server = server;
      case Error():
        // Without an answer or a stored copy, another server's list says
        // nothing about this one.
        if (server != _server) {
          _endpoints = _fallback;
          _server = server;
        }
    }
  }

  @override
  bool supports(String kind, {Map<String, Object?> config = const {}}) =>
      _query(kind, config) != null ||
      switch (kind) {
        'weather' => _weather != null,
        'transit' => _transit != null,
        'waste' => _waste != null,
        _ => false,
      };

  /// The server endpoint and query for a widget of [kind] with [config];
  /// `null` when the server has none or the widget lacks a parameter.
  (CompactEndpoint, Map<String, String>)? _query(
    String kind,
    Map<String, Object?> config,
  ) {
    // A to-do widget on another source (CalDAV, Microsoft To Do) shows
    // lists the server's to-do state does not count.
    if (kind == 'todos' && (config['source'] ?? '') != '') return null;
    final endpoint = _endpoints[moduleOfKind[kind] ?? kind];
    if (endpoint == null) return null;
    final query = <String, String>{};
    for (final param in endpoint.params) {
      final value = compactParam(kind, param, config);
      if (value == null) return null;
      query[param] = value;
    }
    return (endpoint, query);
  }

  @override
  Future<Result<CompactState>> state(
    ServerAddress server,
    String kind, {
    Map<String, Object?> config = const {},
  }) async {
    await load(server, reuse: true);
    if (_query(kind, config) case (final endpoint, final query)) {
      return _api.read(server, endpoint.path, parseCompactState, query: query);
    }
    return switch (kind) {
      'weather' when _weather != null => _weatherState(server, config),
      'transit' when _transit != null => _transitState(server, config),
      'waste' when _waste != null => _wasteState(server),
      _ => const Result.error(ApiException(ApiFailure.notFound)),
    };
  }

  @override
  Future<Result<void>> run(
    ServerAddress server,
    CompactAction action, {
    CompactChoice? choice,
  }) async {
    final body = choice?.body ?? action.body;
    // The parser only lets paths under /api/ through, so the request stays
    // on the server's API.
    final Result<Object?> result = switch (action.method) {
      'POST' => await _api.post(server, action.path, body: body),
      'PUT' => await _api.put(server, action.path, body: body),
      'DELETE' => await _api.delete(server, action.path),
      _ => const Result.error(ApiException(ApiFailure.notFound)),
    };
    return switch (result) {
      Ok() => const Result.ok(null),
      Error(:final error) => Result.error(error),
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

/// The value of the compact query parameter [param] for a widget of
/// [kind] with [config]; `null` when the widget does not set it. A smart
/// home tile has a state only with exactly one device, as on the web.
/// The DNS filter and the electricity price fall back to the defaults of
/// their widgets (AdGuard Home, the zone DE-LU), as the web does, so
/// widgets saved without the setting still have a state
/// (Waylight-App/waylight#650).
String? compactParam(String kind, String param, Map<String, Object?> config) {
  switch ((kind, param)) {
    case ('smarthome', 'entity'):
      return switch (config['entities']) {
        [final String id] when id.isNotEmpty => id,
        _ => null,
      };
    case ('adguard', 'provider'):
      return dnsFilterProvider(config);
    case ('electricity', 'zone'):
      return config['zone'] == 'AT' ? 'AT' : 'DE-LU';
  }
  return switch (config[param]) {
    final String s when s.isNotEmpty => s,
    final num n => '$n',
    _ => null,
  };
}

/// Maps the `compact` list of `GET /api/modules` (Waylight-App/waylight#634):
/// `endpoints` is `null` when an older server has no list; the whole
/// answer is `null` when it has another shape. Entries without a module or
/// with a path outside the API are skipped.
({List<CompactEndpoint>? endpoints})? parseCompactModules(Object? json) =>
    switch (json) {
      {'compact': final List<Object?> list} => (
        endpoints: [
          for (final e in list)
            if (e
                case {
                      'module': final String module,
                      'path': final String path,
                    } &&
                    final Map<String, Object?> o
                when module.isNotEmpty && path.startsWith('/api/'))
              CompactEndpoint(
                module: module,
                path: path,
                params: switch (o['params']) {
                  final List<Object?> p => [
                    for (final name in p)
                      if (name is String && name.isNotEmpty) name,
                  ],
                  _ => const [],
                },
              ),
        ],
      ),
      {'modules': List<Object?>()} => (endpoints: null),
      _ => null,
    };

/// Maps `GET /api/<module>/compact`; `null` for an answer of another
/// shape.
CompactState? parseCompactState(Object? json) {
  if (json case {'title': final Object? t} && final Map<String, Object?> o) {
    final title = parseCompactText(t);
    if (title == null) return null;
    return CompactState(
      title: title,
      detail: parseCompactText(o['detail']),
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
      empty: o['empty'] == true,
    );
  }
  return null;
}

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
      label: parseCompactText(o['label']) ?? CompactText(text: id),
      method: method.toUpperCase(),
      path: path,
      body: _body(o['body']),
      choices: switch (o['choices']) {
        final List<Object?> choices => [
          for (final c in choices)
            if (c case {'id': final String cid} && final Map<String, Object?> m)
              CompactChoice(
                id: cid,
                label: parseCompactText(m['label']) ?? CompactText(text: cid),
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
