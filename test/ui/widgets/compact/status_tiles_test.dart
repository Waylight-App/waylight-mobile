import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:waylight_mobile/data/repositories/compact/compact_state_repository.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/compact_state.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/ui/core/widget_size_scope.dart';
import 'package:waylight_mobile/ui/widgets/adguard/adguard_widget.dart';
import 'package:waylight_mobile/ui/widgets/backups/backups_widget.dart';
import 'package:waylight_mobile/ui/widgets/calendar/calendar_widget.dart';
import 'package:waylight_mobile/ui/widgets/diskhealth/diskhealth_widget.dart';
import 'package:waylight_mobile/ui/widgets/docker/docker_widget.dart';
import 'package:waylight_mobile/ui/widgets/electricity/electricity_widget.dart';
import 'package:waylight_mobile/ui/widgets/parcels/parcels_widget.dart';
import 'package:waylight_mobile/ui/widgets/proxmox/proxmox_widget.dart';
import 'package:waylight_mobile/ui/widgets/services/services_widget.dart';
import 'package:waylight_mobile/ui/widgets/smarthome/smarthome_widget.dart';
import 'package:waylight_mobile/ui/widgets/speedtest/speedtest_widget.dart';
import 'package:waylight_mobile/ui/widgets/wireguard/wireguard_widget.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../../testing/fakes/fake_compact_state_repository.dart';
import '../../../testing/fakes/fake_server_repository.dart';
import '../../../testing/pump_app.dart';

typedef _Builder = Widget Function(BuildContext, WidgetPlacement);

/// Small and strip tiles of the status widgets show the server's compact
/// state (#274, #278) and fit their tile.
void main() {
  const smallTile = Size(150, 150);
  const stripTile = Size(328, 70);

  final kinds = <(String, _Builder, String, Map<String, Object?>)>[
    ('services', ServicesWidget.forPlacement, 'Services', {}),
    ('status-overview', StatusOverviewWidget.forPlacement, 'Status', {}),
    ('backup-status', BackupsWidget.forPlacement, 'Backups', {}),
    ('diskhealth', DiskHealthWidget.forPlacement, 'Disk health', {}),
    ('docker', DockerWidget.forPlacement, 'Docker', {}),
    ('parcels', ParcelsWidget.forPlacement, 'Parcels', {}),
    ('speedtest', SpeedtestWidget.forPlacement, 'Speed test', {}),
    ('calendar', CalendarWidget.forPlacement, 'Calendar', {}),
    (
      'smarthome',
      SmartHomeWidget.forPlacement,
      'Smart home',
      {
        'entities': ['light.desk'],
      },
    ),
    // Waylight-App/waylight#650 (#278).
    ('proxmox', ProxmoxWidget.forPlacement, 'Proxmox VE', {}),
    (
      'adguard',
      AdguardWidget.forPlacement,
      'DNS filter',
      {'provider': 'pihole'},
    ),
    ('wireguard', WireguardWidget.forPlacement, 'WireGuard', {}),
    (
      'electricity',
      ElectricityWidget.forPlacement,
      'Electricity',
      {'zone': 'AT'},
    ),
  ];

  late FakeCompactStateRepository compact;

  setUp(() {
    compact = FakeCompactStateRepository(kinds: {for (final k in kinds) k.$1})
      ..result = const Result.ok(
        CompactState(
          title: CompactText(text: '2 of 14 need attention right now'),
          detail: CompactText(text: 'Nightly NAS backup failed at 03:00'),
          level: CompactLevel.problem,
        ),
      );
  });

  Future<void> pump(
    WidgetTester tester,
    _Builder builder,
    WidgetPlacement placement,
    WidgetSize size,
    Size pixels,
  ) async {
    await tester.pumpScreen(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ServerRepository>.value(
            value: FakeServerRepository(current: testServer()),
          ),
          Provider<CompactStateRepository?>.value(value: compact),
        ],
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox.fromSize(
            size: pixels,
            child: WidgetSizeScope(
              size: size,
              child: Builder(builder: (context) => builder(context, placement)),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final (kind, builder, title, config) in kinds) {
    final placement = WidgetPlacement(
      id: 'w-$kind',
      kind: kind,
      title: title,
      config: config,
    );

    testWidgets('$kind: a small tile shows title and detail', (tester) async {
      await pump(tester, builder, placement, WidgetSize.small, smallTile);

      expect(compact.asked, [kind]);
      expect(compact.configs.single, config);
      expect(find.text(title), findsOneWidget);
      expect(find.text('2 of 14 need attention right now'), findsOneWidget);
      expect(find.text('Nightly NAS backup failed at 03:00'), findsOneWidget);
    });

    testWidgets('$kind: a strip shows the title line', (tester) async {
      await pump(tester, builder, placement, WidgetSize.strip, stripTile);

      expect(find.text('2 of 14 need attention right now'), findsOneWidget);
      expect(find.text('Nightly NAS backup failed at 03:00'), findsNothing);
    });
  }

  group('the action of the server state', () {
    const placement = WidgetPlacement(
      id: 'w-smarthome',
      kind: 'smarthome',
      config: {
        'entities': ['light.desk'],
      },
    );
    const toggle = CompactAction(
      id: 'smarthome.toggle',
      label: CompactText(text: 'Turn off'),
      method: 'POST',
      path: '/api/smarthome/entities/light.desk/action',
    );

    setUp(() {
      compact.result = const Result.ok(
        CompactState(
          title: CompactText(text: 'Desk lamp'),
          detail: CompactText(text: 'On'),
          action: toggle,
        ),
      );
    });

    for (final (size, pixels) in [
      (WidgetSize.small, smallTile),
      (WidgetSize.strip, stripTile),
    ]) {
      testWidgets('runs from a ${size.name} tile and reloads', (tester) async {
        await pump(
          tester,
          SmartHomeWidget.forPlacement,
          placement,
          size,
          pixels,
        );
        expect(compact.asked, hasLength(1));
        // The button takes the room of the detail line.
        expect(find.text('On'), findsNothing);

        await tester.tap(find.text('Turn off'));
        await tester.pumpAndSettle();

        expect(compact.ran.single.$1, same(toggle));
        expect(compact.ran.single.$2, isNull);
        expect(compact.asked, hasLength(2));
      });
    }

    testWidgets('a failure is shown and keeps the state', (tester) async {
      compact.runResult = const Result.error(
        ApiException(ApiFailure.forbidden),
      );
      await pump(
        tester,
        SmartHomeWidget.forPlacement,
        placement,
        WidgetSize.small,
        smallTile,
      );

      await tester.tap(find.text('Turn off'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(compact.asked, hasLength(1));
    });

    testWidgets('choices open a menu', (tester) async {
      const office = CompactChoice(
        id: 'office',
        label: CompactText(text: 'Office'),
        body: {'status': 'office'},
        selected: true,
      );
      const home = CompactChoice(
        id: 'home',
        label: CompactText(text: 'Home'),
        body: {'status': 'home'},
      );
      compact.result = const Result.ok(
        CompactState(
          title: CompactText(text: 'In the office'),
          action: CompactAction(
            id: 'presence.set',
            label: CompactText(text: 'Set status'),
            method: 'PUT',
            path: '/api/presence/me',
            choices: [office, home],
          ),
        ),
      );
      await pump(
        tester,
        SmartHomeWidget.forPlacement,
        placement,
        WidgetSize.strip,
        stripTile,
      );

      await tester.tap(find.byTooltip('Set status'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(CheckedPopupMenuItem<CompactChoice>, 'Home'),
      );
      await tester.pumpAndSettle();

      expect(compact.ran.single.$2, same(home));
    });
  });
}
