import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/core/themes/status_colors.dart';

/// What a [MessageBanner] reports; decides its colours and icon.
enum MessageKind {
  /// Something failed, e.g. the server cannot be reached.
  error,

  /// Something needs attention, e.g. offline or plain HTTP.
  warning,

  /// Neutral information, e.g. why a search source cannot answer.
  info,
}

/// A rounded box with an icon and a message, for errors, warnings and
/// information inside a screen.
///
/// States are never told by colour alone: every kind has its own icon, and
/// errors are announced by screen readers (live region).
class MessageBanner extends StatelessWidget {
  /// Creates a banner of [kind] with [message].
  const MessageBanner({
    required this.kind,
    required this.message,
    this.action,
    super.key,
  });

  /// What the banner reports.
  final MessageKind kind;

  /// The text, a full sentence.
  final String message;

  /// An optional button below the text, e.g. "Try again".
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final status = StatusColors.of(context);
    final (background, foreground, icon) = switch (kind) {
      MessageKind.error => (
        colors.errorContainer,
        colors.onErrorContainer,
        Icons.error_outline,
      ),
      MessageKind.warning => (
        status.warningContainer,
        status.onWarningContainer,
        Icons.warning_amber_rounded,
      ),
      MessageKind.info => (
        colors.surfaceContainerHigh,
        colors.onSurfaceVariant,
        Icons.info_outline,
      ),
    };
    return Semantics(
      liveRegion: kind == MessageKind.error,
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(Dimens.radiusBanner),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Dimens.gapCard),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: foreground, size: Dimens.iconSmall),
              const SizedBox(width: Dimens.gapCard),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: foreground),
                    ),
                    if (action case final action?)
                      Padding(
                        padding: const EdgeInsets.only(top: Dimens.gapSmall),
                        child: action,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
