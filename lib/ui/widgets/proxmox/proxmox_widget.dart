import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:waylight_mobile/data/repositories/actions/home_server_actions_repository.dart';

import 'package:waylight_mobile/data/repositories/widget_data/queries/home_server.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/home_server.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/widgets/tile_rows.dart';
import 'package:waylight_mobile/ui/widgets/common/admin_actions.dart';
import 'package:waylight_mobile/ui/widgets/common/compact_state_widget.dart';
import 'package:waylight_mobile/ui/widgets/common/simple_widget.dart';
import 'package:waylight_mobile/ui/widgets/common/widget_rows.dart';

/// The native view of the Proxmox widget (#138): node load and the guests;
/// admins start and shut down the guests the owner allowed.
class ProxmoxWidget extends StatelessWidget {
  /// Creates the view for [widget].
  const ProxmoxWidget({required this.widget, super.key});

  /// The placement of the widget.
  final WidgetPlacement widget;

  /// The builder for the widget registry.
  /// Small and strip tiles show the server's compact state (#278).
  static Widget forPlacement(BuildContext context, WidgetPlacement widget) =>
      CompactStateWidget.orFull(
        context,
        widget,
        title: widget.title.isNotEmpty ? widget.title : 'Proxmox VE',
        full: () => ProxmoxWidget(widget: widget, key: ValueKey(widget.id)),
      );

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
          // The meters of the nodes come first, then the guests.
          TileRows<Widget>(
            items: [
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
                    label: g.running
                        ? l10n.proxmoxRunning
                        : l10n.proxmoxStopped,
                  ),
                  title: g.name,
                  subtitle: '${g.id} · ${g.kind == 'lxc' ? 'LXC' : 'VM'}',
                  onTap: g.actions ? () => _power(context, g) : null,
                ),
            ],
            rowHeight: TileRows.twoLineRowHeight,
            rowBuilder: (context, row) => row,
          ),
        ],
      );
    },
  );

  static Future<void> _power(BuildContext context, ProxmoxGuest g) async {
    final l10n = context.l10n;
    if (!await isAdmin(context) || !context.mounted) return;
    final action = g.running ? 'shutdown' : 'start';
    final label = g.running ? l10n.proxmoxShutdown : l10n.proxmoxStart;
    if (!await confirmAction(
      context,
      title: '$label: ${g.name}',
      action: label,
    )) {
      return;
    }
    if (!context.mounted) return;
    final repo = context.read<HomeServerActionsRepository>();
    await runAction(
      context,
      (server) => repo.powerGuest(server, g.id, action),
      done: l10n.proxmoxSent(g.name),
    );
  }
}
