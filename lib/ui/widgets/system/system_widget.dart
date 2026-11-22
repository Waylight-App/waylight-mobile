import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/data/repositories/widget_data/queries/home_server.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/home_server.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/core/widgets/compact_lines.dart';
import 'package:waylight_mobile/ui/widgets/common/remote_widget.dart';
import 'package:waylight_mobile/ui/widgets/common/widget_rows.dart';

/// The native view of the system widget (#151).
class SystemWidget extends StatelessWidget {
  /// Creates the view for [widget].
  const SystemWidget({required this.widget, super.key});

  /// The placement of the widget.
  final WidgetPlacement widget;

  /// The builder for the widget registry.
  static Widget forPlacement(BuildContext context, WidgetPlacement widget) =>
      SystemWidget(widget: widget, key: ValueKey(widget.id));

  @override
  Widget build(BuildContext context) => RemoteWidget<SystemStatus>(
    title: widget.title.isNotEmpty ? widget.title : context.l10n.systemTitle,
    query: systemQuery,
    interval: const Duration(seconds: 30),
    compact: (context, s, size) {
      final l10n = context.l10n;
      return CompactLines(
        headline: '${l10n.systemCpu} ${s.cpuPercent.round()} %',
        detail: '${l10n.systemMemory} ${s.memoryPercent.round()} %',
        size: size,
      );
    },
    builder: (context, s) {
      final l10n = context.l10n;
      final theme = Theme.of(context);
      final facts = [
        l10n.systemUptime(s.uptime.inDays, s.uptime.inHours % 24),
        if (s.temperature != null) '${s.temperature!.round()} °C',
        if (s.load1 != null) l10n.systemLoad(s.load1!.toStringAsFixed(2)),
      ];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${s.hostname} · ${facts.join(' · ')}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Dimens.gapSmall),
          MeterRow(label: l10n.systemCpu, percent: s.cpuPercent),
          MeterRow(label: l10n.systemMemory, percent: s.memoryPercent),
          if (s.swapPercent > 0)
            MeterRow(label: l10n.systemSwap, percent: s.swapPercent),
          for (final d in s.disks)
            MeterRow(
              label: d.label,
              percent: d.percent,
              detail: [
                l10n.systemDiskOf(
                  formatBytes(d.usedBytes),
                  formatBytes(d.totalBytes),
                ),
                if (d.daysUntilFull != null)
                  l10n.systemFullIn(d.daysUntilFull!),
              ].join(' · '),
            ),
        ],
      );
    },
  );
}
