import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/ui/core/widget_registry.dart';
import 'package:waylight_mobile/ui/dashboard/widgets/arrange_view.dart';
import 'package:waylight_mobile/ui/widgets/registry.dart';

import '../../../testing/pump_app.dart';

/// Gallery previews from example data (#251). The previews are pumped
/// without any repository or server, so a preview that tried to load data
/// would fail here.
void main() {
  // What each preview shows in a small tile and in a large one.
  final expected = <String, ({String compact, String full})>{
    'weather': (
      compact: l10nEn.weatherDegrees(14),
      full: l10nEn.weatherFeelsLike(12),
    ),
    'todos': (compact: l10nEn.todosCompactOpen(4), full: 'Water the plants'),
    'transit': (compact: '4 Central Station', full: 'University'),
    'focus': (compact: l10nEn.focusToday(50, 2), full: l10nEn.focusStartBreak),
    'presence': (compact: l10nEn.presenceOffice, full: 'Robin'),
  };

  Future<void> pumpPreview(
    WidgetTester tester,
    String kind,
    WidgetSize size, {
    VoidCallback? onTap,
  }) async {
    final builder = nativeWidgets.previewFor(kind)!;
    await tester.pumpScreen(
      Builder(
        builder: (context) => Center(
          child: SizePreview(
            title: kind,
            size: size,
            preview: builder(context, kind, size),
            onTap: onTap ?? () {},
          ),
        ),
      ),
    );
  }

  test('the registry has previews for the first kinds', () {
    for (final kind in expected.keys) {
      expect(nativeWidgets.previewFor(kind), isNotNull, reason: kind);
    }
    expect(const WidgetRegistry({}).previewFor('weather'), isNull);
  });

  for (final MapEntry(key: kind, value: texts) in expected.entries) {
    group(kind, () {
      testWidgets('renders every size without a server', (tester) async {
        for (final size in WidgetSize.values) {
          await pumpPreview(tester, kind, size);
          expect(tester.takeException(), isNull, reason: size.name);
        }
      });

      testWidgets('shows the compact view in small tiles', (tester) async {
        await pumpPreview(tester, kind, WidgetSize.small);
        expect(find.textContaining(texts.compact), findsWidgets);
      });

      testWidgets('shows the full view in large tiles', (tester) async {
        await pumpPreview(tester, kind, WidgetSize.large);
        expect(find.textContaining(texts.full), findsWidgets);
      });
    });
  }

  testWidgets('a tap on a preview adds the widget', (tester) async {
    var taps = 0;
    await pumpPreview(tester, 'todos', WidgetSize.medium, onTap: () => taps++);
    await tester.tap(find.byType(SizePreview));
    expect(taps, 1);
  });

  testWidgets('kinds without example data keep the schematic tile', (
    tester,
  ) async {
    await tester.pumpScreen(
      SizePreview(title: 'Clock', size: WidgetSize.small, onTap: () {}),
    );
    expect(find.text('Clock'), findsOneWidget);
  });
}
