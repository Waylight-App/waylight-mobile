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

  @override
  Future<Result<void>> resetLayout(ServerAddress server, String tabId) async {
    reset.add(tabId);
    return const Result.ok(null);
  }
}
