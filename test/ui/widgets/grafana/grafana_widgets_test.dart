import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/data/repositories/widget_data/queries/home_server.dart';
import 'package:waylight_mobile/data/repositories/widget_data/widget_data_repository.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/ui/core/link_opener.dart';
import 'package:waylight_mobile/ui/widgets/registry.dart';

import '../../../testing/fakes/fake_link_opener.dart';
import '../../../testing/fakes/fake_server_repository.dart';
import '../../../testing/fakes/fake_widget_data_repository.dart';
import '../../../testing/pump_app.dart';

// The answer of GET /api/grafana/alerts (server PR #580).
final _alerts = {
  'url': 'http://grafana.local/alerting/list',
  'alerts': [
    {
      'name': 'Disk full',
      'summary': '/ at 95 %',
      'severity': 'critical',
      'state': 'firing',
      'since': '2026-11-20T08:00:00Z',
    },
    {'name': 'CPU high', 'summary': '', 'severity': '', 'state': 'pending'},
  ],
};

// A 1×1 transparent PNG.
final _png = Uint8List.fromList([
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52, //
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4, //
  0x89,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00, //
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE, //
  0x42, 0x60, 0x82,
]);

void main() {
  late FakeWidgetDataRepository data;
  late FakeLinkOpener opener;

  setUp(() {
    data = FakeWidgetDataRepository()
      ..json['/api/grafana/alerts'] = _alerts
      ..images['/api/grafana/render/node/2'] = _png;
    opener = FakeLinkOpener();
  });

  Future<void> pump(
    WidgetTester tester,
    String kind, [
    Map<String, Object?> config = const {},
  ]) async {
    await tester.pumpScreen(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ServerRepository>.value(
            value: FakeServerRepository(current: testServer()),
          ),
          Provider<WidgetDataRepository>.value(value: data),
        ],
        child: LinkOpenerScope(
          opener: opener,
          child: SingleChildScrollView(
            child: Builder(
              builder: (context) => nativeWidgets.builderFor(kind)!(
                context,
                WidgetPlacement(id: kind, kind: kind, config: config),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  test('reads the alerts and drops unsafe links', () {
    final a = parseGrafanaAlerts(_alerts)!;
    expect(a.alerts.map((x) => x.firing), [true, false]);
    expect(a.alerts.first.since, DateTime.utc(2026, 11, 20, 8).toLocal());
    expect(a.url?.host, 'grafana.local');
    expect(
      parseGrafanaAlerts({'alerts': <Object?>[], 'url': 'javascript:alert(1)'})!
          .url,
      isNull,
    );
    expect(parseGrafanaAlerts({'nope': 1}), isNull);
  });

  testWidgets('the alerts widget lists the alerts and opens Grafana', (
    tester,
  ) async {
    await pump(tester, 'grafana-alerts');
    expect(find.text('Disk full'), findsOneWidget);
    expect(find.text('CPU high'), findsOneWidget);
    await tester.tap(find.text(l10nEn.grafanaAlertList));
    await tester.pump();
    expect(opener.opened.single.path, '/alerting/list');
  });

  testWidgets(
    'the panel widget shows the rendered panel and opens it in Grafana',
    (tester) async {
      await pump(tester, 'grafana-panel', {
        'dashboardUid': 'node',
        'panelId': 2,
        'panelTitle': 'CPU',
        'range': '7d',
        'dashboardUrl': 'http://grafana.local/d/node/node',
      });
      expect(find.text('CPU'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      await tester.tap(find.byType(Image));
      await tester.pump();
      expect(opener.opened.single.queryParameters, {
        'viewPanel': '2',
        'from': 'now-7d',
        'to': 'now',
      });
    },
  );

  testWidgets('without a panel it says where to choose one', (tester) async {
    await pump(tester, 'grafana-panel');
    expect(find.text(l10nEn.grafanaChoosePanel), findsOneWidget);
  });
}
