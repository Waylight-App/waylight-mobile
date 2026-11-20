import 'package:flutter_test/flutter_test.dart';

import 'package:waylight_mobile/data/repositories/diagnostics/diagnostics_repository.dart';
import 'package:waylight_mobile/domain/models/diagnostics.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../../testing/fakes/fake_device_info.dart';
import '../../../testing/fakes/fake_log_store.dart';
import '../../../testing/fakes/fake_server_repository.dart';
import '../../../testing/fakes/fake_widget_data_repository.dart';

void main() {
  late FakeLogStore logs;
  late FakeDeviceInfo device;
  late FakeWidgetDataRepository data;

  setUp(() {
    logs = FakeLogStore()
      ..stored.add(
        LogEntry(
          time: DateTime.utc(2026, 11, 20, 12),
          level: 'SEVERE',
          logger: 'ApiClient',
          message: 'HTTP 503',
        ),
      );
    device = FakeDeviceInfo();
    data = FakeWidgetDataRepository()
      ..json['/api/modules'] = {
        'modules': ['todos', 'bookmarks'],
      };
  });

  DiagnosticsRepository repository(FakeServerRepository server) =>
      DiagnosticsRepository(
        logs: logs,
        device: device,
        server: server,
        data: data,
      );

  test('reports versions, modules and the log without the address', () async {
    final address = switch (ServerAddress.parse(
      'https://nas.example.org:8090',
    )) {
      Ok(:final value) => value,
      Error(:final error) => throw error,
    };
    final report = await repository(FakeServerRepository(current: address))
        .report(appVersion: '0.2.0+42');
    expect(report.serverVersion, '1.2.3');
    expect(report.modules, ['bookmarks', 'todos']);
    expect(report.connection, 'https');
    expect(
      report.text,
      contains('2026-11-20T12:00:00.000Z SEVERE ApiClient: HTTP 503'),
    );
    expect(report.text, contains('Android 15'));
    expect(report.text, isNot(contains('nas.example.org')));
  });

  test('works without a server and shares only on request', () async {
    final repo = repository(FakeServerRepository());
    final report = await repo.report(appVersion: '');
    expect(report.serverVersion, 'not connected');
    expect(report.connection, 'none');
    expect(device.shared, isEmpty);
    await repo.share(report);
    expect(device.shared.single, report.text);
    await repo.clear();
    expect(logs.stored, isEmpty);
  });
}
