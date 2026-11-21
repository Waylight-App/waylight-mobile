import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:waylight_mobile/data/repositories/actions/home_server_actions_repository.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/data/repositories/widget_data/widget_data_repository.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/server_status.dart';
import 'package:waylight_mobile/ui/core/link_opener.dart';
import 'package:waylight_mobile/ui/widgets/registry.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../../testing/fakes/fake_action_repositories.dart';
import '../../../testing/fakes/fake_link_opener.dart';
import '../../../testing/fakes/fake_server_repository.dart';
import '../../../testing/fakes/fake_widget_data_repository.dart';
import '../../../testing/pump_app.dart';

void main() {
  setUpAll(initializeDateFormatting);

  // Recorded from https://demo.getwaylight.app.
  Object? fixture(String name) =>
      jsonDecode(File('test/fixtures/${name}_demo.json').readAsStringSync());

  late FakeWidgetDataRepository data;
  late FakeHomeServerActions actions;
  late FakeServerRepository servers;

  setUp(() {
    final services = (fixture('services')! as List<Object?>)
        .cast<Map<String, Object?>>();
    final proxmox = fixture('proxmox_status')! as Map<String, Object?>;
    final guests = (proxmox['guests']! as List<Object?>)
        .cast<Map<String, Object?>>();
    data = FakeWidgetDataRepository()
      ..json['/api/services'] = [
        {...services.first, 'mac': 'aa:bb:cc:dd:ee:ff'},
        ...services.skip(1),
      ]
      ..json['/api/docker/containers'] = fixture('docker_containers')
      ..json['/api/proxmox/status'] = {
        ...proxmox,
        'guests': [
          {...guests.first, 'actions': true},
          ...guests.skip(1),
        ],
      }
      ..json['/api/adguard/stats'] = fixture('adguard_stats');
    actions = FakeHomeServerActions()
      ..docker = const DockerActions(
        enabled: true,
        containers: {'adguardhome'},
      );
    servers = FakeServerRepository(current: testServer())
      ..statusResult = const Result.ok(
        ServerStatus(setupRequired: false, role: 'owner'),
      );
  });

  Future<void> pump(
    WidgetTester tester,
    String kind, {
    Map<String, Object?> config = const {},
  }) async {
    final placement = WidgetPlacement(id: kind, kind: kind, config: config);
    await tester.pumpScreen(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ServerRepository>.value(value: servers),
          Provider<WidgetDataRepository>.value(value: data),
          Provider<HomeServerActionsRepository>.value(value: actions),
        ],
        child: LinkOpenerScope(
          opener: FakeLinkOpener(),
          child: SingleChildScrollView(
            child: Builder(
              builder: (context) =>
                  nativeWidgets.builderFor(kind)!(context, placement),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('wakes a service with a MAC address', (tester) async {
    await pump(tester, 'services');
    await tester.tap(find.text('DuckDuckGo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10nEn.servicesWake));
    await tester.pumpAndSettle();
    expect(actions.calls, ['wake:15e393e3e6f05a05bd0bc846b3b2bc38']);
  });

  testWidgets('restarts an allowed container after asking', (tester) async {
    await pump(tester, 'docker');
    await tester.tap(find.text('adguardhome'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10nEn.dockerRestart));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, l10nEn.dockerRestart));
    await tester.pumpAndSettle();
    expect(actions.calls, ['restart:adguardhome']);
    expect(find.text(l10nEn.dockerRestarted('adguardhome')), findsOneWidget);
  });

  testWidgets('shows the log of an allowed container', (tester) async {
    await pump(tester, 'docker');
    await tester.tap(find.text('adguardhome'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10nEn.dockerLogs));
    await tester.pumpAndSettle();
    expect(find.textContaining('line 2'), findsOneWidget);
  });

  testWidgets('shuts down an allowed guest and pauses the DNS filter', (
    tester,
  ) async {
    await pump(tester, 'proxmox');
    await tester.tap(find.text('home-assistant'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, l10nEn.proxmoxShutdown));
    await tester.pumpAndSettle();
    expect(actions.calls, ['shutdown:100']);

    await pump(tester, 'adguard');
    await tester.tap(find.text(l10nEn.dnsFilterOn));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10nEn.dnsFilterPause(30)));
    await tester.pumpAndSettle();
    expect(actions.calls.last, 'pause:adguard:30');
  });

  testWidgets('a DNS filter set to Pi-hole reads and pauses Pi-hole (#280)', (
    tester,
  ) async {
    await pump(tester, 'adguard', config: {'provider': 'pihole'});
    expect(data.asked.last.path, '/api/adguard/stats');
    expect(data.asked.last.query, {'provider': 'pihole'});
    await tester.tap(find.text(l10nEn.dnsFilterOn));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10nEn.dnsFilterPause(5)));
    await tester.pumpAndSettle();
    expect(actions.calls.last, 'pause:pihole:5');
  });

  testWidgets('a DNS filter without a provider reads AdGuard Home (#280)', (
    tester,
  ) async {
    await pump(tester, 'adguard');
    expect(data.asked.last.query, {'provider': 'adguard'});
  });

  testWidgets('members get no actions', (tester) async {
    servers.statusResult = const Result.ok(
      ServerStatus(setupRequired: false, role: 'member'),
    );
    await pump(tester, 'docker');
    await tester.tap(find.text('adguardhome'));
    await tester.pumpAndSettle();
    expect(find.text(l10nEn.dockerRestart), findsNothing);
    expect(actions.calls, isEmpty);
  });
}
