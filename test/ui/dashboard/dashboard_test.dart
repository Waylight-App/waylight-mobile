import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/ui/core/link_opener.dart';
import 'package:waylight_mobile/ui/core/widget_registry.dart';
import 'package:waylight_mobile/ui/dashboard/view_models/dashboard_view_model.dart';
import 'package:waylight_mobile/ui/dashboard/widgets/dashboard_screen.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../testing/fakes/fake_dashboard_repository.dart';
import '../../testing/fakes/fake_link_opener.dart';
import '../../testing/fakes/fake_server_repository.dart';
import '../../testing/pump_app.dart';

void main() {
  late FakeServerRepository servers;
  late FakeDashboardRepository dashboards;
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
}
