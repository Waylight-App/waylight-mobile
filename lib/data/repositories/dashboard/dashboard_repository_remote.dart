import 'package:waylight_mobile/data/repositories/dashboard/dashboard_repository.dart';
import 'package:waylight_mobile/data/services/api/dashboard_api.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// A [DashboardRepository] that asks the server every time. Keeping the
/// last dashboard for offline use follows in #23.
class DashboardRepositoryRemote implements DashboardRepository {
  /// Creates the repository.
  const DashboardRepositoryRemote({required this._api});

  final DashboardApi _api;

  @override
  Future<Result<Dashboard>> dashboard(ServerAddress server) =>
      _api.dashboard(server);

  @override
  Future<Result<void>> saveLayout(
    ServerAddress server,
    String tabId,
    List<PhoneLayoutItem> layout,
  ) => _api.saveLayout(server, tabId, layout);

  @override
  Future<Result<void>> resetLayout(ServerAddress server, String tabId) =>
      _api.resetLayout(server, tabId);
}
