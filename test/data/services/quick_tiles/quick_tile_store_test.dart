import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:waylight_mobile/data/services/quick_tiles/quick_tile_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('app.waylight/tiles');
  final calls = <String>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('finished invokes the method the native side handles', () async {
    await MethodChannelQuickTileStore(supported: true).finished();

    // Must match the `finished` case in TilesChannel.kt.
    expect(calls, ['finished']);
  });

  test('does nothing on platforms without tiles', () async {
    await MethodChannelQuickTileStore(supported: false).finished();

    expect(calls, isEmpty);
  });
}
