import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:waylight_mobile/ui/core/themes/app_theme.dart';
import 'package:waylight_mobile/ui/core/widgets/message_banner.dart';
import 'package:waylight_mobile/ui/core/widgets/rows.dart';
import 'package:waylight_mobile/ui/core/widgets/section_card.dart';

import '../../testing/pump_app.dart';

/// The high-contrast theme of the accessibility options (#291).
void main() {
  Widget screen() => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SectionCard(
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
        const SizedBox(height: 12),
        const MessageBanner(
          kind: MessageKind.warning,
          message: 'Offline: showing data from 10:42.',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            FilledButton(onPressed: () {}, child: const Text('Save')),
            const SizedBox(width: 12),
            OutlinedButton(onPressed: () {}, child: const Text('Cancel')),
          ],
        ),
        const SizedBox(height: 12),
        const TextField(decoration: InputDecoration(labelText: 'Address')),
      ],
    ),
  );

  for (final brightness in Brightness.values) {
    testWidgets('draws outlines and strong colours (${brightness.name})', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpScreen(
        screen(),
        theme: AppTheme.highContrast(brightness),
      );
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/high_contrast_${brightness.name}.png'),
      );
    });
  }
}
