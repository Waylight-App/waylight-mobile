import 'package:waylight_mobile/data/services/api/api_client.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The dashboard endpoint of the server (`api/modules/dashboard.yaml`).
class DashboardApi {
  /// Creates the service on top of an [ApiClient].
  const DashboardApi(this._client);

  final ApiClient _client;

  /// Reads `GET /api/dashboard` of [server] for the signed-in account.
  Future<Result<Dashboard>> dashboard(ServerAddress server) async {
    final result = await _client.getJson(server.resolve('/api/dashboard'));
    switch (result) {
      case Ok(:final value):
        final dashboard = parseDashboard(value);
        return dashboard == null
            ? const Result.error(ApiException(ApiFailure.server))
            : Result.ok(dashboard);
      case Error(:final error):
        return Result.error(error);
    }
  }
}

/// Maps the JSON of `GET /api/dashboard` to a [Dashboard]; `null` if it
/// does not match the schema. Unknown fields are ignored, so newer servers
/// keep working.
Dashboard? parseDashboard(Object? json) {
  if (json case {'tabs': final List<Object?> tabs}) {
    final parsed = <(int, DashboardTab)>[];
    for (final tab in tabs) {
      final t = _parseTab(tab);
      if (t == null) return null;
      parsed.add(t);
    }
    parsed.sort((a, b) => a.$1.compareTo(b.$1));
    return Dashboard(
      tabs: [for (final (_, tab) in parsed) tab],
      defaultTabId: switch (json['defaultTabId']) {
        final String id => id,
        _ => '',
      },
    );
  }
  return null;
}

(int, DashboardTab)? _parseTab(Object? json) {
  if (json case {
    'id': final String id,
    'name': final String name,
    'widgets': final List<Object?> widgets,
  }) {
    final byId = <String, WidgetPlacement>{};
    final grid = <GridPosition>[];
    for (final w in widgets) {
      if (w case {
        'id': final String id,
        'kind': final String kind,
        'x': final int x,
        'y': final int y,
      }) {
        final config = switch (w['config']) {
          final Map<String, Object?> c => c,
          _ => const <String, Object?>{},
        };
        byId[id] = WidgetPlacement(
          id: id,
          kind: kind,
          title: switch (config['title']) {
            final String t => t.trim(),
            _ => '',
          },
          config: config,
        );
        grid.add((id: id, x: x, y: y));
      } else {
        return null;
      }
    }
    final phone = <PhoneItem>[
      if (json['mobile'] case final List<Object?> items)
        for (final item in items)
          if (item case {'id': final String id})
            (id: id, hidden: item['hidden'] == true),
    ];
    final position = switch (json['position']) {
      final int p => p,
      _ => 0,
    };
    return (
      position,
      DashboardTab(
        id: id,
        name: name,
        widgets: [for (final id in phoneOrder(grid, phone)) byId[id]!],
      ),
    );
  }
  return null;
}
