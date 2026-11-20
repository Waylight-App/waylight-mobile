import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/data/repositories/widget_data/queries/home_server.dart';
import 'package:waylight_mobile/data/repositories/widget_data/widget_data_repository.dart';
import 'package:waylight_mobile/data/services/device/device_info.dart';
import 'package:waylight_mobile/data/services/logging/log_store.dart';
import 'package:waylight_mobile/domain/models/diagnostics.dart';
import 'package:waylight_mobile/utils/result.dart';

/// Builds a diagnostic report for a bug report and shares it on request
/// (#197). The report leaves the device only through the share sheet.
class DiagnosticsRepository {
  /// Creates the repository.
  DiagnosticsRepository({
    required this._logs,
    required this._device,
    required this._server,
    required this._data,
  });

  final LogStore _logs;
  final DeviceInfo _device;
  final ServerRepository _server;
  final WidgetDataRepository _data;

  /// Collects the report; [appVersion] comes from the UI layer, which reads
  /// the package information.
  Future<DiagnosticReport> report({required String appVersion}) async {
    final server = _server.current;
    var serverVersion = 'not connected';
    var modules = const <String>[];
    if (server != null) {
      serverVersion = switch (await _server.version()) {
        Ok(:final value) => value,
        Error() => 'unknown',
      };
      if (await _data.read(server, modulesQuery) case Ok(:final value)) {
        modules = value.toList()..sort();
      }
    }
    return DiagnosticReport(
      appVersion: appVersion,
      device: await _device.describe(),
      serverVersion: serverVersion,
      modules: modules,
      connection: server == null ? 'none' : server.resolve('/').scheme,
      log: await _logs.entries(),
    );
  }

  /// Opens the share sheet with the report.
  Future<void> share(DiagnosticReport report) =>
      _device.shareText(report.text, subject: 'Waylight diagnostic report');

  /// Deletes the stored log records.
  Future<void> clear() => _logs.clear();
}
