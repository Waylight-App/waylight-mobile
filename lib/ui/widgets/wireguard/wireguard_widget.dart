import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/data/repositories/widget_data/queries/network.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/network.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/widgets/common/simple_widget.dart';
import 'package:waylight_mobile/ui/widgets/common/widget_rows.dart';

/// The native view of the WireGuard widget (#153).
class WireguardWidget extends StatelessWidget {
  /// Creates the view for [widget].
  const WireguardWidget({required this.widget, super.key});

  /// The placement of the widget.
  final WidgetPlacement widget;

  /// The builder for the widget registry.
  static Widget forPlacement(BuildContext context, WidgetPlacement widget) =>
      WireguardWidget(widget: widget, key: ValueKey(widget.id));

  @override
  Widget build(BuildContext context) => SimpleWidget<List<WireguardPeer>>(
    placement: widget,
    defaultTitle: 'WireGuard',
    query: wireguardQuery,
    interval: const Duration(minutes: 1),
    builder: (context, peers) {
      final l10n = context.l10n;
      if (peers.isEmpty) return Text(l10n.wireguardEmpty);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final p in peers)
            InfoRow(
              leading: StatusDot(
                tone: p.online ? Tone.ok : Tone.neutral,
                label: p.online ? l10n.servicesOnline : l10n.servicesOffline,
              ),
              title: p.name,
              subtitle: p.latestHandshake == null
                  ? null
                  : l10n.wireguardHandshake(
                      shortDate(context, p.latestHandshake!.toLocal()),
                    ),
              trailing:
                  '↓ ${formatBytes(p.receivedBytes)} ↑ ${formatBytes(p.sentBytes)}',
            ),
        ],
      );
    },
  );
}
