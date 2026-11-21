import 'package:waylight_mobile/data/services/device_controls/device_controls_store.dart';
import 'package:waylight_mobile/domain/models/device_control.dart';

/// A [DeviceControlsStore] in memory.
class FakeDeviceControlsStore implements DeviceControlsStore {
  /// The snapshots saved, oldest first.
  final List<DeviceControlsSnapshot> saved = [];

  /// How often [clear] ran.
  int clears = 0;

  /// How often [finished] ran.
  int finishes = 0;

  @override
  Future<void> save(DeviceControlsSnapshot snapshot) async =>
      saved.add(snapshot);

  @override
  Future<void> clear() async => clears++;

  @override
  Future<void> finished() async => finishes++;
}
