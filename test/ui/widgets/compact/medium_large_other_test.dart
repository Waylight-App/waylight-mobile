import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:waylight_mobile/data/repositories/absences/absences_repository.dart';
import 'package:waylight_mobile/data/repositories/widget_data/widget_data_repository.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/ui/widgets/registry.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../../testing/fakes/fake_absences_repository.dart';
import '../../../testing/fakes/fake_widget_data_repository.dart';
import '../../../testing/tile_harness.dart';

void main() {
  setUpAll(initializeDateFormatting);

  // Recorded from https://demo.getwaylight.app.
  Object? fixture(String name, [String suffix = 'demo']) =>
      jsonDecode(File('test/fixtures/${name}_$suffix.json').readAsStringSync());

  late FakeWidgetDataRepository data;
  late FakeAbsencesRepository absences;

  setUp(() {
    data = FakeWidgetDataRepository()
      ..json['/api/fritzbox/status'] = fixture('fritzbox_status')
      ..json['/api/fritzbox/calls'] = fixture('fritzbox_calls')
      ..json['/api/holidays'] = fixture('holidays')
      ..json['/api/study/progress'] = fixture('study_progress')
      ..json['/api/phonelist/entries'] = fixture('phonelist_entries')
      ..json['/api/timeline'] = fixture('timeline')
      ..json['/api/sports/overview'] = fixture('sports_overview')
      ..json['/api/wireguard/peers'] = fixture('wireguard_peers')
      ..json['/api/proxmox/status'] = fixture('proxmox_status')
      ..json['/api/adguard/stats'] = fixture('adguard_stats')
      ..json['/api/immich/overview'] = fixture('immich_overview')
      ..json['/api/nextcloud/status'] = fixture('nextcloud_status')
      ..json['/api/briefing'] = fixture('briefing')
      ..json['/api/arr/overview'] = fixture('arr_overview')
      ..json['/api/media/overview'] = fixture('media_overview')
      ..json['/api/releases'] = fixture('releases')
      ..json['/api/gamedeals/overview'] = fixture('gamedeals_overview')
      ..json['/api/mail/inbox'] = fixture('mail_inbox', 'example')
      ..json['/api/apiwidget/endpoints/e1/values'] = fixture('apiwidget_values')
      ..json['/api/grafana/alerts'] = {
        'alerts': [
          for (var i = 0; i < 8; i++)
            {
              'name': 'Alert $i',
              'summary': 'A summary that needs more than one line',
              'state': 'firing',
            },
        ],
      };
    absences = FakeAbsencesRepository()
      ..result = Result.ok(parseAbsences(fixture('absences'))!);
  });

  const kinds = {
    'fritzbox': <String, Object?>{},
    'fritzbox-calls': <String, Object?>{},
    'holidays': <String, Object?>{},
    'study': <String, Object?>{},
    'phonelist': <String, Object?>{},
    'timeline': <String, Object?>{},
    'sports': <String, Object?>{},
    'wireguard': <String, Object?>{},
    'proxmox': <String, Object?>{},
    'adguard': <String, Object?>{},
    'immich': <String, Object?>{},
    'nextcloud': <String, Object?>{},
    'briefing': <String, Object?>{},
    'arr': <String, Object?>{},
    'media': <String, Object?>{},
    'releases': <String, Object?>{},
    'gamedeals': <String, Object?>{},
    'mail': <String, Object?>{},
    'apiwidget': {'endpointId': 'e1'},
    'grafana-alerts': <String, Object?>{},
    'absences': <String, Object?>{},
  };

  for (final MapEntry(key: kind, value: config) in kinds.entries) {
    for (final size in tiles.keys) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('$kind fits a ${size.name} tile at ${scale}x text (#211)', (
          tester,
        ) async {
          await pumpTile(
            tester,
            size: size,
            scale: scale,
            providers: [
              Provider<WidgetDataRepository>.value(value: data),
              Provider<AbsencesRepository>.value(value: absences),
            ],
            child: Builder(
              builder: (context) => nativeWidgets.builderFor(kind)!(
                context,
                WidgetPlacement(id: kind, kind: kind, config: config),
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
