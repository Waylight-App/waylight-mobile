import 'package:material_ui/material_ui.dart';
import 'package:waylight_mobile/data/repositories/widget_data/queries/home_server.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/home_server.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/widgets/tile_rows.dart';
import 'package:waylight_mobile/ui/widgets/common/compact_state_widget.dart';
import 'package:waylight_mobile/ui/widgets/common/simple_widget.dart';
import 'package:waylight_mobile/ui/widgets/common/widget_rows.dart';

/// The native view of the disk health widget (#119).
class DiskHealthWidget extends StatelessWidget {
  /// Creates the view for [widget].
  const DiskHealthWidget({required this.widget, super.key});

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
            : context.l10n.diskHealthTitle,
        full: () => DiskHealthWidget(widget: widget, key: ValueKey(widget.id)),
      );

  @override
  Widget build(BuildContext context) => SimpleWidget<List<DiskHealth>>(
    placement: widget,
    defaultTitle: context.l10n.diskHealthTitle,
    query: diskHealthQuery,
    interval: const Duration(minutes: 30),
    builder: (context, disks) {
      final l10n = context.l10n;
      if (disks.isEmpty) return Text(l10n.diskHealthEmpty);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TileRows(
            items: disks,
            rowHeight: TileRows.twoLineRowHeight,
            rowBuilder: (context, d) => InfoRow(
              leading: StatusDot(
                tone: _tone(d.status),
                label: _label(context, d.status),
              ),
              title: d.model.isEmpty ? d.device : d.model,
              subtitle: [
                if (d.temperature != null) '${d.temperature} °C',
                if (d.percentageUsed != null)
                  l10n.diskHealthWear(d.percentageUsed!),
                ...d.findings,
              ].join(' · '),
              trailing: _label(context, d.status),
              trailingTone: _tone(d.status),
            ),
          ),
        ],
      );
    },
  );

  static Tone _tone(String status) => switch (status) {
    'ok' || 'passed' => Tone.ok,
    'warning' => Tone.warning,
    'failing' || 'failed' || 'critical' => Tone.critical,
    _ => Tone.neutral,
  };

  static String _label(BuildContext context, String status) =>
      switch (_tone(status)) {
        Tone.ok => context.l10n.backupsOk,
        Tone.warning => context.l10n.diskHealthWarning,
        Tone.critical => context.l10n.diskHealthFailing,
        Tone.neutral => context.l10n.diskHealthUnknown,
      };
}
