import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';
import 'package:waylight_mobile/data/repositories/appearance/theme_repository.dart';
import 'package:waylight_mobile/data/services/api/api_client.dart';
import 'package:waylight_mobile/data/services/api/module_api.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/ui/core/widget_registry.dart';
import 'package:waylight_mobile/ui/core/widget_size_scope.dart';
import 'package:waylight_mobile/ui/dashboard/view_models/dashboard_view_model.dart';
import 'package:waylight_mobile/ui/dashboard/widgets/dashboard_screen.dart';
import 'package:waylight_mobile/ui/dashboard/widgets/widget_detail_sheet.dart';
import 'package:waylight_mobile/ui/dashboard/widgets/widget_grid.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../testing/fakes/fake_compact_state_repository.dart';
import '../../testing/fakes/fake_dashboard_repository.dart';
import '../../testing/fakes/fake_server_repository.dart';
import '../../testing/fakes/in_memory_key_value_store.dart';
import '../../testing/pump_app.dart';

/// The simple view of the accessibility options (#291).
void main() {
  late WidgetSize? seenCompact;
  late WidgetSize? seenFull;
  late DashboardViewModel viewModel;

  Future<void> pump(WidgetTester tester, {required bool simple}) async {
    seenCompact = null;
    seenFull = null;
    final theme = ThemeRepository(
      api: ModuleApi(
        ApiClient(
          client: MockClient(
            (_) async =>
                http.Response('{"customCss":"","simpleView":$simple}', 200),
          ),
        ),
      ),
      store: InMemoryKeyValueStore(),
    );
    await theme.refresh(testServer());
    final dashboards = FakeDashboardRepository()
      ..result = const Result.ok(
        Dashboard(
          tabs: [
            DashboardTab(
              id: 't',
              name: 'Home',
              widgets: [
                WidgetPlacement(id: 'a', kind: 'todos'),
                WidgetPlacement(id: 'b', kind: 'notes'),
              ],
              sizes: {'a': WidgetSize.large, 'b': WidgetSize.large},
            ),
          ],
        ),
      );
    viewModel = DashboardViewModel(
      serverRepository: FakeServerRepository(current: testServer()),
      dashboardRepository: dashboards,
      themeRepository: theme,
      compactRepository: FakeCompactStateRepository(kinds: {'todos'}),
    );
    addTearDown(viewModel.dispose);
    await tester.pumpScreen(
      DashboardScreen(
        viewModel: viewModel,
        registry: WidgetRegistry({
          'todos': (context, widget) {
            seenCompact = WidgetSizeScope.maybeOf(context);
            return const Text('todos view');
          },
          'notes': (context, widget) {
            seenFull = WidgetSizeScope.maybeOf(context);
            return const Text('notes view');
          },
        }),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('is off by default: a grid and the edit button', (tester) async {
    await pump(tester, simple: false);

    expect(find.byType(WidgetGrid), findsOneWidget);
    expect(find.byKey(const ValueKey('dashboard.edit')), findsOneWidget);
  });

  testWidgets('shows one column without edit controls', (tester) async {
    await pump(tester, simple: true);

    expect(find.byType(WidgetGrid), findsNothing);
    expect(find.byKey(const ValueKey('dashboard.edit')), findsNothing);
    expect(find.text('todos view'), findsOneWidget);
    expect(find.text('notes view'), findsOneWidget);

    await tester.longPress(find.text('notes view'));
    await tester.pump(const Duration(seconds: 1));
    expect(viewModel.arranging, isNull);
  });

  testWidgets('prefers the compact view and opens the rest in a sheet', (
    tester,
  ) async {
    await pump(tester, simple: true);

    expect(seenCompact, WidgetSize.strip);
    expect(seenFull, isNull, reason: 'widgets without one show in full');

    await tester.tap(find.text('todos view'));
    await tester.pumpAndSettle();
    expect(find.byType(WidgetDetailSheet), findsOneWidget);
  });

  testWidgets('works with a screen reader at the largest system font', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final handle = tester.ensureSemantics();
    await pump(tester, simple: true);

    expect(tester.takeException(), isNull);
    // The compact widget is one button, which a screen reader opens with a
    // double tap.
    expect(
      tester.getSemantics(find.text('todos view')),
      isSemantics(isButton: true, hasTapAction: true),
    );
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });
}
