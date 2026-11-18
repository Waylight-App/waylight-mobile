import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/ui/core/widgets/command_button.dart';
import 'package:waylight_mobile/utils/command.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../testing/pump_app.dart';

void main() {
  testWidgets('runs the command and shows its progress', (tester) async {
    final gate = Completer<Result<void>>();
    final command = Command0(() => gate.future);
    var presses = 0;
    await tester.pumpScreen(
      CommandButton(
        command: command,
        onPressed: () {
          presses++;
          command.execute().ignore();
        },
        label: 'Save',
      ),
    );

    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
      reason: 'disabled while running',
    );

    gate.complete(const Result.ok(null));
    await tester.pumpAndSettle();

    expect(find.text('Save'), findsOneWidget);
    expect(presses, 1);
  });

  for (final (variant, type) in [
    (CommandButtonVariant.filled, FilledButton),
    (CommandButtonVariant.outlined, OutlinedButton),
    (CommandButtonVariant.text, TextButton),
  ]) {
    testWidgets('renders the ${variant.name} variant', (tester) async {
      await tester.pumpScreen(
        CommandButton(
          command: Command0(() async => const Result.ok(null)),
          onPressed: () {},
          label: 'Go',
          variant: variant,
        ),
      );

      expect(find.byType(type), findsOneWidget);
    });
  }
}
