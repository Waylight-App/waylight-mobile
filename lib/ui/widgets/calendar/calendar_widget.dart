import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:waylight_mobile/data/repositories/widget_data/queries/information.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/information.dart';
import 'package:waylight_mobile/routing/routes.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/core/widget_size_scope.dart';
import 'package:waylight_mobile/ui/core/widgets/tile_rows.dart';
import 'package:waylight_mobile/ui/widgets/common/compact_state_widget.dart';
import 'package:waylight_mobile/ui/widgets/common/simple_widget.dart';
import 'package:waylight_mobile/ui/widgets/common/widget_rows.dart';

/// The native view of the calendar widget (#117): the next events grouped
/// by day.
class CalendarWidget extends StatelessWidget {
  /// Creates the view for [widget].
  const CalendarWidget({required this.widget, this.now, super.key});

  /// The placement of the widget.
  final WidgetPlacement widget;

  /// The current time; tests pass a fixed one.
  final DateTime Function()? now;

  /// How many events are shown.
  static const shown = 8;

  /// The builder for the widget registry.
  /// Small and strip tiles show the server's compact state (#274).
  static Widget forPlacement(BuildContext context, WidgetPlacement widget) =>
      CompactStateWidget.orFull(
        context,
        widget,
        title: widget.title.isNotEmpty
            ? widget.title
            : context.l10n.calendarTitle,
        full: () => CalendarWidget(widget: widget, key: ValueKey(widget.id)),
      );

  @override
  Widget build(BuildContext context) => SimpleWidget<List<CalendarEvent>>(
    placement: widget,
    defaultTitle: context.l10n.calendarTitle,
    query: calendarQuery,
    compact: (context, events, size) {
      final l10n = context.l10n;
      final at = (now ?? DateTime.now)();
      final upcoming = events.where((e) => e.end.isAfter(at)).toList()
        ..sort((a, b) => a.start.compareTo(b.start));
      if (upcoming.isEmpty) {
        return Text(
          l10n.calendarEmpty,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        );
      }
      final first = upcoming.first;
      final time = DateFormat.Hm(
        Localizations.localeOf(context).toLanguageTag(),
      );
      final when = first.allDay
          ? l10n.calendarAllDay
          : time.format(first.start);
      if (size == WidgetSize.strip) return Text('$when · ${first.summary}');
      final today = DateTime(at.year, at.month, at.day);
      final day = DateTime(
        first.start.year,
        first.start.month,
        first.start.day,
      );
      final days = day.difference(today).inDays;
      final theme = Theme.of(context);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            days <= 1 && days >= 0
                ? daysText(context, days)
                : shortDate(context, day),
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            first.summary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall,
          ),
          Text(
            first.allDay
                ? l10n.calendarAllDay
                : '${time.format(first.start)}–${time.format(first.end)}',
            style: theme.textTheme.bodySmall,
          ),
          if (upcoming.length > 1)
            Text(
              l10n.calendarMore(upcoming.length - 1),
              style: theme.textTheme.bodySmall,
            ),
        ],
      );
    },
    builder: (context, events) {
      final l10n = context.l10n;
      final at = (now ?? DateTime.now)();
      final upcoming = events.where((e) => e.end.isAfter(at)).toList()
        ..sort((a, b) => a.start.compareTo(b.start));
      if (upcoming.isEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.calendarEmpty),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.push(Routes.calendar),
                child: Text(l10n.calendarShowAll),
              ),
            ),
          ],
        );
      }
      final today = DateTime(at.year, at.month, at.day);
      final time = DateFormat.Hm(
        Localizations.localeOf(context).toLanguageTag(),
      );
      // An event that starts a new day carries the heading of that day, so
      // a tile never ends on a heading alone.
      final days = <({CalendarEvent event, String? heading})>[];
      DateTime? lastDay;
      for (final e in upcoming.take(shown)) {
        final day = DateTime(e.start.year, e.start.month, e.start.day);
        String? heading;
        if (day != lastDay) {
          lastDay = day;
          final ahead = day.difference(today).inDays;
          heading = ahead <= 1 && ahead >= 0
              ? daysText(context, ahead)
              : shortDate(context, day);
        }
        days.add((event: e, heading: heading));
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TileRows(
            items: days,
            rowHeight: TileRows.twoLineRowHeight,
            rowBuilder: (context, entry) {
              final e = entry.event;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (entry.heading != null) ...[
                    const SizedBox(height: Dimens.gapTiny),
                    Text(
                      entry.heading!,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ],
                  InfoRow(
                    title: e.summary,
                    subtitle: [
                      if (e.location.isNotEmpty) e.location,
                      if (e.calendar.isNotEmpty) e.calendar,
                    ].join(' · '),
                    trailing: e.allDay
                        ? l10n.calendarAllDay
                        : '${time.format(e.start)}–${time.format(e.end)}',
                  ),
                ],
              );
            },
          ),
          if (!WidgetSizeScope.inGrid(context))
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.push(Routes.calendar),
                child: Text(l10n.calendarShowAll),
              ),
            ),
        ],
      );
    },
  );
}
