import 'package:waylight_mobile/domain/models/everyday.dart';
import 'package:waylight_mobile/domain/models/information.dart';
import 'package:waylight_mobile/domain/models/todo.dart';

/// What a reminder on the device is about (#190).
enum ReminderKind {
  /// A to-do due that day.
  todo,

  /// A calendar event starting soon.
  event,

  /// Someone's birthday.
  birthday,
}

/// A notification the phone shows by itself at [at] (#190), without the
/// server or the network.
final class Reminder {
  /// Creates the reminder.
  const Reminder({
    required this.id,
    required this.at,
    required this.kind,
    required this.title,
    required this.body,
    required this.link,
  });

  /// Stable for the same item, so a rescheduled reminder replaces its
  /// notification instead of adding a second one.
  final int id;

  /// When it is shown.
  final DateTime at;

  /// What it is about; each kind has its own Android notification channel.
  final ReminderKind kind;

  /// The notification's title.
  final String title;

  /// The notification's text.
  final String body;

  /// The app link opened on a tap, e.g. `waylight://calendar`.
  final String link;

  @override
  bool operator ==(Object other) =>
      other is Reminder &&
      other.id == id &&
      other.at == at &&
      other.kind == kind &&
      other.title == title &&
      other.body == body &&
      other.link == link;

  @override
  int get hashCode => Object.hash(id, at, kind, title, body, link);

  @override
  String toString() => 'Reminder($kind, $at, $title)';
}

/// Which reminders the person wants; all off by default (#190).
final class ReminderSettings {
  /// Creates the settings.
  const ReminderSettings({
    this.todos = false,
    this.eventMinutes = 0,
    this.birthdays = false,
  });

  /// The lead times offered for events, in minutes.
  static const eventChoices = [5, 15, 30, 60];

  /// Remind of to-dos on the morning of their due day.
  final bool todos;

  /// Minutes before an event starts; 0 means off.
  final int eventMinutes;

  /// Remind of birthdays on the morning of the day.
  final bool birthdays;

  /// Whether any kind is on.
  bool get any => todos || eventMinutes > 0 || birthdays;

  /// A copy with the given values replaced.
  ReminderSettings copyWith({
    bool? todos,
    int? eventMinutes,
    bool? birthdays,
  }) => ReminderSettings(
    todos: todos ?? this.todos,
    eventMinutes: eventMinutes ?? this.eventMinutes,
    birthdays: birthdays ?? this.birthdays,
  );

  @override
  bool operator ==(Object other) =>
      other is ReminderSettings &&
      other.todos == todos &&
      other.eventMinutes == eventMinutes &&
      other.birthdays == birthdays;

  @override
  int get hashCode => Object.hash(todos, eventMinutes, birthdays);
}

/// The words of the reminders, in the app's language; the UI layer
/// implements it, so planning needs no `BuildContext`.
abstract interface class ReminderFormatter {
  /// Title and text for a to-do due today.
  (String, String) todo(Todo todo);

  /// Title and text for an event starting in [minutes] (all-day: 0).
  (String, String) event(CalendarEvent event, int minutes);

  /// Title and text for a birthday today.
  (String, String) birthday(Birthday birthday);
}
