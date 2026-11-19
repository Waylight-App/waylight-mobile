import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/ui/core/localization.dart';

export 'package:waylight_mobile/ui/core/widgets/rows.dart';

/// "Today", "Tomorrow" or "in N days".
String daysText(BuildContext context, int days) => switch (days) {
  0 => context.l10n.todosToday,
  1 => context.l10n.todosTomorrow,
  _ => context.l10n.wasteInDays(days),
};

/// A date as "Mon, 23 Nov" in the app's language.
String shortDate(BuildContext context, DateTime date) =>
    DateFormat.MMMEd(Localizations.localeOf(context).toLanguageTag())
        .format(date);

/// Bytes as "1.2 TB".
String formatBytes(int bytes) {
  const units = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1000 && unit < units.length - 1) {
    value /= 1000;
    unit++;
  }
  return '${value.toStringAsFixed(value >= 10 || unit == 0 ? 0 : 1)} ${units[unit]}';
}
