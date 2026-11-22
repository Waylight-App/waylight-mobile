import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:waylight_mobile/data/repositories/widget_data/queries/everyday.dart';
import 'package:waylight_mobile/data/repositories/widget_data/queries/home_server.dart';
import 'package:waylight_mobile/data/repositories/widget_data/widget_data_repository_remote.dart';
import 'package:waylight_mobile/data/services/api/api_client.dart';
import 'package:waylight_mobile/data/services/api/module_api.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/backup_health.dart';
import 'package:waylight_mobile/domain/models/everyday.dart';
import 'package:waylight_mobile/domain/models/home_server.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../../testing/fakes/fake_server_repository.dart';

void main() {
  // Recorded from https://demo.getwaylight.app.
  Object? fixture(String name) =>
      jsonDecode(File('test/fixtures/${name}_demo.json').readAsStringSync());

  test('reads the system status of the demo', () {
    final s = parseSystem(fixture('system'))!;
    expect(s.hostname, 'homeserver');
    expect(s.disks.map((d) => d.label), ['System', 'Data']);
    expect(s.disks.first.daysUntilFull, isNull, reason: 'no forecast yet');
    expect(s.uptime.inDays, greaterThan(0));
  });

  test('reads services and leaves out hidden tiles', () {
    final json = fixture('services')! as List<Object?>;
    final list = parseServices(json)!;
    expect(list.map((s) => s.name), [
      'DuckDuckGo',
      'OpenStreetMap',
      'Open-Meteo',
    ]);
    expect(list.first.state, ServiceState.online);

    final hidden = [
      ...json,
      {'id': 'x', 'name': 'Hidden', 'state': 'offline', 'hidden': true},
    ];
    expect(parseServices(hidden), hasLength(3));
    expect(parseServices({'not': 'a list'}), isNull);
  });

  test('reads backups, countdowns, birthdays and prices of the demo', () {
    final backups = parseBackupSources(fixture('backup_status_sources'))!;
    expect(
      backups.firstWhere((b) => b.name.startsWith('Offsite')).state,
      BackupState.failed,
    );
    expect(
      backups.firstWhere((b) => b.name.startsWith('Photos')).state,
      BackupState.overdue,
    );

    final countdowns = parseCountdowns(fixture('countdowns'))!;
    expect(countdowns.first.title, 'Car inspection');
    expect(countdowns.first.date, DateTime(2026, 11, 23));
    expect(countdowns.first.daysFrom(DateTime(2026, 11, 19, 23)), 4);

    final birthdays = parseBirthdays(fixture('birthdays'))!;
    expect(birthdays.first.name, 'Grandma Hilde');
    expect(birthdays.first.age, 80);
    expect(birthdays.firstWhere((b) => b.age == null).name, isNotEmpty);

    final prices = parseElectricity(fixture('electricity_prices'))!;
    expect(prices.zone, 'DE-LU');
    expect(prices.hours, hasLength(48));
    final first = prices.hours.first;
    expect(prices.at(first.start.add(const Duration(minutes: 30))), first);
  });

  test(
    'the remote repository passes the query and fails on bad JSON',
    () async {
      late Uri asked;
      var body = '{"zone":"AT","hours":[]}';
      final repo = WidgetDataRepositoryRemote(
        api: ModuleApi(
          ApiClient(
            client: MockClient((request) async {
              asked = request.url;
              return http.Response(body, 200);
            }),
          ),
        ),
      );

      final ok = await repo.read(
        testServer(),
        electricityQuery.withQuery({'zone': 'AT'}),
      );
      expect((ok as Ok<ElectricityPrices>).value.zone, 'AT');
      expect(asked.path, '/api/electricity/prices');
      expect(asked.queryParameters, {'zone': 'AT'});

      body = '[]';
      final bad = await repo.read(testServer(), electricityQuery);
      expect(((bad as Error).error as ApiException).failure, ApiFailure.server);
    },
  );

  test('reads the backup traffic light', () {
    final status = parseBackupStatus({
      'health': 'stale',
      'lastBackupAt': '2026-11-20T02:00:00Z',
      'error': '',
      'offsiteError': 'timeout',
    })!;
    expect(status.health, BackupHealth.stale);
    expect(status.lastBackupAt, DateTime.utc(2026, 11, 20, 2));
    expect(status.offsiteError, 'timeout');
    expect(parseBackupStatus({'count': 1}), isNull);
  });
}
