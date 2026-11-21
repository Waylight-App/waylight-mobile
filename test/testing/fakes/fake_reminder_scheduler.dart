import 'package:waylight_mobile/data/services/reminders/reminder_scheduler.dart';
import 'package:waylight_mobile/domain/models/reminder.dart';

/// A [ReminderScheduler] for tests that keeps what would be scheduled.
class FakeReminderScheduler implements ReminderScheduler {
  /// What is scheduled now.
  List<Reminder> scheduled = [];

  /// How often the whole list was replaced.
  int replaced = 0;

  /// What [requestPermission] answers.
  bool permission = true;

  @override
  Future<void> replaceAll(List<Reminder> reminders) async {
    replaced++;
    scheduled = List.of(reminders);
  }

  @override
  Future<void> cancelAll() async => scheduled = [];

  @override
  Future<bool> requestPermission() async => permission;
}
