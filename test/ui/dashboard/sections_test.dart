import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/data/repositories/sections/section_state_repository.dart';
import 'package:waylight_mobile/data/services/api/dashboard_api.dart';
import 'package:waylight_mobile/domain/models/attention.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/ui/core/widget_registry.dart';
import 'package:waylight_mobile/ui/dashboard/view_models/dashboard_view_model.dart';
import 'package:waylight_mobile/ui/dashboard/widgets/dashboard_screen.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../testing/fakes/fake_attention_repository.dart';
import '../../testing/fakes/fake_dashboard_repository.dart';
import '../../testing/fakes/fake_server_repository.dart';
import '../../testing/fakes/in_memory_key_value_store.dart';
import '../../testing/pump_app.dart';

/// Collapsible sections per tab (#334).
void main() {
  final json = {
    'tabs': [
      {
        'id': 't',
        'name': 'Home',
        'position': 0,
        'mine': true,
        'widgets': [
          {'id': 'n', 'kind': 'notes', 'x': 0, 'y': 0},
          {'id': 'd', 'kind': 'docker', 'x': 0, 'y': 1},
          {'id': 's', 'kind': 'system', 'x': 0, 'y': 2},
          {'id': 'c', 'kind': 'clock', 'x': 0, 'y': 3},
        ],
      },
      {
        'id': 'u',
        'name': 'Servers',
        'position': 1,
        'mine': true,
        'widgets': [
          {'id': 'd2', 'kind': 'docker', 'x': 0, 'y': 0},
          {'id': 's2', 'kind': 'system', 'x': 0, 'y': 1},
        ],
      },
    ],
  };

  const registry = WidgetRegistry(
    {},
    categories: {
      'docker': WidgetCategory.server,
      'system': WidgetCategory.server,
    },
  );

  late SectionStateRepository sections;
  late FakeAttentionRepository attention;

  DashboardViewModel viewModel() {
    final viewModel = DashboardViewModel(
      serverRepository: FakeServerRepository(current: testServer()),
      dashboardRepository: FakeDashboardRepository()
        ..result = Result.ok(parseDashboard(json)!),
      attentionRepository: attention,
      sectionStateRepository: sections,
    );
    addTearDown(viewModel.dispose);
    return viewModel;
  }

  setUp(() {
    sections = SectionStateRepository(store: InMemoryKeyValueStore());
    attention = FakeAttentionRepository(
      items: const [
        AttentionItem(
          id: 'widget:s',
          kind: AttentionKind.connection,
          integration: 'system',
          widgetId: 's',
          tabId: 't',
          title: 'system',
          message: '',
          action: AttentionAction.check,
        ),
      ],
    );
  });

  test('the view model collapses per tab and knows attention', () async {
    final model = viewModel();
    await model.load.execute();
    final widgets = (model.load.result! as Ok<Dashboard>).value.tabs.first;

    model.toggleSection('t', 'server');
    await Future<void>.delayed(Duration.zero);

    expect(model.isSectionCollapsed('t', 'server'), isTrue);
    expect(model.isSectionCollapsed('u', 'server'), isFalse);
    expect(sections.isCollapsed(testServer(), 't', 'server'), isTrue);
    expect(widgets.widgets.where(model.needsAttention).map((w) => w.id), ['s']);

    model.toggleSection('t', 'server');
    expect(model.isSectionCollapsed('t', 'server'), isFalse);
  });

  Future<DashboardViewModel> pump(WidgetTester tester) async {
    final model = viewModel();
    await tester.pumpScreen(
      DashboardScreen(viewModel: model, registry: registry),
    );
    await tester.pumpAndSettle();
    return model;
  }

  Finder card(String title) => find.text(title);

  testWidgets('groups widgets under headers in the order they appear', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Everyday'), findsOneWidget);
    expect(find.text('Server'), findsOneWidget);
    final everyday = tester.getTopLeft(find.text('Everyday')).dy;
    final server = tester.getTopLeft(find.text('Server')).dy;
    expect(everyday, lessThan(server));
    // The clock follows the notes in the everyday section, above the
    // server section, although it comes last in the phone order.
    expect(tester.getTopLeft(card('Clock')).dy, lessThan(server));
  });

  testWidgets('collapses a section, with the count and the attention dot', (
    tester,
  ) async {
    final model = await pump(tester);
    expect(find.text('Docker'), findsOneWidget);
    expect(find.byKey(const ValueKey('section.attention')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('section.server')));
    await tester.pumpAndSettle();

    expect(find.text('Docker'), findsNothing);
    expect(find.text('2'), findsOneWidget);
    expect(find.byKey(const ValueKey('section.attention')), findsOneWidget);
    expect(model.isSectionCollapsed('t', 'server'), isTrue);

    await tester.tap(find.byKey(const ValueKey('section.server')));
    await tester.pumpAndSettle();
    expect(find.text('Docker'), findsOneWidget);
  });

  testWidgets('headers are buttons with their expanded state', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester);

    expect(
      tester.getSemantics(find.byKey(const ValueKey('section.server'))),
      matchesSemantics(
        label: 'Server, 2 widgets',
        isButton: true,
        hasExpandedState: true,
        isExpanded: true,
        hasTapAction: true,
        onTapHint: 'collapse',
      ),
    );

    await tester.tap(find.byKey(const ValueKey('section.server')));
    await tester.pumpAndSettle();

    expect(
      tester.getSemantics(find.byKey(const ValueKey('section.server'))),
      matchesSemantics(
        label: 'Server, 2 widgets, needs attention',
        isButton: true,
        hasExpandedState: true,
        hasTapAction: true,
        onTapHint: 'expand',
      ),
    );
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('a tab with a single section shows no header', (tester) async {
    await pump(tester);

    await tester.tap(find.widgetWithText(Tab, 'Servers'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('section.server')), findsNothing);
    expect(find.text('Docker'), findsOneWidget);
  });
}
