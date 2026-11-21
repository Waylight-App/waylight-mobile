import 'package:waylight_mobile/domain/models/everyday.dart';
import 'package:waylight_mobile/domain/models/information.dart';
import 'package:waylight_mobile/domain/models/reminder.dart';
import 'package:waylight_mobile/domain/models/todo.dart';

/// The hour of the morning reminders (to-dos, birthdays, all-day events).
const reminderMorningHour = 8;

/// How far ahead reminders are scheduled; the next refresh extends it.
const reminderHorizon = Duration(days: 7);

/// The most reminders scheduled at once; Android limits alarms per app.
const maxReminders = 64;

/// Decides what to remind of and when (#190). Pure: the same input gives
/// the same list, so it is tested with a fixed [now].
List<Reminder> planReminders({
  required DateTime now,
  required ReminderSettings settings,
  required ReminderFormatter format,
  List<Todo> todos = const [],
  List<CalendarEvent> events = const [],
  List<Birthday> birthdays = const [],
}) {
  final end = now.add(reminderHorizon);
  final out = <Reminder>[];
  void add(
    String key,
    DateTime at,
    ReminderKind kind,
    (String, String) text,
    String link,
  ) {
    if (!at.isAfter(now) || at.isAfter(end)) return;
    out.add(
      Reminder(
        id: reminderId(key),
        at: at,
        kind: kind,
        title: text.$1,
        body: text.$2,
        link: link,
      ),
    );
  }

  if (settings.todos) {
    for (final t in todos) {
      final due = t.due;
      if (t.done || due == null) continue;
      add(
        'todo:${t.id}',
        _morning(due),
        ReminderKind.todo,
        format.todo(t),
        'waylight://',
      );
    }
  }
  final minutes = settings.eventMinutes;
  if (minutes > 0) {
    for (final e in events) {
      final at = e.allDay
          ? _morning(e.start)
          : e.start.subtract(Duration(minutes: minutes));
      add(
        'event:${e.calendar}:${e.summary}:${e.start.toIso8601String()}',
        at,
        ReminderKind.event,
        format.event(e, e.allDay ? 0 : minutes),
        'waylight://calendar',
      );
    }
  }
  if (settings.birthdays) {
    for (final b in birthdays) {
      add(
        'birthday:${b.name}:${b.next.month}-${b.next.day}',
        _morning(b.next),
        ReminderKind.birthday,
        format.birthday(b),
        'waylight://',
      );
    }
  }
  out.sort((a, b) => a.at.compareTo(b.at));
  return out.length > maxReminders ? out.sublist(0, maxReminders) : out;
}

DateTime _morning(DateTime day) =>
    DateTime(day.year, day.month, day.day, reminderMorningHour);

/// A stable, positive 31-bit id for [key] (FNV-1a), the same on every run,
/// unlike `String.hashCode`.
int reminderId(String key) {
  var hash = 0x811c9dc5;
  for (final unit in key.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash & 0x7fffffff;
}
