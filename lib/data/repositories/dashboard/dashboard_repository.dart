import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The dashboard of the signed-in account (#16). Read-only: tabs and
/// layouts are edited in the web interface.
abstract interface class DashboardRepository {
  /// Loads the tabs and widgets from [server].
  Future<Result<Dashboard>> dashboard(ServerAddress server);

  /// Stores the phone layout of [tabId] (#53).
  Future<Result<void>> saveLayout(
    ServerAddress server,
    String tabId,
    List<PhoneLayoutItem> layout,
  );

  /// Lets the phone layout of [tabId] follow the desktop grid again.
  Future<Result<void>> resetLayout(ServerAddress server, String tabId);
}
