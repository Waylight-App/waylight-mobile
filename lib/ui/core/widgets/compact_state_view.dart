import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/domain/models/compact_state.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/core/widgets/rows.dart';

/// The content of a small or strip tile from the server's compact state
/// (#228): the title line, coloured only when it needs attention, and the
/// detail line in small tiles.
class CompactStateView extends StatelessWidget {
  /// Creates the view of [state] for a tile of [size].
  const CompactStateView({required this.state, required this.size, super.key});

  /// The state to show.
  final CompactState state;

  /// The size of the tile; strips show the title line only.
  final WidgetSize size;

  /// The tone of [level]; healthy and neutral states stay uncoloured.
  static Tone? toneOf(CompactLevel level) => switch (level) {
    CompactLevel.attention => Tone.warning,
    CompactLevel.problem => Tone.critical,
    CompactLevel.none || CompactLevel.ok => null,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = toneOf(state.level);
    final title = Text(
      state.title.text,
      maxLines: size == WidgetSize.strip ? 1 : 2,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.titleSmall?.copyWith(
        color: tone == null ? null : toneColor(context, tone),
      ),
    );
    final detail = state.detail;
    if (size == WidgetSize.strip || detail == null || detail.text.isEmpty) {
      return title;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        title,
        const SizedBox(height: Dimens.gapTiny),
        Text(
          detail.text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
