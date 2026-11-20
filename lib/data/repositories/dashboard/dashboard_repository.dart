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

  /// The widget kinds the server offers (#210).
  Future<Result<List<String>>> widgetKinds(ServerAddress server);

  /// Adds a widget of [kind] to [tabId], below its [desktopRows] in the
  /// desktop grid; the server appends it to the phone layout (#210).
  Future<Result<WidgetPlacement>> addWidget(
    ServerAddress server,
    String tabId,
    String kind, {
    required int desktopRows,
  });

  /// Lets the phone layout of [tabId] follow the desktop grid again.
  Future<Result<void>> resetLayout(ServerAddress server, String tabId);
}
