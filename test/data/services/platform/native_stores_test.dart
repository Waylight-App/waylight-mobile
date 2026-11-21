import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waylight_mobile/data/services/device_controls/device_controls_store.dart';
import 'package:waylight_mobile/data/services/quick_tiles/quick_tile_store.dart';
import 'package:waylight_mobile/domain/models/device_control.dart';

/// The method names must match the Kotlin channels, which answer anything
/// else with "not implemented".
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  List<MethodCall> record(String channel) {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(MethodChannel(channel), (call) async {
          calls.add(call);
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(MethodChannel(channel), null),
    );
    return calls;
  }

  test('the tiles report the end as TilesChannel expects (#253)', () async {
    final calls = record('app.waylight/tiles');
    await MethodChannelQuickTileStore(supported: true).finished();
    expect(calls.single.method, 'finished');
  });

  test('the device controls save, clear and finish (#194)', () async {
    final calls = record('app.waylight/controls');
    final store = MethodChannelDeviceControlsStore(supported: true);
    await store.save(const DeviceControlsSnapshot(available: false));
    await store.clear();
    await store.finished();

    expect(calls.map((c) => c.method), ['save', 'clear', 'finished']);
    final state = (calls.first.arguments as Map<Object?, Object?>)['state'];
    expect(jsonDecode(state! as String), {
      'available': false,
      'reason': '',
      'controls': <Object?>[],
    });
  });
}
