import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';

/// The content of a small or strip tile made of a headline and one line
/// of detail (#211): a strip shows both in one line, a small tile on two.
///
/// Long texts are cut with an ellipsis, and the detail line gives way at
/// large text sizes, so the tile never overflows.
class CompactLines extends StatelessWidget {
  /// Creates the lines for a tile of [size].
  const CompactLines({
    required this.headline,
    required this.size,
    this.detail,
    super.key,
  });

  /// The main line.
  final String headline;

  /// The line below it; empty or `null` for none.
  final String? detail;

  /// The size of the tile.
  final WidgetSize size;

  /// The largest text scale at which a small tile still has room for the
  /// detail line.
  static const maxDetailScale = 1.5;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detail = this.detail;
    final hasDetail =
        detail != null &&
        detail.isNotEmpty &&
        MediaQuery.textScalerOf(context).scale(1) <= maxDetailScale;
    if (size == WidgetSize.strip) {
      return Text(
        hasDetail ? '$headline · $detail' : headline,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          headline,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall,
        ),
        if (hasDetail) ...[
          const SizedBox(height: Dimens.gapTiny),
          Text(
            detail,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
