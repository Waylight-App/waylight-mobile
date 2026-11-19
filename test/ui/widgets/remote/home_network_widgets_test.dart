import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/data/repositories/widget_data/queries/everyday.dart';
import 'package:waylight_mobile/data/repositories/widget_data/queries/home_server.dart';
import 'package:waylight_mobile/data/repositories/widget_data/queries/network.dart';
import 'package:waylight_mobile/data/repositories/widget_data/widget_data_repository.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/network.dart';
import 'package:waylight_mobile/ui/core/link_opener.dart';
import 'package:waylight_mobile/ui/widgets/registry.dart';

import '../../../testing/fakes/fake_link_opener.dart';
import '../../../testing/fakes/fake_server_repository.dart';
import '../../../testing/fakes/fake_widget_data_repository.dart';
import '../../../testing/pump_app.dart';

void main() {
  setUpAll(initializeDateFormatting);

  // Recorded from https://demo.getwaylight.app.
  Object? fixture(String name) =>
      jsonDecode(File('test/fixtures/${name}_demo.json').readAsStringSync());

  const endpoints = {
    '/api/holidays': 'holidays',
    '/api/diskhealth': 'diskhealth',
    '/api/docker/containers': 'docker_containers',
    '/api/proxmox/status': 'proxmox_status',
    '/api/speedtest/results': 'speedtest_results',
    '/api/timeline': 'timeline',
    '/api/wireguard/peers': 'wireguard_peers',
    '/api/fritzbox/status': 'fritzbox_status',
    '/api/fritzbox/calls': 'fritzbox_calls',
    '/api/adguard/stats': 'adguard_stats',
  };

  late FakeWidgetDataRepository data;
  late FakeLinkOpener links;

  setUp(() {
    data = FakeWidgetDataRepository();
    for (final MapEntry(:key, :value) in endpoints.entries) {
      data.json[key] = fixture(value);
    }
    links = FakeLinkOpener();
  });

  Future<void> pump(WidgetTester tester, String kind) async {
    final placement = WidgetPlacement(id: kind, kind: kind);
    await tester.pumpScreen(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ServerRepository>.value(
            value: FakeServerRepository(current: testServer()),
          ),
          Provider<WidgetDataRepository>.value(value: data),
        ],
        child: LinkOpenerScope(
          opener: links,
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

  test('the parsers read the demo', () {
    final holidays = parseHolidays(fixture('holidays'))!;
    expect(holidays.first.key, 'christmas_day');
    expect(holidays.first.school, isFalse);
    expect(parseDiskHealth(fixture('diskhealth'))!.first.findings, isNotEmpty);
    final docker = parseDocker(fixture('docker_containers'))!;
    expect(docker.running, 4);
    expect(docker.stopped, 1);
    final pve = parseProxmox(fixture('proxmox_status'))!;
    expect(pve.nodes.single.name, 'pve');
    expect(pve.guests.first.name, 'home-assistant');
    expect(
      parseSpeedtest(fixture('speedtest_results'))!.latest!.downloadMbps,
      195,
    );
    expect(parseTimeline(fixture('timeline'))!.first.source, 'container');
    expect(
      parseWireguard(fixture('wireguard_peers'))!.first.name,
      "Anna's phone",
    );
    expect(parseFritzbox(fixture('fritzbox_status'))!.connected, isTrue);
    final calls = parseCalls(fixture('fritzbox_calls'))!;
    expect(calls.first.name, 'Mama');
    expect(calls.map((c) => c.type), contains(CallType.rejected));
    final dns = parseDnsFilter(fixture('adguard_stats'))!;
    expect(dns.queries, 48213);
    expect(dns.topBlocked.first.$1, 'telemetry.example-tv.com');
  });

  for (final kind in [
    'holidays',
    'diskhealth',
    'docker',
    'proxmox',
    'speedtest',
    'timeline',
    'wireguard',
    'fritzbox',
    'fritzbox-calls',
    'adguard',
  ]) {
    testWidgets('$kind renders the demo data', (tester) async {
      await pump(tester, kind);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('content of a few widgets', (tester) async {
    await pump(tester, 'holidays');
    expect(find.text(l10nEn.holidayChristmasDay), findsOneWidget);

    await pump(tester, 'docker');
    expect(find.text(l10nEn.dockerSummary(4, 1, 0)), findsOneWidget);

    await pump(tester, 'fritzbox-calls');
    await tester.tap(find.text('Mama'));
    expect(links.opened.single.scheme, 'tel');
    expect(links.opened.single.path, '0441123456');

    await pump(tester, 'adguard');
    expect(find.text('telemetry.example-tv.com'), findsOneWidget);
  });
}
