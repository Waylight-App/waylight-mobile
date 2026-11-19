import 'package:waylight_mobile/domain/models/departure.dart';
import 'package:waylight_mobile/domain/models/home_snapshot.dart';
import 'package:waylight_mobile/domain/models/todo.dart';
import 'package:waylight_mobile/l10n/generated/app_localizations.dart';

/// Formats the home screen widgets in the app's language (#42). Times are
/// absolute, so a card stays right while the phone shows it unchanged.
class HomeWidgetTexts implements HomeWidgetFormatter {
  /// Creates the formatter for [l10n].
  const HomeWidgetTexts(this.l10n);

  /// The texts in the app's language.
  final AppLocalizations l10n;

  /// 24-hour "HH:mm", as both languages write it. Formatted by hand because
  /// the background refresh runs without the app's date symbols.
  static String _time(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _footer(DateTime at) => l10n.homeWidgetUpdated(_time(at));

  @override
  HomeWidgetCard todos(List<Todo> today, DateTime at) => HomeWidgetCard(
    title: l10n.homeWidgetTodos,
    lines: [for (final t in today) t.overdue ? '! ${t.title}' : t.title],
    empty: l10n.homeWidgetTodosEmpty,
    footer: _footer(at),
    link: 'waylight://',
  );

  @override
  HomeWidgetCard departures(
    String stopName,
    List<Departure>? departures,
    DateTime at,
  ) => HomeWidgetCard(
    title: stopName.isEmpty ? l10n.homeWidgetDepartures : stopName,
    lines: [
      for (final d in departures ?? const <Departure>[])
        [
          _time(d.expected.toLocal()),
          d.line,
          d.headsign,
          if (d.cancelled)
            l10n.homeWidgetCancelled
          else if (d.delayMinutes > 0)
            '+${d.delayMinutes}',
        ].join(' '),
    ],
    empty: departures == null
        ? l10n.homeWidgetNoStop
        : l10n.homeWidgetNoDepartures,
    footer: _footer(at),
    link: 'waylight://',
  );
}
