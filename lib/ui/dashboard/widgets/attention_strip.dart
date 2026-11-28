import 'package:material_ui/material_ui.dart';
import 'package:waylight_mobile/domain/models/compact_state.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/ui/core/compact_texts.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/core/widgets/rows.dart';
import 'package:waylight_mobile/ui/dashboard/view_models/dashboard_view_model.dart';

/// What needs attention now, above the widgets of a tab (#335): the first
/// [DashboardViewModel.attentionStripLength] entries, each opening its
/// widget, and how many more there are. Shows nothing without entries.
class AttentionStrip extends StatelessWidget {
  /// Creates the strip of [entries], most urgent first.
  const AttentionStrip({
    required this.entries,
    required this.onOpen,
    super.key,
  });

  /// What needs attention, most urgent first.
  final List<AttentionStripEntry> entries;

  /// Opens the widget of an entry.
  final ValueChanged<WidgetPlacement> onOpen;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final shown = entries.take(DashboardViewModel.attentionStripLength);
    final more = entries.length - shown.length;
    return Card(
      key: const ValueKey('dashboard.attentionStrip'),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Dimens.gapTiny),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final entry in shown) _row(context, entry),
            if (more > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Dimens.gap,
                  Dimens.gapTiny,
                  Dimens.gap,
                  Dimens.gapSmall,
                ),
                child: Text(
                  l10n.attentionStripMore(more),
                  key: const ValueKey('dashboard.attentionStrip.more'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, AttentionStripEntry entry) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final problem = entry.level == CompactLevel.problem;
    final tone = problem ? Tone.critical : Tone.warning;
    final word = problem
        ? l10n.attentionLevelProblem
        : l10n.attentionLevelWarning;
    final text = switch (entry.text) {
      final text? => compactTextOf(l10n, text),
      null => l10n.attentionBroken,
    };
    final title = entry.widget.displayTitle;
    return Semantics(
      button: true,
      label: '$word, $title: $text',
      excludeSemantics: true,
      child: InkWell(
        key: ValueKey('dashboard.attentionStrip.${entry.widget.id}'),
        onTap: () => onOpen(entry.widget),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: Dimens.tapTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimens.gap),
            child: Row(
              children: [
                StatusDot(tone: tone, label: word),
                const SizedBox(width: Dimens.gapSmall),
                Text(
                  word,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: toneColor(context, tone),
                  ),
                ),
                const SizedBox(width: Dimens.gapCard),
                Expanded(
                  child: Text(
                    '$title · $text',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.chevron_right, size: Dimens.iconSmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
