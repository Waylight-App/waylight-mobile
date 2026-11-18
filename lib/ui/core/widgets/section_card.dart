import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/ui/core/themes/dimens.dart';

/// A card with a title row and content: the frame of every dashboard
/// widget and of grouped content on other screens.
///
/// Keeps title style, padding and corner radius the same everywhere; the
/// content decides only what is inside.
class SectionCard extends StatelessWidget {
  /// Creates a card titled [title] around [child].
  const SectionCard({
    required this.title,
    required this.child,
    this.trailing,
    super.key,
  });

  /// The heading of the card, announced as a header by screen readers.
  final String title;

  /// A short status at the end of the title row, e.g. "updated 5 min ago".
  final String? trailing;

  /// The content below the title.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trailing = this.trailing;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Dimens.gap),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(title, style: theme.textTheme.titleMedium),
                  ),
                ),
                if (trailing != null)
                  Text(
                    trailing,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: Dimens.gapSmall),
            child,
          ],
        ),
      ),
    );
  }
}
