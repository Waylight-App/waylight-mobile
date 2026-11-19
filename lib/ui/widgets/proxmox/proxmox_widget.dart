import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/data/repositories/widget_data/queries/home_server.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/home_server.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/widgets/common/simple_widget.dart';
import 'package:waylight_mobile/ui/widgets/common/widget_rows.dart';

/// The native view of the Proxmox widget (#138): node load and the guests.
class ProxmoxWidget extends StatelessWidget {
  /// Creates the view for [widget].
  const ProxmoxWidget({required this.widget, super.key});

  /// The placement of the widget.
  final WidgetPlacement widget;

  /// The builder for the widget registry.
  static Widget forPlacement(BuildContext context, WidgetPlacement widget) =>
      ProxmoxWidget(widget: widget, key: ValueKey(widget.id));

  @override
  Widget build(BuildContext context) => SimpleWidget<ProxmoxOverview>(
    placement: widget,
    defaultTitle: 'Proxmox VE',
    query: proxmoxQuery,
    interval: const Duration(minutes: 1),
    builder: (context, pve) {
      final l10n = context.l10n;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final n in pve.nodes) ...[
            MeterRow(
              label: '${n.name} · ${l10n.systemCpu}',
              percent: n.cpuPercent,
            ),
            MeterRow(
              label: '${n.name} · ${l10n.systemMemory}',
              percent: n.memoryPercent,
            ),
          ],
          for (final g in pve.guests)
            InfoRow(
              leading: StatusDot(
                tone: g.running ? Tone.ok : Tone.neutral,
                label: g.running ? l10n.proxmoxRunning : l10n.proxmoxStopped,
              ),
              title: g.name,
              subtitle: '${g.id} · ${g.kind == 'lxc' ? 'LXC' : 'VM'}',
            ),
        ],
      );
    },
  );
}
