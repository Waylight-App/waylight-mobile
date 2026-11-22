import 'package:material_ui/material_ui.dart';
import 'package:waylight_mobile/data/repositories/widget_data/queries/home_server.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/ui/core/backup_health_texts.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/widgets/common/compact_state_widget.dart';
import 'package:waylight_mobile/ui/widgets/common/remote_widget.dart';
import 'package:waylight_mobile/ui/widgets/common/widget_rows.dart';

/// The traffic light of the server's own backups (`backup-health`): the
/// verdict and when the newest backup was made. Only the owner may read it.
class BackupHealthWidget extends StatelessWidget {
  /// Creates the view for [widget].
  const BackupHealthWidget({required this.widget, super.key});

  /// The placement of the widget.
  final WidgetPlacement widget;

  /// The builder for the widget registry.
  /// Small and strip tiles show the server's compact state.
  static Widget forPlacement(BuildContext context, WidgetPlacement widget) =>
      CompactStateWidget.orFull(
        context,
        widget,
        title: widget.title.isNotEmpty
            ? widget.title
            : context.l10n.backupHealthTitle,
        full: () =>
            BackupHealthWidget(widget: widget, key: ValueKey(widget.id)),
      );

  @override
  Widget build(BuildContext context) => RemoteWidget(
    title: widget.title.isNotEmpty
        ? widget.title
        : context.l10n.backupHealthTitle,
    query: backupStatusQuery,
    builder: (context, status) {
      final l10n = context.l10n;
      return InfoRow(
        leading: StatusDot(tone: status.tone, label: status.label(l10n)),
        title: status.label(l10n),
        subtitle: status.detail(l10n, (d) => shortDate(context, d)),
      );
    },
  );
}
