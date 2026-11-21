import 'package:waylight_mobile/domain/models/compact_state.dart';
import 'package:waylight_mobile/domain/models/departure.dart';
import 'package:waylight_mobile/domain/models/todo.dart';

/// What one home screen widget shows (#42), already formatted in the app's
/// language, so the native widget only draws text. It holds no credentials.
final class HomeWidgetCard {
  /// Creates the card.
  const HomeWidgetCard({
    required this.title,
    required this.lines,
    required this.empty,
    required this.footer,
    required this.link,
    this.summary = '',
    this.level = CompactLevel.none,
  });

  /// The heading, e.g. "To-dos today".
  final String title;

  /// One line per entry.
  final List<String> lines;

  /// Shown instead of [lines] when there are none.
  final String empty;

  /// The age of the data, e.g. "Updated 10:42".
  final String footer;

  /// The app link opened on a tap, e.g. `waylight://`.
  final String link;

  /// The title line of the widget's compact state (#242), e.g.
  /// "3 open · 1 overdue"; empty when there is none.
  final String summary;

  /// How much the compact state needs attention; the native widget colours
  /// [summary] for [CompactLevel.attention] and [CompactLevel.problem].
  final CompactLevel level;

  /// The JSON the native widget reads.
  Map<String, Object?> toJson() => {
    'title': title,
    'lines': lines,
    'empty': empty,
    'footer': footer,
    'link': link,
    'summary': summary,
    'level': level.name,
  };
}

/// The home screen widgets the app keeps up to date.
enum HomeWidgetKind {
  /// Open to-dos due today or overdue.
  todos,

  /// The next departures at the stop of the first transit widget.
  departures,
}

/// Turns the data of the home screen widgets into cards in the app's
/// language; the UI layer implements it.
abstract interface class HomeWidgetFormatter {
  /// The card of open to-dos due today or overdue, loaded at [at];
  /// [compact] is the to-dos' compact state when the server offers one.
  HomeWidgetCard todos(List<Todo> today, DateTime at, {CompactState? compact});

  /// The card of the next [departures] at [stopName]; `null` departures
  /// mean no transit widget with a stop is on the dashboard. [compact] is
  /// the state derived from [departures].
  HomeWidgetCard departures(
    String stopName,
    List<Departure>? departures,
    DateTime at, {
    CompactState? compact,
  });
}
