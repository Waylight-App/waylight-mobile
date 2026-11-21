import 'package:waylight_mobile/data/repositories/actions/smarthome_repository.dart';
import 'package:waylight_mobile/data/services/device_controls/device_controls_store.dart';
import 'package:waylight_mobile/domain/models/device_control.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// Keeps Android's device controls up to date and runs their actions
/// (#194). The controls reach the server only through this repository and
/// the server's smart home endpoints, so the server's allow-list applies
/// unchanged.
class DeviceControlsRepository {
  /// Creates the repository.
  const DeviceControlsRepository({
    required this._smartHome,
    required this._store,
  });

  final SmartHomeRepository _smartHome;
  final DeviceControlsStore _store;

  /// Reads the entities of the smart home module and their states. On a
  /// failure the controls show as unavailable, never an old state.
  Future<Result<void>> refresh(
    ServerAddress server, {
    required DeviceControlFormatter format,
  }) async {
    switch (await _smartHome.entities(server)) {
      case Ok(:final value):
        await _store.save(
          DeviceControlsSnapshot(
            available: true,
            controls: [
              for (final e in value) DeviceControl.of(e, format.state(e)),
            ],
          ),
        );
        return const Result.ok(null);
      case Error(:final error):
        await unavailable(DeviceControlsProblem.unreachable, format: format);
        return Result.error(error);
    }
  }

  /// Switches or presses the entity [id], then shows the new states.
  Future<Result<void>> act(
    ServerAddress server,
    String id, {
    required DeviceControlFormatter format,
  }) async {
    final acted = await _smartHome.act(server, id);
    final refreshed = await refresh(server, format: format);
    return switch (acted) {
      Error() => acted,
      Ok() => refreshed,
    };
  }

  /// Shows the controls as unavailable because of [problem].
  Future<void> unavailable(
    DeviceControlsProblem problem, {
    required DeviceControlFormatter format,
  }) => _store.save(
    DeviceControlsSnapshot(available: false, reason: format.problem(problem)),
  );

  /// Forgets every control, e.g. after signing out.
  Future<void> clear() => _store.clear();

  /// Tells the native side that a background run has ended.
  Future<void> finish() => _store.finished();
}
