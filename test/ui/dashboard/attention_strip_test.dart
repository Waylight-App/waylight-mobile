import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:waylight_mobile/domain/models/attention.dart';
import 'package:waylight_mobile/domain/models/compact_state.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/ui/core/widget_registry.dart';
import 'package:waylight_mobile/ui/dashboard/view_models/dashboard_view_model.dart';
import 'package:waylight_mobile/ui/dashboard/widgets/dashboard_screen.dart';
import 'package:waylight_mobile/ui/dashboard/widgets/widget_full_screen.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../testing/fakes/fake_attention_repository.dart';
import '../../testing/fakes/fake_compact_state_repository.dart';
import '../../testing/fakes/fake_dashboard_repository.dart';
import '../../testing/fakes/fake_server_repository.dart';
import '../../testing/pump_app.dart';

void main() {
  const tab = DashboardTab(
    id: 't1',
    name: 'Home',
    widgets: [
      WidgetPlacement(id: 'todos', kind: 'todos', title: 'To-dos'),
      WidgetPlacement(id: 'backup', kind: 'backup-status', title: 'Backups'),
      WidgetPlacement(id: 'clock', kind: 'clock', title: 'Clock'),
      WidgetPlacement(id: 'services', kind: 'services', title: 'Services'),
      WidgetPlacement(id: 'immich', kind: 'immich', title: 'Photos'),
      WidgetPlacement(id: 'habits', kind: 'habits', title: 'Habits'),
    ],
  );

  Result<CompactState> state(String text, CompactLevel level) => Result.ok(
    CompactState(
      title: CompactText(text: text),
      level: level,
    ),
  );

  late FakeCompactStateRepository compact;
  late FakeAttentionRepository attention;

  DashboardViewModel create() => DashboardViewModel(
    serverRepository: FakeServerRepository(current: testServer()),
    dashboardRepository: FakeDashboardRepository()
      ..result = const Result.ok(Dashboard(tabs: [tab], defaultTabId: 't1')),
    compactRepository: compact,
    attentionRepository: attention,
  );

  setUp(() {
    compact =
        FakeCompactStateRepository(
            kinds: {'todos', 'backup-status', 'services', 'habits'},
          )
          ..byKind['todos'] = state('1 overdue', CompactLevel.attention)
          ..byKind['backup-status'] = state('1 failed', CompactLevel.problem)
          ..byKind['services'] = state('All up', CompactLevel.ok)
          ..byKind['habits'] = state('2 due today', CompactLevel.attention);
    attention = FakeAttentionRepository(
      items: const [
        AttentionItem(
          id: 'widget:immich',
          kind: AttentionKind.connection,
          integration: 'immich',
          widgetId: 'immich',
          tabId: 't1',
          title: 'immich',
          message: 'Sign-in expired',
          action: AttentionAction.signIn,
        ),
        AttentionItem(
          id: 'widget:clock',
          kind: AttentionKind.setup,
          integration: 'clock',
          widgetId: 'clock',
          tabId: 't1',
          title: 'clock',
          message: '',
          action: AttentionAction.choose,
        ),
      ],
    );
  });

  test('lists problems first, then warnings, in layout order (#335)', () async {
    final vm = create();
    addTearDown(vm.dispose);
    await vm.load.execute();
    await pumpEventQueue();

    final entries = vm.attentionOf(tab);
    expect(
      [for (final e in entries) e.widget.id],
      ['backup', 'immich', 'todos', 'habits'],
      reason: 'healthy and not-set-up widgets stay out',
    );
    expect(entries[1].text, isNull, reason: 'a broken connection');
    expect(entries.first.level, CompactLevel.problem);
  });

  testWidgets('shows three entries and a count, and opens the widget', (
    tester,
  ) async {
    await tester.pumpScreen(
      DashboardScreen(viewModel: create(), registry: const WidgetRegistry({})),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('dashboard.attentionStrip')), findsOne);
    expect(find.text('Backups · 1 failed'), findsOneWidget);
    expect(find.text('Photos · ${l10nEn.attentionBroken}'), findsOneWidget);
    expect(find.text('To-dos · 1 overdue'), findsOneWidget);
    expect(find.textContaining('2 due today'), findsNothing);
    expect(find.text(l10nEn.attentionStripMore(1)), findsOneWidget);
    expect(find.text(l10nEn.attentionLevelProblem), findsNWidgets(2));
    expect(find.text(l10nEn.attentionLevelWarning), findsOneWidget);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

    await tester.tap(
      find.byKey(const ValueKey('dashboard.attentionStrip.backup')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(WidgetFullScreen), findsOneWidget);
  });

  testWidgets('is hidden while nothing needs attention', (tester) async {
    compact.byKind.clear();
    attention.result = const Result.ok([]);
    await tester.pumpScreen(
      DashboardScreen(viewModel: create(), registry: const WidgetRegistry({})),
      locale: const Locale('de'),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('dashboard.attentionStrip')),
      findsNothing,
    );
    expect(find.text('Clock'), findsOneWidget);
  });
}
