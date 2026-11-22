import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/data/repositories/offline/offline_repository.dart';
import 'package:waylight_mobile/data/services/api/api_client.dart';
import 'package:waylight_mobile/data/services/api/dashboard_api.dart';
import 'package:waylight_mobile/data/services/api/offline_status.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/ui/core/error_messages.dart';
import 'package:waylight_mobile/ui/core/widget_registry.dart';
import 'package:waylight_mobile/ui/dashboard/view_models/arrange_view_model.dart';
import 'package:waylight_mobile/ui/dashboard/view_models/dashboard_view_model.dart';
import 'package:waylight_mobile/ui/dashboard/widgets/dashboard_screen.dart';
import 'package:waylight_mobile/ui/dashboard/widgets/widget_card.dart';
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
          {'id': 'a', 'kind': 'clock', 'x': 0, 'y': 0, 'h': 4},
          {'id': 'b', 'kind': 'weather', 'x': 6, 'y': 0, 'h': 4},
          {'id': 'c', 'kind': 'notes', 'x': 0, 'y': 4, 'h': 3},
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
        'widgets': [
          {'id': 'd', 'kind': 'clock', 'x': 0, 'y': 0},
        ],
      },
    ],
  };

  group('API', () {
    test('reads the phone layout, hidden widgets and desktop rows', () {
      final dashboard = parseDashboard(json)!;
      final tab = dashboard.tabs.first;

      expect(tab.widgets.map((w) => w.id), ['b', 'c']);
      expect(tab.layout.map((i) => (i.widget.id, i.hidden, i.rows)), [
        ('b', false, 3),
        ('a', true, 2),
        ('c', false, 1),
      ]);
      expect(tab.desktopRows, 7);
      expect(dashboard.tabs.last.mine, isFalse);
    });

    test('stores and resets the layout', () async {
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

    test('reads the widget kinds and adds a widget below the grid', () async {
      final sent = <http.Request>[];
      final api = DashboardApi(
        ApiClient(
          client: MockClient((r) async {
            sent.add(r);
            return switch (r.method) {
              'GET' => http.Response(
                jsonEncode({
                  'modules': <Object?>[],
                  'widgetKinds': ['clock', 3, 'weather'],
                }),
                200,
              ),
              _ => http.Response(jsonEncode({'id': 'n', 'kind': 'clock'}), 201),
            };
          }),
        ),
      );

      final kinds = await api.widgetKinds(testServer());
      final added = await api.addWidget(testServer(), 't', 'clock', row: 7);

      expect((kinds as Ok<List<String>>).value, ['clock', 'weather']);
      expect((added as Ok<WidgetPlacement>).value.id, 'n');
      expect(sent.last.url.path, '/api/dashboard/tabs/t/widgets');
      expect(jsonDecode(sent.last.body), {
        'kind': 'clock',
        'x': 0,
        'y': 7,
        'w': addedWidgetColumns,
        'h': addedWidgetRows,
        'config': <String, Object?>{},
      });
    });

    test('refuses answers it does not understand', () async {
      final api = DashboardApi(
        ApiClient(client: MockClient((r) async => http.Response('[]', 200))),
      );

      final kinds = await api.widgetKinds(testServer());
      final added = await api.addWidget(testServer(), 't', 'clock', row: 0);

      expect((kinds as Error<List<String>>).error, isA<ApiException>());
      expect((added as Error<WidgetPlacement>).error, isA<ApiException>());
    });
  });

  group('view model', () {
    late FakeDashboardRepository dashboards;

    ArrangeViewModel arrange({bool connected = true}) {
      dashboards = FakeDashboardRepository();
      return ArrangeViewModel(
        tab: parseDashboard(json)!.tabs.first,
        serverRepository: FakeServerRepository(
          current: connected ? testServer() : null,
        ),
        dashboardRepository: dashboards,
      );
    }

    test('moves onto another widget and by one place', () {
      final viewModel = arrange();

      viewModel.moveOnto('c', 'b');
      expect(viewModel.visible.map((i) => i.widget.id), ['c', 'b']);

      viewModel.moveBy('c', 1);
      expect(viewModel.visible.map((i) => i.widget.id), ['b', 'c']);

      viewModel.moveBy('c', 1);
      expect(viewModel.visible.map((i) => i.widget.id), ['b', 'c']);
    });

    test('hides, shows again and knows when it changed', () {
      final viewModel = arrange();
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
      final viewModel = arrange();
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
      final viewModel = arrange()..hide('b');
      await viewModel.reset.execute();

      expect(dashboards.reset, ['t']);
      expect(viewModel.changed, isFalse);
    });

    test('lists the kinds in order', () async {
      final viewModel = arrange();
      dashboards.kinds = const Result.ok(['weather', 'clock']);
      await viewModel.kinds.execute();

      expect((viewModel.kinds.result! as Ok<List<String>>).value, [
        'clock',
        'weather',
      ]);
    });

    test('adds widgets below each other in the chosen size', () async {
      final viewModel = arrange();
      await viewModel.add.execute((kind: 'clock', size: WidgetSize.small));
      await viewModel.add.execute((kind: 'todos', size: WidgetSize.large));

      expect(dashboards.added, [
        ('t', 'clock', 7),
        ('t', 'todos', 7 + addedWidgetRows),
      ]);
      expect(viewModel.visible.map((i) => (i.widget.id, i.size)), [
        ('b', null),
        ('c', null),
        ('new-clock', WidgetSize.small),
        ('new-todos', WidgetSize.large),
      ]);
      expect(viewModel.changed, isTrue);
    });

    test('needs a server', () async {
      final viewModel = arrange(connected: false);
      await viewModel.save.execute();
      await viewModel.reset.execute();
      await viewModel.kinds.execute();
      await viewModel.add.execute((kind: 'clock', size: WidgetSize.small));

      for (final command in [
        viewModel.save,
        viewModel.reset,
        viewModel.kinds,
        viewModel.add,
      ]) {
        expect(command.result, isA<Error<Object?>>());
      }
    });
  });

  group('edit mode on the dashboard (#209)', () {
    late FakeDashboardRepository dashboards;
    late DashboardViewModel viewModel;
    TabTagWriter? writeTabTag;

    setUp(() => writeTabTag = null);

    Future<void> pumpDashboard(
      WidgetTester tester, {
      bool reduceMotion = true,
    }) async {
      dashboards = FakeDashboardRepository()
        ..result = Result.ok(parseDashboard(json)!);
      viewModel = DashboardViewModel(
        serverRepository: FakeServerRepository(current: testServer()),
        dashboardRepository: dashboards,
        offlineRepository: OfflineRepository(OfflineStatus()),
      );
      addTearDown(viewModel.dispose);
      await tester.pumpScreen(
        Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(disableAnimations: reduceMotion),
            child: DashboardScreen(
              viewModel: viewModel,
              registry: const WidgetRegistry(
                {},
                sizes: {
                  'clock': WidgetSizes([
                    WidgetSize.small,
                    WidgetSize.medium,
                    WidgetSize.strip,
                  ], defaultSize: WidgetSize.small),
                },
              ),
              writeTabTag: writeTabTag,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> edit(WidgetTester tester, {bool reduceMotion = true}) async {
      await pumpDashboard(tester, reduceMotion: reduceMotion);
      await tester.tap(find.byKey(const ValueKey('dashboard.edit')));
      if (reduceMotion) {
        await tester.pumpAndSettle();
      } else {
        await tester.pump(const Duration(seconds: 1));
      }
    }

    List<String> order() =>
        viewModel.arranging!.visible.map((i) => i.widget.id).toList();

    testWidgets('starts when a widget is held', (tester) async {
      await pumpDashboard(tester);

      await tester.longPress(find.byType(WidgetCard).first);
      await tester.pumpAndSettle();

      expect(viewModel.arranging?.tabId, 't');
      expect(find.byKey(const ValueKey('arrange')), findsOneWidget);
      expect(find.byKey(const ValueKey('editTab.add')), findsOneWidget);
      expect(find.byType(TabBar), findsNothing);
    });

    testWidgets('cannot arrange tabs shared with the account', (tester) async {
      await pumpDashboard(tester);
      await tester.tap(find.widgetWithText(Tab, 'Team'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('dashboard.edit')), findsNothing);

      await tester.longPress(find.byType(WidgetCard).last);
      await tester.pumpAndSettle();
      expect(viewModel.arranging, isNull);
    });

    testWidgets('shows the grid and the hidden widgets below', (tester) async {
      await edit(tester);

      expect(find.byKey(const ValueKey('grid.b')), findsOneWidget);
      expect(find.byKey(const ValueKey('grid.c')), findsOneWidget);
      expect(find.byKey(const ValueKey('grid.a')), findsNothing);
      expect(find.byKey(const ValueKey('editTab.show.a')), findsOneWidget);
      expect(find.text(l10nEn.editTabHint), findsOneWidget);
      expect(find.text('Home'), findsOneWidget, reason: 'the tab name');
    });

    testWidgets('hides with − and shows again', (tester) async {
      await edit(tester);

      await tester.tap(find.byKey(const ValueKey('editTab.hide.b')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('editTab.show.a')));
      await tester.pumpAndSettle();

      expect(order(), ['a', 'c']);
      expect(find.byKey(const ValueKey('editTab.show.b')), findsOneWidget);
    });

    testWidgets('changes the size in the sheet with a preview', (tester) async {
      await edit(tester);

      await tester.tap(find.byKey(const ValueKey('editTab.size.b')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('editTab.sizeChoice.small')));
      await tester.pumpAndSettle();

      expect(viewModel.arranging!.items.first.size, WidgetSize.small);

      await tester.tap(find.byKey(const ValueKey('editTab.sizeDone')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('editTab.sizeDone')), findsNothing);
    });

    testWidgets('moves and hides from the sheet', (tester) async {
      await edit(tester);

      await tester.tap(find.byKey(const ValueKey('editTab.size.c')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('editTab.earlier')));
      await tester.pumpAndSettle();
      expect(order(), ['c', 'b']);

      await tester.tap(find.byKey(const ValueKey('editTab.later')));
      await tester.pumpAndSettle();
      expect(order(), ['b', 'c']);

      await tester.tap(find.text(l10nEn.editTabHideOnPhones));
      await tester.pumpAndSettle();
      expect(order(), ['b']);
    });

    testWidgets('drags a widget onto another', (tester) async {
      await edit(tester);

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

    testWidgets('saves with Done and shows the new layout', (tester) async {
      await edit(tester);
      final loads = dashboards.calls;

      await tester.tap(find.byKey(const ValueKey('editTab.hide.c')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('editTab.save')));
      await tester.pumpAndSettle();

      expect(dashboards.saved['t']!.map((i) => (i.widget.id, i.hidden)), [
        ('b', false),
        ('a', true),
        ('c', true),
      ]);
      expect(viewModel.arranging, isNull);
      expect(dashboards.calls, loads + 1, reason: 'reloaded');
      expect(find.byType(TabBar), findsOneWidget);
    });

    testWidgets('leaves with Done without saving when nothing changed', (
      tester,
    ) async {
      await edit(tester);

      await tester.tap(find.byKey(const ValueKey('editTab.save')));
      await tester.pumpAndSettle();

      expect(viewModel.arranging, isNull);
      expect(dashboards.saved, isEmpty);
    });

    testWidgets('resets from the menu', (tester) async {
      await edit(tester);

      await tester.tap(find.byKey(const ValueKey('editTab.more')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('editTab.reset')));
      await tester.pumpAndSettle();

      expect(dashboards.reset, ['t']);
      expect(viewModel.arranging, isNull);
    });

    testWidgets('writes an NFC tag for the tab from the menu (#260)', (
      tester,
    ) async {
      final written = <(String, String)>[];
      writeTabTag = (context, id, name) async => written.add((id, name));
      await edit(tester);

      await tester.tap(find.byKey(const ValueKey('editTab.more')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('editTab.tag')));
      await tester.pumpAndSettle();

      expect(written.single.$1, 't');
    });

    testWidgets('offers no tag where the phone cannot write one', (
      tester,
    ) async {
      await edit(tester);
      await tester.tap(find.byKey(const ValueKey('editTab.more')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('editTab.tag')), findsNothing);
    });

    testWidgets('asks before leaving with changes', (tester) async {
      await edit(tester);

      await tester.tap(find.byKey(const ValueKey('editTab.hide.c')));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text(l10nEn.editTabDiscardTitle), findsOneWidget);

      await tester.tap(find.text(l10nEn.editTabKeep));
      await tester.pumpAndSettle();
      expect(viewModel.arranging, isNotNull);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('editTab.discard')));
      await tester.pumpAndSettle();

      expect(viewModel.arranging, isNull);
      expect(dashboards.saved, isEmpty);
    });

    testWidgets('leaves on back without asking when nothing changed', (
      tester,
    ) async {
      await edit(tester);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text(l10nEn.editTabDiscardTitle), findsNothing);
      expect(viewModel.arranging, isNull);
    });

    testWidgets('wiggles unless animations are reduced', (tester) async {
      await edit(tester, reduceMotion: false);
      expect(tester.hasRunningAnimations, isTrue);

      await tester.tap(find.byKey(const ValueKey('editTab.save')));
      await tester.pump(const Duration(seconds: 1));

      await edit(tester);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('meets the accessibility guidelines', (tester) async {
      final handle = tester.ensureSemantics();
      await edit(tester);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    group('gallery (#210)', () {
      Future<void> openGallery(WidgetTester tester) async {
        await edit(tester);
        await tester.tap(find.byKey(const ValueKey('editTab.add')));
        await tester.pumpAndSettle();
      }

      testWidgets('lists the kinds and searches them', (tester) async {
        await openGallery(tester);

        expect(find.text(l10nEn.galleryTitle('Home')), findsOneWidget);
        for (final kind in ['clock', 'todos', 'weather']) {
          expect(find.byKey(ValueKey('gallery.$kind')), findsOneWidget);
        }

        await tester.enterText(
          find.byKey(const ValueKey('gallery.search')),
          'wea',
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('gallery.clock')), findsNothing);
        expect(find.byKey(const ValueKey('gallery.weather')), findsOneWidget);

        await tester.enterText(
          find.byKey(const ValueKey('gallery.search')),
          'nothing like it',
        );
        await tester.pumpAndSettle();
        expect(find.text(l10nEn.galleryEmpty), findsOneWidget);
      });

      testWidgets('adds a widget in the size of the preview tapped', (
        tester,
      ) async {
        await openGallery(tester);
        for (final size in WidgetSize.values) {
          expect(
            find.byKey(ValueKey('gallery.add.todos.${size.name}')),
            findsOneWidget,
          );
        }

        await tester.tap(
          find.byKey(const ValueKey('gallery.add.todos.medium')),
        );
        await tester.pumpAndSettle();

        expect(dashboards.added, [('t', 'todos', 7)]);
        expect(find.text(l10nEn.galleryAdded), findsOneWidget);
        expect(order(), ['b', 'c', 'new-todos']);

        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('grid.new-todos')), findsOneWidget);
        expect(
          tester.getSize(find.byKey(const ValueKey('grid.new-todos'))).width,
          greaterThan(
            tester.getSize(find.byKey(const ValueKey('grid.b'))).width / 2,
          ),
          reason: 'medium takes the full width',
        );
      });

      testWidgets('offers only the sizes a kind declares', (tester) async {
        await openGallery(tester);

        expect(
          find.byKey(const ValueKey('gallery.add.clock.strip')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('gallery.add.clock.large')),
          findsNothing,
        );
      });

      testWidgets('describes each preview for screen readers', (tester) async {
        final handle = tester.ensureSemantics();
        await openGallery(tester);

        expect(
          find.bySemanticsLabel(
            l10nEn.galleryAddSized('Todos', l10nEn.widgetSizeStrip),
          ),
          findsOneWidget,
        );
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        handle.dispose();
      });

      testWidgets('says when adding fails', (tester) async {
        await openGallery(tester);
        dashboards.addError = const ApiException(ApiFailure.forbidden);

        await tester.tap(find.byKey(const ValueKey('gallery.add.clock.small')));
        await tester.pumpAndSettle();

        expect(
          find.text(
            l10nEn.errorMessage(const ApiException(ApiFailure.forbidden)),
          ),
          findsOneWidget,
        );
        expect(find.text(l10nEn.galleryAdded), findsNothing);
        expect(order(), ['b', 'c']);
      });

      testWidgets('says when the kinds cannot be loaded', (tester) async {
        await pumpDashboard(tester);
        dashboards.kinds = const Result.error(
          ApiException(ApiFailure.unreachable),
        );
        await tester.tap(find.byKey(const ValueKey('dashboard.edit')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('editTab.add')));
        await tester.pumpAndSettle();

        expect(
          find.text(
            l10nEn.errorMessage(const ApiException(ApiFailure.unreachable)),
          ),
          findsOneWidget,
        );
      });
    });
  });
}
