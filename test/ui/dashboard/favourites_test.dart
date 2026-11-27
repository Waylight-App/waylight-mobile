import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/ui/core/widget_registry.dart';
import 'package:waylight_mobile/ui/dashboard/view_models/arrange_view_model.dart';
import 'package:waylight_mobile/ui/dashboard/view_models/dashboard_view_model.dart';
import 'package:waylight_mobile/ui/dashboard/widgets/dashboard_screen.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../testing/fakes/fake_dashboard_repository.dart';
import '../../testing/fakes/fake_server_repository.dart';
import '../../testing/pump_app.dart';

void main() {
  const clock = WidgetPlacement(id: 'clock', kind: 'clock', title: 'Clock');
  const notes = WidgetPlacement(id: 'notes', kind: 'notes', title: 'Notes');
  const docker = WidgetPlacement(id: 'docker', kind: 'docker', title: 'Box');
  const todos = WidgetPlacement(id: 'todos', kind: 'todos', title: 'Tasks');

  Dashboard dashboard({
    Set<String> home = const {},
    Set<String> server = const {},
  }) => Dashboard(
    defaultTabId: 'home',
    tabs: [
      const DashboardTab(
        id: 'server',
        name: 'Server',
        widgets: [docker, todos],
        layout: [
          PhoneLayoutItem(widget: docker),
          PhoneLayoutItem(widget: todos),
        ],
        sizes: {'todos': WidgetSize.small},
      ).withFavourites(server),
      const DashboardTab(
        id: 'home',
        name: 'Home',
        widgets: [clock, notes],
        layout: [
          PhoneLayoutItem(widget: clock),
          PhoneLayoutItem(widget: notes),
        ],
      ).withFavourites(home),
    ],
  );

  test('lists favourites in tab and layout order with their sizes', () {
    final favourites = dashboard(
      home: {'notes'},
      server: {'todos', 'docker'},
    ).favourites;
    expect(
      [for (final f in favourites) f.widget.id],
      ['docker', 'todos', 'notes'],
    );
    expect(favourites[1].size, WidgetSize.small);
  });

  test('the edit mode toggles a favourite and saves it', () async {
    final dashboards = FakeDashboardRepository();
    final vm = ArrangeViewModel(
      tab: dashboard().tabs.last,
      serverRepository: FakeServerRepository(current: testServer()),
      dashboardRepository: dashboards,
    );
    addTearDown(vm.dispose);

    vm.toggleFavourite('notes');
    expect(vm.changed, isTrue);
    await vm.save.execute();
    expect(dashboards.saved['home']!.map((i) => (i.widget.id, i.favourite)), [
      ('clock', false),
      ('notes', true),
    ]);

    vm.toggleFavourite('notes');
    expect(vm.items.last.favourite, isFalse);
  });

  Future<DashboardViewModel> pump(WidgetTester tester, Dashboard value) async {
    final vm = DashboardViewModel(
      serverRepository: FakeServerRepository(current: testServer()),
      dashboardRepository: FakeDashboardRepository()..result = Result.ok(value),
    );
    addTearDown(vm.dispose);
    await tester.pumpScreen(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: DashboardScreen(
          viewModel: vm,
          registry: const WidgetRegistry({}),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return vm;
  }

  testWidgets('shows favourites of every tab on top of the home tab', (
    tester,
  ) async {
    final vm = await pump(
      tester,
      dashboard(home: {'notes'}, server: {'todos'}),
    );

    final section = find.byKey(const ValueKey('dashboard.favourites'));
    expect(section, findsOneWidget);
    expect(find.text(l10nEn.dashboardFavourites), findsOneWidget);
    expect(find.text('Tasks'), findsOneWidget, reason: 'from another tab');
    expect(find.text('Notes'), findsOneWidget, reason: 'shown only once');
    expect(
      tester.getTopLeft(section).dy,
      lessThan(tester.getTopLeft(find.text('Tasks')).dy),
    );
    await tester.scrollUntilVisible(
      find.text('Clock'),
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const PageStorageKey('home')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(
      tester.getTopLeft(find.text('Notes')).dy,
      lessThan(tester.getTopLeft(find.text('Clock')).dy),
      reason: 'the rest of the tab follows the favourites',
    );
    expect(vm.favouritesOn(dashboard().tabs.first), isEmpty);

    await tester.tap(find.widgetWithText(Tab, 'Server'));
    await tester.pumpAndSettle();
    expect(section, findsNothing, reason: 'only on the home tab');
  });

  testWidgets('has no section without favourites', (tester) async {
    await pump(tester, dashboard());
    expect(find.byKey(const ValueKey('dashboard.favourites')), findsNothing);
  });

  testWidgets('marks a favourite with the star in the edit mode', (
    tester,
  ) async {
    final vm = await pump(tester, dashboard());
    await tester.tap(find.byKey(const ValueKey('dashboard.edit')));
    await tester.pumpAndSettle();

    final star = find.byKey(const ValueKey('editTab.favourite.clock'));
    expect(find.byTooltip(l10nEn.editTabFavourite('Clock')), findsOneWidget);
    await tester.tap(star);
    await tester.pumpAndSettle();

    expect(vm.arranging!.items.first.favourite, isTrue);
    expect(find.byTooltip(l10nEn.editTabUnfavourite('Clock')), findsOneWidget);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  });
}
