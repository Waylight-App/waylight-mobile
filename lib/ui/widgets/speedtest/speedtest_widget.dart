import 'package:material_ui/material_ui.dart';
import 'package:waylight_mobile/data/repositories/widget_data/queries/network.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/network.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/widgets/tile_rows.dart';
import 'package:waylight_mobile/ui/widgets/common/compact_state_widget.dart';
import 'package:waylight_mobile/ui/widgets/common/simple_widget.dart';
import 'package:waylight_mobile/ui/widgets/common/widget_rows.dart';

/// The native view of the speed test widget (#148): the latest result and
/// the average of the shown history.
class SpeedtestWidget extends StatelessWidget {
  /// Creates the view for [widget].
  const SpeedtestWidget({required this.widget, super.key});

  /// The placement of the widget.
  final WidgetPlacement widget;

  /// The builder for the widget registry.
  /// Small and strip tiles show the server's compact state (#274).
  static Widget forPlacement(BuildContext context, WidgetPlacement widget) =>
      CompactStateWidget.orFull(
        context,
        widget,
        title: widget.title.isNotEmpty
            ? widget.title
            : context.l10n.speedtestTitle,
        full: () => SpeedtestWidget(widget: widget, key: ValueKey(widget.id)),
      );

  @override
  Widget build(BuildContext context) => SimpleWidget<SpeedtestResults>(
    placement: widget,
    defaultTitle: context.l10n.speedtestTitle,
    query: speedtestQuery,
    interval: const Duration(minutes: 30),
    builder: (context, results) {
      final l10n = context.l10n;
      final latest = results.latest;
      if (latest == null) return Text(l10n.speedtestEmpty);
      String avg(double Function(SpeedtestResult) f) => results.history.isEmpty
          ? ''
          : l10n.speedtestAverage(
              (results.history.map(f).reduce((a, b) => a + b) /
                      results.history.length)
                  .round(),
            );
      return TileRows<Widget>(
        items: [
          InfoRow(
            leading: const Text('⬇️', semanticsLabel: ''),
            title: l10n.speedtestDownload,
            subtitle: avg((r) => r.downloadMbps),
            trailing: '${latest.downloadMbps.round()} Mbit/s',
          ),
          InfoRow(
            leading: const Text('⬆️', semanticsLabel: ''),
            title: l10n.speedtestUpload,
            subtitle: avg((r) => r.uploadMbps),
            trailing: '${latest.uploadMbps.round()} Mbit/s',
          ),
          InfoRow(
            leading: const Text('⏱️', semanticsLabel: ''),
            title: l10n.speedtestPing,
            trailing: '${latest.pingMs.round()} ms',
          ),
        ],
        rowHeight: TileRows.twoLineRowHeight,
        rowBuilder: (context, row) => row,
      );
    },
  );
}
