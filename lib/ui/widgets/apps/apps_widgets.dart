import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/data/repositories/widget_data/queries/information.dart';
import 'package:waylight_mobile/data/repositories/widget_data/widget_data_repository.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/information.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/widgets/compact_lines.dart';
import 'package:waylight_mobile/ui/core/widgets/tile_rows.dart';
import 'package:waylight_mobile/ui/widgets/common/simple_widget.dart';
import 'package:waylight_mobile/ui/widgets/common/widget_rows.dart';

/// The Immich widget (#130) and the Nextcloud widget (#134): a few facts and
/// the storage.
class AppOverviewWidget extends StatelessWidget {
  const AppOverviewWidget._({
    required this.widget,
    required this.title,
    required this.query,
    super.key,
  });

  /// The placement of the widget.
  final WidgetPlacement widget;

  /// The default title.
  final String title;

  /// What to load.
  final WidgetQuery<AppOverview> query;

  /// Immich.
  static Widget immich(BuildContext context, WidgetPlacement widget) =>
      AppOverviewWidget._(
        widget: widget,
        title: 'Immich',
        query: immichQuery,
        key: ValueKey(widget.id),
      );

  /// Nextcloud.
  static Widget nextcloud(BuildContext context, WidgetPlacement widget) =>
      AppOverviewWidget._(
        widget: widget,
        title: 'Nextcloud',
        query: nextcloudQuery,
        key: ValueKey(widget.id),
      );

  @override
  Widget build(BuildContext context) => SimpleWidget<AppOverview>(
    placement: widget,
    defaultTitle: title,
    query: query,
    interval: const Duration(minutes: 30),
    compact: (context, app, size) {
      final l10n = context.l10n;
      final n = NumberFormat.decimalPattern(
        Localizations.localeOf(context).toLanguageTag(),
      );
      final updates = app.appUpdates ?? 0;
      return CompactLines(
        headline: app.maintenance
            ? l10n.appMaintenance
            : updates > 0
            ? '${l10n.appUpdates}: ${n.format(updates)}'
            : title,
        detail: [
          if (app.photos != null) '${l10n.appPhotos} ${n.format(app.photos)}',
          if (app.users != null) '${l10n.appUsers} ${n.format(app.users)}',
        ].join(' · '),
        size: size,
      );
    },
    builder: (context, app) {
      final l10n = context.l10n;
      final n = NumberFormat.decimalPattern(
        Localizations.localeOf(context).toLanguageTag(),
      );
      return TileRows<Widget>(
        items: [
          if (app.maintenance)
            InfoRow(
              leading: StatusDot(
                tone: Tone.warning,
                label: l10n.appMaintenance,
              ),
              title: l10n.appMaintenance,
            ),
          if (app.photos != null)
            InfoRow(title: l10n.appPhotos, trailing: n.format(app.photos)),
          if (app.videos != null)
            InfoRow(title: l10n.appVideos, trailing: n.format(app.videos)),
          if (app.users != null)
            InfoRow(title: l10n.appUsers, trailing: n.format(app.users)),
          if (app.appUpdates != null && app.appUpdates! > 0)
            InfoRow(
              title: l10n.appUpdates,
              trailing: n.format(app.appUpdates),
              trailingTone: Tone.warning,
            ),
          if (app.version.isNotEmpty)
            InfoRow(title: 'Version', trailing: app.version),
          if (app.storagePercent != null)
            MeterRow(
              label: l10n.appStorage,
              percent: app.storagePercent!,
              detail: app.storageUsed == null || app.storageTotal == null
                  ? null
                  : l10n.systemDiskOf(
                      formatBytes(app.storageUsed!),
                      formatBytes(app.storageTotal!),
                    ),
            ),
        ],
        rowHeight: TileRows.lineRowHeight + 12,
        rowBuilder: (context, row) => row,
      );
    },
  );
}
