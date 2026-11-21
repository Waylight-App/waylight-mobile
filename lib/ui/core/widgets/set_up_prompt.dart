import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';

/// What a widget misses and how to set it up (#230).
typedef SetUpNeed = ({String message, VoidCallback onSetUp});

/// A widget that is not set up yet: one sentence of what is missing and a
/// *Set up* button, in place of an error. Fits every tile size.
class SetUpPrompt extends StatelessWidget {
  /// Creates the prompt for [need].
  const SetUpPrompt({required this.need, this.compact = false, super.key});

  /// What is missing and what the button does.
  final SetUpNeed need;

  /// Small and strip tiles: short text, small button.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final button = FilledButton.tonal(
      key: const ValueKey('setUp'),
      onPressed: need.onSetUp,
      style: compact
          ? FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            )
          : null,
      child: Text(context.l10n.setUpAction),
    );
    if (compact) {
      return Row(
        children: [
          Expanded(
            child: Text(
              need.message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ),
          const SizedBox(width: Dimens.gapSmall),
          button,
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(need.message),
        const SizedBox(height: Dimens.gapSmall),
        button,
      ],
    );
  }
}
