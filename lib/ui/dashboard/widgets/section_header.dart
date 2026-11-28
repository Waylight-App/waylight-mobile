import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';

/// The header of one section of a tab (#334): its name and a chevron;
/// tapping it collapses or expands the section. A collapsed header also
/// shows how many widgets the section holds and a dot when one of them
/// needs attention.
class SectionHeader extends StatelessWidget {
  /// Creates the header of the section [title] with [count] widgets.
  const SectionHeader({
    required this.title,
    required this.count,
    required this.collapsed,
    required this.attention,
    required this.onToggle,
    super.key,
  });

  /// The name of the section.
  final String title;

  /// How many widgets the section holds.
  final int count;

  /// Whether the section's widgets are hidden.
  final bool collapsed;

  /// Whether one of the section's widgets needs attention.
  final bool attention;

  /// Collapses or expands the section.
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final showAttention = collapsed && attention;
    return Semantics(
      button: true,
      expanded: !collapsed,
      label: [
        title,
        l10n.dashboardSectionCount(count),
        if (showAttention) l10n.dashboardSectionAttention,
      ].join(', '),
      onTapHint: collapsed
          ? l10n.dashboardSectionExpand
          : l10n.dashboardSectionCollapse,
      onTap: onToggle,
      excludeSemantics: true,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(Dimens.radiusSmall),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: Dimens.tapTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimens.gapSmall),
            child: Row(
              children: [
                Expanded(child: Text(title, style: theme.textTheme.titleSmall)),
                if (collapsed) ...[
                  Text(
                    '$count',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: Dimens.gapSmall),
                ],
                if (showAttention) ...[
                  Badge(
                    key: const ValueKey('section.attention'),
                    backgroundColor: theme.colorScheme.error,
                  ),
                  const SizedBox(width: Dimens.gapSmall),
                ],
                Icon(collapsed ? Icons.expand_more : Icons.expand_less),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
