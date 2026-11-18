import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/ui/core/widgets/message_banner.dart';

import '../../testing/pump_app.dart';

void main() {
  for (final (kind, icon) in [
    (MessageKind.error, Icons.error_outline),
    (MessageKind.warning, Icons.warning_amber_rounded),
    (MessageKind.info, Icons.info_outline),
  ]) {
    testWidgets('shows the ${kind.name} icon next to the message', (
      tester,
    ) async {
      await tester.pumpScreen(MessageBanner(kind: kind, message: 'Hello'));

      expect(find.text('Hello'), findsOneWidget);
      expect(find.byIcon(icon), findsOneWidget);
    });
  }

  testWidgets('shows an action below the message', (tester) async {
    await tester.pumpScreen(
      MessageBanner(
        kind: MessageKind.error,
        message: 'Failed',
        action: TextButton(onPressed: () {}, child: const Text('Retry')),
      ),
    );

    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('meets the contrast guideline in light and dark', (tester) async {
    for (final brightness in Brightness.values) {
      await tester.pumpScreen(
        const Column(
          children: [
            MessageBanner(kind: MessageKind.error, message: 'Error'),
            MessageBanner(kind: MessageKind.warning, message: 'Warning'),
            MessageBanner(kind: MessageKind.info, message: 'Info'),
          ],
        ),
        brightness: brightness,
      );

      await expectLater(tester, meetsGuideline(textContrastGuideline));
    }
  });
}
