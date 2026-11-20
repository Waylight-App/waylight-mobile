// Rows shared by the widgets and the search answers: tone, status dot,
// info row and meter.
import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/ui/core/themes/dimens.dart';

/// How good or bad a value is; decides its colour in the widgets.
enum Tone {
  /// Fine.
  ok,

  /// Needs attention.
  warning,

  /// Broken or full.
  critical,

  /// No verdict, e.g. not checked yet.
  neutral,
}

/// The colour of a [Tone] in the current theme.
Color toneColor(BuildContext context, Tone tone) {
  final scheme = Theme.of(context).colorScheme;
  return switch (tone) {
    Tone.ok => scheme.tertiary,
    Tone.warning => scheme.primary,
    Tone.critical => scheme.error,
    Tone.neutral => scheme.outline,
  };
}

/// A small coloured dot for a state; the [label] is read out instead.
class StatusDot extends StatelessWidget {
  /// Creates the dot.
  const StatusDot({required this.tone, required this.label, super.key});

  /// The state.
  final Tone tone;

  /// What the dot means, for screen readers.
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    child: Container(
      width: Dimens.gapCard,
      height: Dimens.gapCard,
      decoration: BoxDecoration(
        color: toneColor(context, tone),
        shape: BoxShape.circle,
      ),
    ),
  );
}

/// One line of a widget list: an optional leading emoji or dot, a title
/// with an optional subtitle, and a trailing value.
class InfoRow extends StatelessWidget {
  /// Creates the row.
  const InfoRow({
    required this.title,
    this.leading,
    this.subtitle,
    this.trailing,
    this.trailingTone,
    this.onTap,
    super.key,
  });

  /// The main text.
  final String title;

  /// An emoji or a [StatusDot] in front.
  final Widget? leading;

  /// A second, smaller line.
  final String? subtitle;

  /// A value at the end, such as "in 3 days".
  final String? trailing;

  /// Colours [trailing]; `null` keeps the text colour.
  final Tone? trailingTone;

  /// Opens something, e.g. the service in the browser.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimens.gapTiny),
      child: Row(
        children: [
          if (leading != null) ...[
            SizedBox(
              width: Dimens.iconLarge,
              child: Center(child: leading),
            ),
            const SizedBox(width: Dimens.gapSmall),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title),
                if (subtitle != null && subtitle!.isNotEmpty)
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: theme.textTheme.titleSmall?.copyWith(
                color: trailingTone == null
                    ? null
                    : toneColor(context, trailingTone!),
              ),
            ),
        ],
      ),
    );
    if (onTap == null) return row;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: Dimens.tapTarget),
        child: row,
      ),
    );
  }
}

/// A labelled bar for a share, such as memory or a disk.
class MeterRow extends StatelessWidget {
  /// Creates the meter.
  const MeterRow({
    required this.label,
    required this.percent,
    this.detail,
    this.invert = false,
    super.key,
  });

  /// What is measured.
  final String label;

  /// The share, 0 to 100.
  final double percent;

  /// Extra text after the percentage, such as "1.2 of 4 TB".
  final String? detail;

  /// Whether a high share is good, such as progress, instead of a warning
  /// like a full disk.
  final bool invert;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = invert
        ? Tone.ok
        : percent >= 90
        ? Tone.critical
        : percent >= 75
        ? Tone.warning
        : Tone.ok;
    final value = '${percent.round()} %';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimens.gapTiny),
      child: Semantics(
        label: '$label $value${detail == null ? '' : ', $detail'}',
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(label)),
                Text(
                  detail == null ? value : '$value · $detail',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: Dimens.gapTiny),
            LinearProgressIndicator(
              value: (percent / 100).clamp(0, 1),
              color: toneColor(context, tone),
            ),
          ],
        ),
      ),
    );
  }
}
