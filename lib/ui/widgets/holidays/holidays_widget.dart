import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/data/repositories/widget_data/queries/everyday.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/everyday.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/widgets/compact_lines.dart';
import 'package:waylight_mobile/ui/core/widgets/tile_rows.dart';
import 'package:waylight_mobile/ui/widgets/common/simple_widget.dart';
import 'package:waylight_mobile/ui/widgets/common/widget_rows.dart';

/// The native view of the holidays widget (#129).
class HolidaysWidget extends StatelessWidget {
  /// Creates the view for [widget].
  const HolidaysWidget({required this.widget, super.key});

  /// The placement of the widget.
  final WidgetPlacement widget;

  /// The builder for the widget registry.
  static Widget forPlacement(BuildContext context, WidgetPlacement widget) =>
      HolidaysWidget(widget: widget, key: ValueKey(widget.id));

  @override
  Widget build(BuildContext context) => SimpleWidget<List<Holiday>>(
    placement: widget,
    defaultTitle: context.l10n.holidaysTitle,
    query: holidaysQuery,
    interval: const Duration(hours: 6),
    compact: (context, holidays, size) {
      final l10n = context.l10n;
      final next = holidays.firstOrNull;
      if (next == null) return Text(l10n.holidaysEmpty);
      return CompactLines(
        headline: next.school ? next.name : holidayName(l10n, next.key),
        detail: next.current
            ? l10n.holidaysNow
            : daysText(context, next.daysUntil),
        size: size,
      );
    },
    builder: (context, holidays) {
      final l10n = context.l10n;
      if (holidays.isEmpty) return Text(l10n.holidaysEmpty);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TileRows(
            items: holidays.take(6).toList(),
            rowHeight: TileRows.twoLineRowHeight,
            rowBuilder: (context, h) => InfoRow(
              leading: Text(h.school ? '🎒' : '📅', semanticsLabel: ''),
              title: h.school ? h.name : holidayName(l10n, h.key),
              subtitle: h.start == h.end
                  ? shortDate(context, h.start)
                  : '${shortDate(context, h.start)} – ${shortDate(context, h.end)}',
              trailing: h.current
                  ? l10n.holidaysNow
                  : daysText(context, h.daysUntil),
            ),
          ),
        ],
      );
    },
  );
}

/// The name of a public holiday by its key; unknown keys are shown as
/// they are, so a holiday added on the server still appears.
String holidayName(AppLocalizations l10n, String key) => switch (key) {
  'new_year' => l10n.holidayNewYear,
  'epiphany' => l10n.holidayEpiphany,
  'womens_day' => l10n.holidayWomensDay,
  'good_friday' => l10n.holidayGoodFriday,
  'easter_sunday' => l10n.holidayEasterSunday,
  'easter_monday' => l10n.holidayEasterMonday,
  'labour_day' => l10n.holidayLabourDay,
  'ascension' => l10n.holidayAscension,
  'whit_sunday' => l10n.holidayWhitSunday,
  'whit_monday' => l10n.holidayWhitMonday,
  'corpus_christi' => l10n.holidayCorpusChristi,
  'assumption' => l10n.holidayAssumption,
  'childrens_day' => l10n.holidayChildrensDay,
  'german_unity' => l10n.holidayGermanUnity,
  'reformation' => l10n.holidayReformation,
  'all_saints' => l10n.holidayAllSaints,
  'repentance' => l10n.holidayRepentance,
  'christmas_day' => l10n.holidayChristmasDay,
  'boxing_day' => l10n.holidayBoxingDay,
  _ => key,
};
