import 'package:material_ui/material_ui.dart';
import 'package:waylight_mobile/data/repositories/widget_data/queries/home_server.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/home_server.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/widgets/tile_rows.dart';
import 'package:waylight_mobile/ui/widgets/common/compact_state_widget.dart';
import 'package:waylight_mobile/ui/widgets/common/remote_widget.dart';
import 'package:waylight_mobile/ui/widgets/common/widget_rows.dart';

/// The native view of the backup monitoring widget (#114): each backup or
/// job with its state and last success, problems first.
class BackupsWidget extends StatelessWidget {
  /// Creates the view for [widget].
  const BackupsWidget({required this.widget, super.key});

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
            : context.l10n.backupsTitle,
        full: () => BackupsWidget(widget: widget, key: ValueKey(widget.id)),
      );

  @override
  Widget build(BuildContext context) => RemoteWidget<List<BackupSource>>(
    title: widget.title.isNotEmpty ? widget.title : context.l10n.backupsTitle,
    query: backupSourcesQuery,
    builder: (context, sources) {
      final l10n = context.l10n;
      if (sources.isEmpty) return Text(l10n.backupsEmpty);
      final sorted = [...sources]
        ..sort((a, b) => _rank(a.state).compareTo(_rank(b.state)));
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TileRows(
            items: sorted,
            rowHeight: TileRows.twoLineRowHeight,
            rowBuilder: (context, s) => InfoRow(
              leading: StatusDot(
                tone: _tone(s.state),
                label: _label(context, s.state),
              ),
              title: s.name,
              subtitle: s.state == BackupState.failed && s.message.isNotEmpty
                  ? s.message
                  : s.lastSuccessAt == null
                  ? _label(context, s.state)
                  : l10n.backupsLastSuccess(
                      shortDate(context, s.lastSuccessAt!.toLocal()),
                    ),
              trailing: s.state == BackupState.ok
                  ? null
                  : _label(context, s.state),
              trailingTone: _tone(s.state),
            ),
          ),
        ],
      );
    },
  );

  static int _rank(BackupState s) => switch (s) {
    BackupState.failed => 0,
    BackupState.overdue => 1,
    BackupState.waiting => 2,
    BackupState.ok => 3,
  };

  static Tone _tone(BackupState s) => switch (s) {
    BackupState.ok => Tone.ok,
    BackupState.overdue => Tone.warning,
    BackupState.failed => Tone.critical,
    BackupState.waiting => Tone.neutral,
  };

  static String _label(BuildContext context, BackupState s) => switch (s) {
    BackupState.ok => context.l10n.backupsOk,
    BackupState.overdue => context.l10n.backupsOverdue,
    BackupState.failed => context.l10n.backupsFailed,
    BackupState.waiting => context.l10n.backupsWaiting,
  };
}
