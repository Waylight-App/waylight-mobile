import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:quick_actions/quick_actions.dart';

import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/routing/shortcuts.dart';
import 'package:waylight_mobile/ui/core/app_shortcuts.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/dashboard/view_models/dashboard_view_model.dart';

import '../../testing/fakes/fake_dashboard_repository.dart';
import '../../testing/fakes/fake_server_repository.dart';

/// Records the shortcuts instead of talking to the platform.
class _FakeQuickActions extends QuickActions {
  _FakeQuickActions();

  QuickActionHandler? handler;
  List<ShortcutItem> items = [];

  @override
  Future<void> initialize(QuickActionHandler handler) async =>
      this.handler = handler;

  @override
  Future<void> setShortcutItems(List<ShortcutItem> items) async =>
      this.items = items;
}

void main() {
  test('each shortcut leads to its place', () {
    expect(shortcutLocation(AppShortcut.addTodo), '/search?q=t+');
    expect(shortcutLocation(AppShortcut.departures), '/?widget=transit');
    expect(shortcutLocation(AppShortcut.search), '/search');
    expect(AppShortcut.ofType('search'), AppShortcut.search);
    expect(AppShortcut.ofType('other'), isNull);
  });

  test('the dashboard opens the tab of the requested widget kind', () {
    final viewModel = DashboardViewModel(
      serverRepository: FakeServerRepository(current: testServer()),
      dashboardRepository: FakeDashboardRepository(),
      initialWidgetKind: 'transit',
    );
    const dashboard = Dashboard(
      tabs: [
        DashboardTab(
          id: 'a',
          name: 'Home',
          widgets: [WidgetPlacement(id: '1', kind: 'clock')],
        ),
        DashboardTab(
          id: 'b',
          name: 'Out',
          widgets: [WidgetPlacement(id: '2', kind: 'transit')],
        ),
      ],
    );

    expect(viewModel.initialIndexIn(dashboard), 1);
    viewModel.dispose();
  });

  testWidgets('registers translated shortcuts and opens their place', (
    tester,
  ) async {
    final actions = _FakeQuickActions();
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const Text('home')),
        GoRoute(
          path: '/search',
          builder: (_, s) => Text('search ${s.uri.queryParameters['q'] ?? ''}'),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => AppShortcuts(
          onShortcut: (s) => router.go(shortcutLocation(s)),
          actions: actions,
          child: child!,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(actions.items.map((i) => i.type), [
      'addTodo',
      'departures',
      'search',
    ]);
    expect(actions.items.first.localizedTitle, 'Add to-do');

    actions.handler!('addTodo');
    await tester.pumpAndSettle();
    expect(find.text('search t '), findsOneWidget);
  });
}
