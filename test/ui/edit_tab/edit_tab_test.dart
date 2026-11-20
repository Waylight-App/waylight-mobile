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

    test('moves, hides and stores', () async {
      final viewModel = await loaded('t');

      viewModel
        ..move(2, 0)
        ..toggleHidden(2);
      await viewModel.save.execute();

      expect(dashboards.saved['t']!.map((i) => (i.widget.id, i.hidden)), [
        ('c', false),
        ('b', false),
        ('a', false),
      ]);
    });

    test('sets and removes sizes and stores them', () async {
      final viewModel = await loaded('t');
      var notified = 0;
      viewModel
        ..addListener(() => notified++)
        ..setSize(0, WidgetSize.small)
        ..setSize(0, WidgetSize.small)
        ..setSize(1, WidgetSize.large)
        ..setSize(1, null);
      await viewModel.save.execute();

      expect(dashboards.saved['t']!.map((i) => i.size), [
        WidgetSize.small,
        null,
        null,
      ]);
      expect(notified, 3, reason: 'setting the same size changes nothing');
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

  testWidgets('moves with buttons and goes back after saving', (tester) async {
    final dashboards = FakeDashboardRepository()
      ..result = Result.ok(parseDashboard(json)!);
    bool? popped;
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
            viewModel: EditTabViewModel(
              tabId: 't',
              serverRepository: FakeServerRepository(current: testServer()),
              dashboardRepository: dashboards,
            ),
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip(l10nEn.editTabDown).first);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('editTab.save')));
    await tester.pumpAndSettle();

    expect(dashboards.saved['t']!.map((i) => i.widget.id), ['a', 'b', 'c']);
    expect(popped, isTrue);
  });

  testWidgets('chooses a size from the menu', (tester) async {
    final dashboards = FakeDashboardRepository()
      ..result = Result.ok(parseDashboard(json)!);
    final viewModel = EditTabViewModel(
      tabId: 't',
      serverRepository: FakeServerRepository(current: testServer()),
      dashboardRepository: dashboards,
    );
    await tester.pumpScreen(EditTabScreen(viewModel: viewModel));
    await tester.pumpAndSettle();
    expect(
      find.text(l10nEn.editTabSize(l10nEn.widgetSizeFull)),
      findsNWidgets(3),
    );

    await tester.tap(find.byKey(const ValueKey('editTab.size.b')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10nEn.widgetSizeSmall).last);
    await tester.pumpAndSettle();

    expect(viewModel.items.first.size, WidgetSize.small);
    expect(
      find.text(l10nEn.editTabSize(l10nEn.widgetSizeSmall)),
      findsOneWidget,
    );
  });
}
