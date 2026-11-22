import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:waylight_mobile/data/repositories/widget_data/widget_data_repository.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/ui/widgets/registry.dart';

import '../../../testing/fakes/fake_widget_data_repository.dart';
import '../../../testing/tile_harness.dart';

void main() {
  setUpAll(initializeDateFormatting);

  // Recorded from https://demo.getwaylight.app.
  Object? fixture(String name) =>
      jsonDecode(File('test/fixtures/${name}_demo.json').readAsStringSync());

  late FakeWidgetDataRepository data;

  setUp(() {
    data = FakeWidgetDataRepository()
      ..json['/api/system'] = fixture('system')
      ..json['/api/services'] = fixture('services')
      ..json['/api/docker/containers'] = fixture('docker_containers')
      ..json['/api/backup-status/sources'] = fixture('backup_status_sources')
      ..json['/api/diskhealth'] = fixture('diskhealth')
      ..json['/api/speedtest/results'] = fixture('speedtest_results');
  });

  const kinds = [
    'services',
    'status-overview',
    'system',
    'docker',
    'backup-status',
    'diskhealth',
    'speedtest',
  ];

  for (final kind in kinds) {
    for (final size in tiles.keys) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('$kind fits a ${size.name} tile at ${scale}x text (#211)', (
          tester,
        ) async {
          await pumpTile(
            tester,
            size: size,
            scale: scale,
            providers: [Provider<WidgetDataRepository>.value(value: data)],
            child: Builder(
              builder: (context) => nativeWidgets.builderFor(kind)!(
                context,
                WidgetPlacement(id: kind, kind: kind),
              ),
            ),
          );

          // An overflow would have failed the test with an exception.
          expectFits(tester, size, scale);
        });
      }
    }
  }
}
