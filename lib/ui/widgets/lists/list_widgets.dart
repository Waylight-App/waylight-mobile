import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/data/repositories/widget_data/queries/information.dart';
import 'package:waylight_mobile/data/repositories/widget_data/widget_data_repository.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/information.dart';
import 'package:waylight_mobile/ui/core/link_opener.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/core/widgets/compact_lines.dart';
import 'package:waylight_mobile/ui/core/widgets/tile_rows.dart';
import 'package:waylight_mobile/ui/widgets/common/simple_widget.dart';
import 'package:waylight_mobile/ui/widgets/common/widget_rows.dart';

/// The list widgets: their data maps to sections of lines, so one view
/// shows them all (briefing #116, Sonarr/Radarr #113, media #133, releases
/// #141, game deals #127, space #147, read later #140).
class ListWidget extends StatelessWidget {
  const ListWidget._({
    required this.widget,
    required this.query,
    required this.title,
    required this.interval,
    super.key,
  });

  /// The placement of the widget.
  final WidgetPlacement widget;

  /// What to load.
  final WidgetQuery<List<FeedSection>> query;

  /// The default title.
  final String Function(AppLocalizations l10n) title;

  /// How often it reloads.
  final Duration interval;

  /// Lines per section.
  static const maxItems = 6;

  static Widget _for(
    WidgetPlacement widget,
    WidgetQuery<List<FeedSection>> query,
    String Function(AppLocalizations l10n) title, {
    Duration interval = const Duration(minutes: 15),
  }) => ListWidget._(
    widget: widget,
    query: query,
    title: title,
    interval: interval,
    key: ValueKey(widget.id),
  );

  /// The daily briefing.
  static Widget briefing(BuildContext context, WidgetPlacement widget) =>
      _for(widget, briefingQuery, (l) => l.briefingTitle);

  /// Sonarr, Radarr and Prowlarr.
  static Widget arr(BuildContext context, WidgetPlacement widget) =>
      _for(widget, arrQuery, (l) => 'Sonarr & Radarr');

  /// Plex, Jellyfin and Emby.
  static Widget media(BuildContext context, WidgetPlacement widget) => _for(
    widget,
    mediaQuery,
    (l) => l.mediaTitle,
    interval: const Duration(minutes: 1),
  );

  /// Music releases.
  static Widget releases(BuildContext context, WidgetPlacement widget) =>
      _for(widget, releasesQuery, (l) => l.releasesTitle);

  /// Game deals.
  static Widget gameDeals(BuildContext context, WidgetPlacement widget) =>
      _for(widget, gameDealsQuery, (l) => l.gameDealsTitle);

  /// Rocket launches.
  static Widget space(BuildContext context, WidgetPlacement widget) =>
      _for(widget, launchesQuery, (l) => l.spaceTitle);

  @override
  Widget build(BuildContext context) => SimpleWidget<List<FeedSection>>(
    placement: widget,
    defaultTitle: title(context.l10n),
    query: query,
    interval: interval,
    compact: (context, sections, size) {
      final l10n = context.l10n;
      final items = [for (final s in sections) ...s.items];
      if (items.isEmpty) return Text(l10n.listEmpty);
      final first = items.first;
      return CompactLines(
        headline: first.title,
        detail: items.length > 1
            ? l10n.listMore(items.length - 1)
            : first.detail,
        size: size,
      );
    },
    builder: (context, sections) {
      final l10n = context.l10n;
      final shown = sections.where((s) => s.items.isNotEmpty).toList();
      if (shown.isEmpty) return Text(l10n.listEmpty);
      final locale = Localizations.localeOf(context).toLanguageTag();
      final date = DateFormat.MMMd(locale);
      final time = DateFormat.MMMd(locale).add_Hm();
      // A section's heading sits on its first row, so a tile never ends on
      // a heading alone.
      final rows = <Widget>[
        for (final s in shown) ...[
          for (final (i, item) in s.items.take(maxItems).indexed)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (i == 0)
                  if (sectionTitle(l10n, s.title) case final heading?) ...[
                    const SizedBox(height: Dimens.gapTiny),
                    Text(
                      heading,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ],
                InfoRow(
                  title: item.title,
                  subtitle: [
                    if (item.detail.isNotEmpty) item.detail,
                    if (item.at case final at?)
                      at.hour == 0 && at.minute == 0
                          ? date.format(at)
                          : time.format(at),
                  ].join(' · '),
                  leading: item.tone == FeedTone.neutral
                      ? null
                      : StatusDot(
                          tone: item.tone == FeedTone.critical
                              ? Tone.critical
                              : Tone.warning,
                          label: '',
                        ),
                  onTap: item.url == null
                      ? null
                      : () => LinkOpener.of(context).open(item.url!),
                ),
              ],
            ),
          if (s.more + (s.items.length - maxItems).clamp(0, 999) > 0)
            Text(
              l10n.listMore(s.more + (s.items.length - maxItems).clamp(0, 999)),
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ];
      return TileRows<Widget>(
        items: rows,
        // A heading above a row takes some more.
        rowHeight: TileRows.twoLineRowHeight + 16,
        rowBuilder: (context, row) => row,
      );
    },
  );
}

/// The heading of a section by its key; `null` hides it.
String? sectionTitle(AppLocalizations l10n, String key) => switch (key) {
  'briefing.warnings' => l10n.briefingWarnings,
  'briefing.incidents' => l10n.briefingIncidents,
  'briefing.todos' => l10n.briefingTodos,
  'briefing.events' => l10n.briefingEvents,
  'briefing.waste' => l10n.wasteTitle,
  'arr.health' => l10n.arrHealth,
  'arr.upcoming' => l10n.arrUpcoming,
  'arr.queue' => l10n.arrQueue,
  'media.playing' => l10n.mediaPlaying,
  'media.recent' => l10n.mediaRecent,
  'gamedeals.free' => l10n.gameDealsFree,
  'gamedeals.deals' => l10n.gameDealsDeals,
  'gamedeals.next' => l10n.gameDealsNext,
  '' => null,
  _ => key.contains('.') ? key.split('.').last : key,
};
