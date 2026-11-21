import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:waylight_mobile/data/repositories/compact/compact_state_repository.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/domain/models/compact_state.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/ui/core/widget_size_scope.dart';
import 'package:waylight_mobile/ui/core/widgets/compact_state_view.dart';
import 'package:waylight_mobile/ui/core/widgets/rows.dart';
import 'package:waylight_mobile/ui/widgets/common/compact_state_widget.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../../testing/fakes/fake_compact_state_repository.dart';
import '../../../testing/fakes/fake_server_repository.dart';
import '../../../testing/pump_app.dart';

void main() {
  const widget = WidgetPlacement(id: 'w1', kind: 'todos');
  late FakeCompactStateRepository compact;

  setUp(() {
    compact = FakeCompactStateRepository(kinds: {'todos'})
      ..result = const Result.ok(
        CompactState(
          title: CompactText(text: '3 open · 1 overdue'),
          detail: CompactText(text: 'Next: Tax return'),
          level: CompactLevel.attention,
          count: 3,
        ),
      );
  });

  Future<void> pump(WidgetTester tester, WidgetSize? size) async {
    Widget child = Builder(
      builder: (context) => CompactStateWidget.orFull(
        context,
        widget,
        title: 'To-dos',
        full: () => const Text('full view'),
      ),
    );
    if (size != null) child = WidgetSizeScope(size: size, child: child);
    await tester.pumpScreen(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ServerRepository>.value(
            value: FakeServerRepository(current: testServer()),
          ),
          Provider<CompactStateRepository?>.value(value: compact),
        ],
        child: child,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('small tiles show the compact state of the server', (
    tester,
  ) async {
    await pump(tester, WidgetSize.small);

    expect(compact.asked, ['todos']);
    expect(find.text('To-dos'), findsOneWidget);
    expect(find.text('3 open · 1 overdue'), findsOneWidget);
    expect(find.text('Next: Tax return'), findsOneWidget);
    expect(find.text('full view'), findsNothing);
  });

  testWidgets('strips show the title line only', (tester) async {
    await pump(tester, WidgetSize.strip);

    expect(find.text('3 open · 1 overdue'), findsOneWidget);
    expect(find.text('Next: Tax return'), findsNothing);
  });

  testWidgets('larger tiles and kinds without one keep the full view', (
    tester,
  ) async {
    await pump(tester, WidgetSize.medium);
    expect(find.text('full view'), findsOneWidget);

    compact = FakeCompactStateRepository();
    await pump(tester, WidgetSize.small);
    expect(find.text('full view'), findsOneWidget);
    expect(compact.asked, isEmpty);
  });

  test('colours only attention and problem', () {
    expect(CompactStateView.toneOf(CompactLevel.none), isNull);
    expect(CompactStateView.toneOf(CompactLevel.ok), isNull);
    expect(CompactStateView.toneOf(CompactLevel.attention), Tone.warning);
    expect(CompactStateView.toneOf(CompactLevel.problem), Tone.critical);
  });
}
