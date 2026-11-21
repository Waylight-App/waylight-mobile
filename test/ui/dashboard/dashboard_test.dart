import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:waylight_mobile/data/repositories/home_widgets/home_widgets_repository.dart';
import 'package:waylight_mobile/data/repositories/offline/offline_repository.dart';
import 'package:waylight_mobile/data/services/api/offline_status.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/attention.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/home_snapshot.dart';
import 'package:waylight_mobile/ui/core/link_opener.dart';
import 'package:waylight_mobile/ui/core/widget_registry.dart';
import 'package:waylight_mobile/ui/core/widget_size_scope.dart';
import 'package:waylight_mobile/ui/dashboard/view_models/dashboard_view_model.dart';
import 'package:waylight_mobile/ui/dashboard/widgets/dashboard_screen.dart';
import 'package:waylight_mobile/ui/dashboard/widgets/widget_full_screen.dart';
import 'package:waylight_mobile/ui/dashboard/widgets/widget_grid.dart';
import 'package:waylight_mobile/ui/home_widgets/home_widget_texts.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../testing/fakes/fake_attention_repository.dart';
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

  testWidgets('shows a badge while something needs attention', (tester) async {
    final attention = FakeAttentionRepository(
      items: const [
        AttentionItem(
          id: 'module:immich',
          kind: AttentionKind.connection,
          integration: 'immich',
          title: 'immich',
          message: '',
          action: AttentionAction.check,
        ),
      ],
    );
    await tester.pumpScreen(
      DashboardScreen(
        viewModel: DashboardViewModel(
          serverRepository: servers,
          dashboardRepository: dashboards,
          attentionRepository: attention,
        ),
        registry: registry,
      ),
    );
    await tester.pumpAndSettle();

    expect(attention.refreshes, 1, reason: 'follows the dashboard load');
    final badge = find.byKey(const ValueKey('dashboard.attention'));
    expect(badge, findsOneWidget);
    expect(find.text('1'), findsOneWidget);

    attention.result = const Result.ok([]);
    await attention.refresh(testServer());
    await tester.pump();
    expect(badge, findsNothing, reason: 'an empty list hides the badge');
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

  group('grid of sizes (#208)', () {
    Dashboard sized(Map<String, WidgetSize> sizes, {int count = 4}) =>
        Dashboard(
          tabs: [
            DashboardTab(
              id: 't',
              name: 'Home',
              widgets: [
                for (var i = 0; i < count; i++)
                  WidgetPlacement(id: 'w$i', kind: 'kind$i'),
              ],
            ).withSizes(sizes),
          ],
        );

    setUp(() {
      registry = WidgetRegistry({
        for (var i = 0; i < 4; i++)
          'kind$i': (context, widget) => Text('native ${widget.id}'),
      });
    });
    tearDown(() => registry = const WidgetRegistry({}));

    testWidgets('puts small widgets side by side', (tester) async {
      dashboards.result = Result.ok(
        sized({'w0': WidgetSize.small, 'w1': WidgetSize.small}),
      );
      await pump(tester);

      final first = tester.getTopLeft(find.text('native w0'));
      final second = tester.getTopLeft(find.text('native w1'));
      expect(second.dy, first.dy);
      expect(second.dx, greaterThan(first.dx));
    });

    testWidgets('keeps widgets without a size at full width', (tester) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      dashboards.result = Result.ok(
        sized({'w0': WidgetSize.small, 'w1': WidgetSize.small}),
      );
      await pump(tester);

      final tile = tester.getTopLeft(find.text('native w0'));
      final full = tester.getTopLeft(find.text('native w2'));
      expect(full.dx, tile.dx);
      expect(full.dy, greaterThan(tile.dy));
      expect(find.byType(WidgetTile), findsNWidgets(2));
    });

    testWidgets('tells the view the size of its tile', (tester) async {
      WidgetSize? seen;
      registry = WidgetRegistry({
        'kind0': (context, widget) {
          seen = WidgetSizeScope.maybeOf(context);
          return const Text('sized');
        },
      });
      dashboards.result = Result.ok(sized({'w0': WidgetSize.medium}));
      await pump(tester);

      expect(seen, WidgetSize.medium);
    });

    testWidgets('fades out content that does not fit', (tester) async {
      registry = WidgetRegistry({
        'kind0': (context, widget) =>
            Column(children: [for (var i = 0; i < 30; i++) Text('line $i')]),
        'kind1': (context, widget) => const Text('short'),
      });
      dashboards.result = Result.ok(
        sized({'w0': WidgetSize.medium, 'w1': WidgetSize.medium}),
      );
      await pump(tester);

      WidgetTileState tile(String id) => tester.state<WidgetTileState>(
        find.descendant(
          of: find.byKey(ValueKey('grid.$id')),
          matching: find.byType(WidgetTile),
        ),
      );
      expect(tile('w0').fades, isTrue);
      expect(tile('w1').fades, isFalse);
    });

    testWidgets('keeps the view when it starts to overflow', (tester) async {
      // Regression: wrapping the view only while it overflowed rebuilt it,
      // so it reloaded, got shorter and flickered in a loop.
      final grow = ValueNotifier(false);
      addTearDown(grow.dispose);
      var created = 0;
      registry = WidgetRegistry({
        'kind0': (context, widget) => _Counting(
          onCreate: () => created++,
          child: ValueListenableBuilder(
            valueListenable: grow,
            builder: (context, tall, _) => Column(
              children: [
                for (var i = 0; i < (tall ? 30 : 1); i++) Text('line $i'),
              ],
            ),
          ),
        ),
      });
      dashboards.result = Result.ok(sized({'w0': WidgetSize.medium}));
      await pump(tester);

      grow.value = true;
      await tester.pumpAndSettle();
      grow.value = false;
      await tester.pumpAndSettle();

      expect(created, 1);
    });

    testWidgets('opens a widget in full on tap and goes back', (tester) async {
      dashboards.result = Result.ok(sized({'w0': WidgetSize.small}));
      await pump(tester);

      await tester.tap(find.byKey(const ValueKey('grid.w0')));
      await tester.pumpAndSettle();

      expect(find.byType(WidgetFullScreen), findsOneWidget);
      expect(find.widgetWithText(AppBar, 'Kind0'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(WidgetFullScreen),
          matching: find.text('native w0'),
        ),
        findsOneWidget,
      );

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(WidgetFullScreen), findsNothing);
    });

    testWidgets('uses eight columns on tablets', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      dashboards.result = Result.ok(
        sized({
          'w0': WidgetSize.medium,
          'w1': WidgetSize.medium,
          'w2': WidgetSize.small,
        }),
      );
      await pump(tester);

      final rows = {
        for (var i = 0; i < 2; i++)
          tester.getTopLeft(find.text('native w$i')).dy.round(),
      };
      expect(rows, hasLength(1), reason: 'two medium widgets in one row');
    });

    testWidgets('meets the accessibility guidelines', (tester) async {
      final handle = tester.ensureSemantics();
      dashboards.result = Result.ok(
        sized({'w0': WidgetSize.small, 'w1': WidgetSize.strip}),
      );
      await pump(tester);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  });

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

class _Counting extends StatefulWidget {
  const _Counting({required this.onCreate, required this.child});

  final VoidCallback onCreate;
  final Widget child;

  @override
  State<_Counting> createState() => _CountingState();
}

class _CountingState extends State<_Counting> {
  @override
  void initState() {
    super.initState();
    widget.onCreate();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
