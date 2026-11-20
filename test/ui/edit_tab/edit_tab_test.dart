import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/data/services/api/api_client.dart';
import 'package:waylight_mobile/data/services/api/dashboard_api.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/widget_registry.dart';
import 'package:waylight_mobile/ui/edit_tab/view_models/edit_tab_view_model.dart';
import 'package:waylight_mobile/ui/edit_tab/widgets/edit_tab_screen.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../testing/fakes/fake_dashboard_repository.dart';
import '../../testing/fakes/fake_server_repository.dart';
import '../../testing/pump_app.dart';

void main() {
  final json = {
    'tabs': [
      {
        'id': 't',
        'name': 'Home',
        'position': 0,
        'mine': true,
        'widgets': [
          {'id': 'a', 'kind': 'clock', 'x': 0, 'y': 0},
          {'id': 'b', 'kind': 'weather', 'x': 6, 'y': 0},
          {'id': 'c', 'kind': 'notes', 'x': 0, 'y': 4},
        ],
        'mobile': [
          {'id': 'b', 'hidden': false, 'rows': 3},
          {'id': 'a', 'hidden': true, 'rows': 2},
          {'id': 'c', 'hidden': false, 'rows': 1},
        ],
      },
      {
        'id': 'team',
        'name': 'Team',
        'position': 1,
        'mine': false,
        'widgets': <Object?>[],
      },
    ],
  };

  test('reads the whole phone layout with hidden widgets and heights', () {
    final dashboard = parseDashboard(json)!;
    final tab = dashboard.tabs.first;

    expect(tab.widgets.map((w) => w.id), ['b', 'c']);
    expect(tab.layout.map((i) => (i.widget.id, i.hidden, i.rows)), [
      ('b', false, 3),
      ('a', true, 2),
      ('c', false, 1),
    ]);
    expect(dashboard.tabs.last.mine, isFalse);
  });

  test('stores and resets the layout over the API', () async {
    final sent = <http.Request>[];
    final api = DashboardApi(
      ApiClient(
        client: MockClient((r) async {
          sent.add(r);
          return http.Response('{}', 200);
        }),
      ),
    );
    final layout = parseDashboard(json)!.tabs.first.layout;

    await api.saveLayout(testServer(), 't', layout);
    await api.resetLayout(testServer(), 't');

    expect(sent.first.method, 'PUT');
    expect(sent.first.url.path, '/api/dashboard/tabs/t/mobile-layout');
    expect(jsonDecode(sent.first.body), {
      'items': [
        {'id': 'b', 'hidden': false, 'rows': 3},
        {'id': 'a', 'hidden': true, 'rows': 2},
        {'id': 'c', 'hidden': false, 'rows': 1},
      ],
    });
    expect(sent.last.method, 'DELETE');
  });

  group('view model', () {
    late FakeDashboardRepository dashboards;

    Future<EditTabViewModel> loaded(String tab) async {
      dashboards = FakeDashboardRepository()
        ..result = Result.ok(parseDashboard(json)!);
      final viewModel = EditTabViewModel(
        tabId: tab,
        serverRepository: FakeServerRepository(current: testServer()),
        dashboardRepository: dashboards,
      );
      while (viewModel.load.result == null) {
        await Future<void>.delayed(Duration.zero);
      }
      return viewModel;
    }

    test('moves onto another widget and by one place', () async {
      final viewModel = await loaded('t');

      viewModel.moveOnto('c', 'b');
      expect(viewModel.visible.map((i) => i.widget.id), ['c', 'b']);

      viewModel.moveBy('c', 1);
      expect(viewModel.visible.map((i) => i.widget.id), ['b', 'c']);

      viewModel.moveBy('c', 1);
      expect(viewModel.visible.map((i) => i.widget.id), ['b', 'c']);
    });

    test('hides, shows again and knows when it changed', () async {
      final viewModel = await loaded('t');
      expect(viewModel.changed, isFalse);
      expect(viewModel.hidden.map((i) => i.widget.id), ['a']);

      viewModel
        ..hide('b')
        ..showAgain('a');

      expect(viewModel.changed, isTrue);
      expect(viewModel.visible.map((i) => i.widget.id), ['a', 'c']);
      expect(viewModel.hidden.map((i) => i.widget.id), ['b']);
    });

    test('sets and removes sizes and stores them', () async {
      final viewModel = await loaded('t');
      var notified = 0;
      viewModel
        ..addListener(() => notified++)
        ..setSize('b', WidgetSize.small)
        ..setSize('b', WidgetSize.small)
        ..setSize('c', WidgetSize.large)
        ..setSize('c', null);
      await viewModel.save.execute();

      expect(dashboards.saved['t']!.map((i) => (i.widget.id, i.size)), [
        ('b', WidgetSize.small),
        ('a', null),
        ('c', null),
      ]);
      expect(notified, 3, reason: 'setting the same size changes nothing');
      expect(viewModel.changed, isFalse, reason: 'saved');
    });

    test('resets to the desktop grid', () async {
      final viewModel = await loaded('t');
      await viewModel.reset.execute();
      expect(dashboards.reset, ['t']);
    });

    test('refuses team tabs', () async {
      final viewModel = await loaded('team');
      expect(
        (viewModel.load.result! as Error<void>).error,
        isA<TabNotEditable>(),
      );
    });
  });

  group('edit mode (#209)', () {
    late FakeDashboardRepository dashboards;
    late EditTabViewModel viewModel;
    bool? popped;

    Future<void> pumpEditor(
      WidgetTester tester, {
      bool reduceMotion = true,
    }) async {
      dashboards = FakeDashboardRepository()
        ..result = Result.ok(parseDashboard(json)!);
      popped = null;
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, _) => TextButton(
              onPressed: () async => popped = await context.push<bool>('/edit'),
              child: const Text('open'),
            ),
          ),
          GoRoute(
            path: '/edit',
            builder: (_, _) => EditTabScreen(
              viewModel: viewModel = EditTabViewModel(
                tabId: 't',
                serverRepository: FakeServerRepository(current: testServer()),
                dashboardRepository: dashboards,
              ),
              registry: const WidgetRegistry({}),
            ),
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(disableAnimations: reduceMotion),
            child: child!,
          ),
        ),
      );
      await tester.tap(find.text('open'));
      if (reduceMotion) {
        await tester.pumpAndSettle();
      } else {
        await tester.pump(const Duration(seconds: 1));
      }
    }

    List<String> order() => viewModel.visible.map((i) => i.widget.id).toList();

    testWidgets('shows the grid and the hidden widgets below', (tester) async {
      await pumpEditor(tester);

      expect(find.byKey(const ValueKey('grid.b')), findsOneWidget);
      expect(find.byKey(const ValueKey('grid.c')), findsOneWidget);
      expect(find.byKey(const ValueKey('grid.a')), findsNothing);
      expect(find.byKey(const ValueKey('editTab.show.a')), findsOneWidget);
      expect(find.text(l10nEn.editTabHint), findsOneWidget);
    });

    testWidgets('hides with − and shows again', (tester) async {
      await pumpEditor(tester);

      await tester.tap(find.byKey(const ValueKey('editTab.hide.b')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('editTab.show.a')));
      await tester.pumpAndSettle();

      expect(order(), ['a', 'c']);
      expect(find.byKey(const ValueKey('editTab.show.b')), findsOneWidget);
    });

    testWidgets('changes the size in the sheet with a preview', (tester) async {
      await pumpEditor(tester);

      await tester.tap(find.byKey(const ValueKey('editTab.size.b')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('editTab.sizeChoice.small')));
      await tester.pumpAndSettle();

      expect(viewModel.items.first.size, WidgetSize.small);

      await tester.tap(find.byKey(const ValueKey('editTab.sizeDone')));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('editTab.size.b')),
          matching: find.text(l10nEn.widgetSizeSmall),
        ),
        findsOneWidget,
      );
    });

    testWidgets('moves without dragging from the sheet', (tester) async {
      await pumpEditor(tester);

      await tester.tap(find.byKey(const ValueKey('editTab.size.c')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('editTab.earlier')));
      await tester.pumpAndSettle();

      expect(order(), ['c', 'b']);
    });

    testWidgets('drags a widget onto another', (tester) async {
      await pumpEditor(tester);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('grid.c'))),
      );
      await tester.pump(const Duration(milliseconds: 700));
      await gesture.moveTo(
        tester.getCenter(find.byKey(const ValueKey('grid.b'))),
      );
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(order(), ['c', 'b']);
    });

    testWidgets('saves with Done and goes back', (tester) async {
      await pumpEditor(tester);

      await tester.tap(find.byKey(const ValueKey('editTab.hide.c')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('editTab.save')));
      await tester.pumpAndSettle();

      expect(dashboards.saved['t']!.map((i) => (i.widget.id, i.hidden)), [
        ('b', false),
        ('a', true),
        ('c', true),
      ]);
      expect(popped, isTrue);
    });

    testWidgets('asks before leaving with changes', (tester) async {
      await pumpEditor(tester);

      await tester.tap(find.byKey(const ValueKey('editTab.hide.c')));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text(l10nEn.editTabDiscardTitle), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('editTab.discard')));
      await tester.pumpAndSettle();

      expect(popped, isFalse);
      expect(dashboards.saved, isEmpty);
    });

    testWidgets('leaves without asking when nothing changed', (tester) async {
      await pumpEditor(tester);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text(l10nEn.editTabDiscardTitle), findsNothing);
      expect(find.text('open'), findsOneWidget);
    });

    testWidgets('wiggles unless animations are reduced', (tester) async {
      await pumpEditor(tester, reduceMotion: false);
      expect(tester.hasRunningAnimations, isTrue);

      await pumpEditor(tester);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('meets the accessibility guidelines', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpEditor(tester);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  });
}
