import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/utils/command.dart';

/// The emphasis of a [CommandButton], from strongest to weakest
/// (Material 3: filled, outlined, text).
enum CommandButtonVariant {
  /// The main action of a screen; at most one per screen.
  filled,

  /// A secondary action.
  outlined,

  /// A low-emphasis action, e.g. in a dialog or next to another button.
  text,
}

/// A button that runs a [Command] and shows its progress.
///
/// While the command runs, the button is disabled and shows a progress
/// indicator, so a double tap cannot start the action twice and no screen
/// needs its own loading flag.
///
/// ```dart
/// CommandButton(
///   command: viewModel.connect,
///   onPressed: () => viewModel.connect.execute(controller.text),
///   label: l10n.connectButton,
/// )
/// ```
class CommandButton extends StatelessWidget {
  /// Creates a button for [command].
  const CommandButton({
    required this.command,
    required this.onPressed,
    required this.label,
    this.variant = CommandButtonVariant.filled,
    super.key,
  });

  /// The command whose state the button shows.
  final Command<Object?> command;

  /// Starts the command, usually `() => command.execute(…)`.
  final VoidCallback onPressed;

  /// The text of the button.
  final String label;

  /// How prominent the button is.
  final CommandButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: command,
      builder: (context, _) {
        final running = command.running;
        final child = running
            ? Semantics(
                label: label,
                child: const SizedBox.square(
                  dimension: Dimens.inlineProgress,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : Text(label);
        final onPressed = running ? null : this.onPressed;
        return switch (variant) {
          CommandButtonVariant.filled => FilledButton(
            onPressed: onPressed,
            child: child,
          ),
          CommandButtonVariant.outlined => OutlinedButton(
            onPressed: onPressed,
            child: child,
          ),
          CommandButtonVariant.text => TextButton(
            onPressed: onPressed,
            child: child,
          ),
        };
      },
    );
  }
}
