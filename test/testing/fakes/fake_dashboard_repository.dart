import 'package:waylight_mobile/data/repositories/dashboard/dashboard_repository.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// A [DashboardRepository] without network for tests.
class FakeDashboardRepository implements DashboardRepository {
  /// What [dashboard] returns; no tabs by default.
  Result<Dashboard> result = const Result.ok(Dashboard(tabs: []));

  /// How often [dashboard] was called.
  int calls = 0;

  @override
  Future<Result<Dashboard>> dashboard(ServerAddress server) async {
    calls++;
    return result;
  }

  /// The layouts stored with [saveLayout], by tab.
  final Map<String, List<PhoneLayoutItem>> saved = {};

  /// The tabs reset with [resetLayout].
  final List<String> reset = [];

  @override
  Future<Result<void>> saveLayout(
    ServerAddress server,
    String tabId,
    List<PhoneLayoutItem> layout,
  ) async {
    saved[tabId] = layout;
    return const Result.ok(null);
  }

  /// What [widgetKinds] returns.
  Result<List<String>> kinds = const Result.ok(['clock', 'todos', 'weather']);

  /// The widgets added with [addWidget], as `(tab, kind, row)`.
  final List<(String, String, int)> added = [];

  /// When set, [addWidget] fails with it.
  Exception? addError;

  @override
  Future<Result<List<String>>> widgetKinds(ServerAddress server) async => kinds;

  @override
  Future<Result<WidgetPlacement>> addWidget(
    ServerAddress server,
    String tabId,
    String kind, {
    required int desktopRows,
  }) async {
    if (addError case final error?) return Result.error(error);
    added.add((tabId, kind, desktopRows));
    return Result.ok(WidgetPlacement(id: 'new-$kind', kind: kind));
  }

  /// The configurations stored by [updateWidget], by widget id.
  final Map<String, Map<String, Object?>> updated = {};

  @override
  Future<Result<void>> updateWidget(
    ServerAddress server,
    String id,
    Map<String, Object?> config,
  ) async {
    updated[id] = config;
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> resetLayout(ServerAddress server, String tabId) async {
    reset.add(tabId);
    return const Result.ok(null);
  }
}
