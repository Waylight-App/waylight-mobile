import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';

/// The card of a widget in a small or strip tile of the dashboard grid
/// (#211, docs/design: *Home screen as a grid of sizes*).
///
/// Small tiles are half a phone wide: a short title above the content.
/// Strips are one row high: title and content side by side on one line.
/// Everything is cut with an ellipsis, so nothing overflows the tile.
///
/// ```dart
/// CompactCard(
///   title: 'Weather',
///   size: WidgetSize.small,
///   child: Text('8 °C'),
/// )
/// ```
class CompactCard extends StatelessWidget {
  /// Creates the card for a tile of [size] (small or strip).
  const CompactCard({
    required this.title,
    required this.size,
    required this.child,
    this.status,
    super.key,
  });

  /// The title of the widget.
  final String title;

  /// The size of the tile: [WidgetSize.strip] lays out in one row.
  final WidgetSize size;

  /// The compact content.
  final Widget child;

  /// A short note on the age of the data, shown in small tiles.
  final String? status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = theme.textTheme.labelMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final status = this.status;
    if (size == WidgetSize.strip) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Dimens.gap,
            vertical: Dimens.gapSmall,
          ),
          child: Row(
            children: [
              Flexible(
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: label,
                  ),
                ),
              ),
              const SizedBox(width: Dimens.gapCard),
              Expanded(
                flex: 3,
                child: DefaultTextStyle.merge(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  child: child,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Dimens.gapCard),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: label,
              ),
            ),
            const SizedBox(height: Dimens.gapTiny),
            child,
            if (status != null) ...[
              const SizedBox(height: Dimens.gapTiny),
              Text(
                status,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The content of a small or strip tile for a widget without a compact
/// view yet: a hint that tapping shows everything (#211).
class TapToOpenHint extends StatelessWidget {
  /// Creates the hint.
  const TapToOpenHint({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          Icons.open_in_full,
          size: Dimens.iconSmall,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: Dimens.gapSmall),
        Flexible(
          child: Text(
            context.l10n.dashboardTapToOpen,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

/// Whether [size] is a tile too narrow or too low for a widget's normal
/// view, so it shows its compact form.
bool isCompact(WidgetSize? size) =>
    size == WidgetSize.small || size == WidgetSize.strip;
