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

  /// The JSON the native widget reads.
  Map<String, Object?> toJson() => {
    'title': title,
    'lines': lines,
    'empty': empty,
    'footer': footer,
    'link': link,
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
  /// The card of open to-dos due today or overdue, loaded at [at].
  HomeWidgetCard todos(List<Todo> today, DateTime at);

  /// The card of the next [departures] at [stopName]; `null` departures
  /// mean no transit widget with a stop is on the dashboard.
  HomeWidgetCard departures(
    String stopName,
    List<Departure>? departures,
    DateTime at,
  );
}
