import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:waylight_mobile/data/repositories/home_widgets/home_widgets_repository.dart';
import 'package:waylight_mobile/data/repositories/offline/offline_repository.dart';
import 'package:waylight_mobile/data/services/api/offline_status.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/home_snapshot.dart';
import 'package:waylight_mobile/ui/core/link_opener.dart';
import 'package:waylight_mobile/ui/core/widget_registry.dart';
import 'package:waylight_mobile/ui/dashboard/view_models/dashboard_view_model.dart';
import 'package:waylight_mobile/ui/dashboard/widgets/dashboard_screen.dart';
import 'package:waylight_mobile/ui/home_widgets/home_widget_texts.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../testing/fakes/fake_dashboard_repository.dart';
import '../../testing/fakes/fake_home_widget_store.dart';
import '../../testing/fakes/fake_link_opener.dart';
import '../../testing/fakes/fake_server_repository.dart';
import '../../testing/fakes/fake_todos_repository.dart';
import '../../testing/fakes/fake_transit_repository.dart';
import '../../testing/pump_app.dart';

void main() {
  late FakeServerRepository servers;
  late FakeDashboardRepository dashboards;
  late OfflineStatus offlineStatus;
  var registry = const WidgetRegistry({});

  const twoTabs = Dashboard(
    defaultTabId: 't2',
    tabs: [
      DashboardTab(
        id: 't1',
        name: 'Home',
        widgets: [WidgetPlacement(id: 'w1', kind: 'clock')],
      ),
      DashboardTab(
        id: 't2',
        name: 'Server',
        widgets: [
          WidgetPlacement(id: 'w2', kind: 'status-overview'),
          WidgetPlacement(id: 'w3', kind: 'docker', title: 'Containers'),
        ],
      ),
    ],
  );

  DashboardViewModel create() => DashboardViewModel(
    serverRepository: servers,
    dashboardRepository: dashboards,
    offlineRepository: OfflineRepository(offlineStatus),
  );

  late FakeLinkOpener opener;

  Future<void> pump(WidgetTester tester) async {
    opener = FakeLinkOpener();
    await tester.pumpScreen(
      LinkOpenerScope(
        opener: opener,
        child: DashboardScreen(viewModel: create(), registry: registry),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    servers = FakeServerRepository(current: testServer());
    offlineStatus = OfflineStatus();
    dashboards = FakeDashboardRepository()..result = const Result.ok(twoTabs);
  });

  testWidgets('shows the tabs and opens the default tab', (tester) async {
    await pump(tester);

    expect(find.widgetWithText(Tab, 'Home'), findsOneWidget);
    expect(find.widgetWithText(Tab, 'Server'), findsOneWidget);
    expect(find.text('Status overview'), findsOneWidget);
    expect(find.text('Containers'), findsOneWidget);
  });

  testWidgets('switches tabs', (tester) async {
    await pump(tester);

    await tester.tap(find.widgetWithText(Tab, 'Home'));
    await tester.pumpAndSettle();

    expect(find.text('Clock'), findsOneWidget);
  });

  testWidgets('says when a tab is empty', (tester) async {
    dashboards.result = const Result.ok(
      Dashboard(
        tabs: [DashboardTab(id: 't', name: 'Empty', widgets: [])],
      ),
    );
    await pump(tester);

    expect(find.text(l10nEn.dashboardEmptyTab), findsOneWidget);
    expect(find.byType(TabBar), findsNothing);
  });

  testWidgets('says when there are no tabs', (tester) async {
    dashboards.result = const Result.ok(Dashboard(tabs: []));
    await pump(tester);

    expect(find.text(l10nEn.dashboardNoTabs), findsOneWidget);
  });

  testWidgets('shows errors and loads again', (tester) async {
    dashboards.result = const Result.error(
      ApiException(ApiFailure.unreachable),
    );
    await pump(tester);
    expect(find.text(l10nEn.errorUnreachable), findsOneWidget);

    dashboards.result = const Result.ok(twoTabs);
    await tester.tap(find.byKey(const ValueKey('dashboard.retry')));
    await tester.pumpAndSettle();

    expect(dashboards.calls, 2);
    expect(find.widgetWithText(Tab, 'Server'), findsOneWidget);
  });

  testWidgets('meets the accessibility guidelines', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester);

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });

  testWidgets('uses the native view of a registered kind', (tester) async {
    registry = WidgetRegistry({
      'docker': (context, widget) => Text('native ${widget.id}'),
    });
    await pump(tester);

    expect(find.text('native w3'), findsOneWidget);
    expect(find.text('Status overview'), findsOneWidget);
    registry = const WidgetRegistry({});
  });

  testWidgets('opens the tab of a widget without native view', (tester) async {
    await pump(tester);

    await tester.tap(find.text(l10nEn.dashboardOpenInWaylight).first);
    await tester.pump();

    expect(opener.opened.single.toString(), 'https://home.example.org/?tab=t2');
  });

  testWidgets('pulls to refresh a tab', (tester) async {
    await pump(tester);

    await tester.fling(
      find.text('Status overview'),
      const Offset(0, 400),
      1000,
    );
    await tester.pumpAndSettle();

    expect(find.byType(RefreshIndicator), findsWidgets);
  });

  testWidgets('says when it shows stored data', (tester) async {
    await pump(tester);
    expect(find.byKey(const ValueKey('dashboard.offline')), findsNothing);

    offlineStatus.servedStored(DateTime(2026, 11, 19, 7, 58));
    await tester.pump();

    expect(find.text(l10nEn.dashboardOffline('07:58')), findsOneWidget);
  });

  for (final (width, columns) in [(390.0, 1), (700.0, 2), (1200.0, 3)]) {
    testWidgets('uses $columns column(s) at $width dp', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      dashboards.result = Result.ok(
        Dashboard(
          tabs: [
            DashboardTab(
              id: 't',
              name: 'Many',
              widgets: [
                for (var i = 0; i < 6; i++)
                  WidgetPlacement(id: 'w$i', kind: 'kind$i'),
              ],
            ),
          ],
        ),
      );
      await pump(tester);

      final lefts = {
        for (var i = 0; i < 3; i++)
          tester.getTopLeft(find.text('Kind$i')).dx.round(),
      };
      expect(lefts, hasLength(columns));
    });
  }

  test('every load refreshes the home screen widgets', () async {
    final store = FakeHomeWidgetStore();
    final vm = DashboardViewModel(
      serverRepository: servers,
      dashboardRepository: dashboards,
      homeWidgetsRepository: HomeWidgetsRepository(
        dashboard: dashboards,
        todos: FakeTodosRepository(),
        transit: FakeTransitRepository(),
        store: store,
      ),
      homeWidgetFormatter: HomeWidgetTexts(l10nEn),
    );
    addTearDown(vm.dispose);
    await vm.load.execute();
    await pumpEventQueue();
    expect(store.scheduled, isTrue);
    expect(store.cards.keys, containsAll(HomeWidgetKind.values));
  });
}
