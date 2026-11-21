import 'package:waylight_mobile/domain/models/everyday.dart';
import 'package:waylight_mobile/domain/models/information.dart';
import 'package:waylight_mobile/domain/models/reminder.dart';
import 'package:waylight_mobile/domain/models/todo.dart';
import 'package:waylight_mobile/l10n/generated/app_localizations.dart';

/// The words of the reminders on the device in the app's language (#190).
class ReminderTexts implements ReminderFormatter {
  /// Creates the formatter for [l10n].
  const ReminderTexts(this.l10n);

  /// The texts in the app's language.
  final AppLocalizations l10n;

  // Formatted by hand: the background refresh runs without date symbols.
  static String _time(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  (String, String) todo(Todo todo) => (todo.title, l10n.reminderTodoBody);

  @override
  (String, String) event(CalendarEvent event, int minutes) {
    final where = event.location.isEmpty ? '' : ' · ${event.location}';
    return (
      event.summary,
      minutes == 0
          ? '${l10n.reminderEventAllDay}$where'
          : '${l10n.reminderEventAt(_time(event.start), minutes)}$where',
    );
  }

  @override
  (String, String) birthday(Birthday birthday) => (
    l10n.reminderBirthdayTitle(birthday.name),
    switch (birthday.age) {
      final age? => l10n.reminderBirthdayAge(age),
      null => l10n.reminderBirthdayBody,
    },
  );
}
