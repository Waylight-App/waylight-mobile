import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:waylight_mobile/ui/core/widgets/rows.dart';
import 'package:waylight_mobile/ui/core/widgets/section_card.dart';

import '../../testing/pump_app.dart';

/// The calm tile (#288): only warning and critical rows carry colour.
void main() {
  Widget tile() => Padding(
    padding: const EdgeInsets.all(16),
    child: SectionCard(
      title: 'Services',
      child: Column(
        children: [
          for (final tone in Tone.values)
            InfoRow(
              leading: StatusDot(tone: tone, label: tone.name),
              title: tone.name,
              trailing: tone.name,
              trailingTone: tone,
            ),
        ],
      ),
    ),
  );

  for (final brightness in Brightness.values) {
    testWidgets('colours only warning and critical (${brightness.name})', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 320);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpScreen(tile(), brightness: brightness);
      await expectLater(
        find.byType(SectionCard),
        matchesGoldenFile('goldens/tones_${brightness.name}.png'),
      );
    });
  }

  testWidgets('a healthy row has no accent colour', (tester) async {
    await tester.pumpScreen(tile());
    final context = tester.element(find.byType(SectionCard));
    final scheme = Theme.of(context).colorScheme;
    expect(toneColor(context, Tone.ok), scheme.onSurfaceVariant);
    expect(toneColor(context, Tone.warning), scheme.primary);
    expect(toneColor(context, Tone.critical), scheme.error);
  });
}
