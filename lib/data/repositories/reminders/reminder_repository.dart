import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import 'package:waylight_mobile/data/repositories/reminders/reminder_planner.dart';
import 'package:waylight_mobile/data/repositories/todos/todos_repository.dart';
import 'package:waylight_mobile/data/repositories/widget_data/queries/everyday.dart';
import 'package:waylight_mobile/data/repositories/widget_data/queries/information.dart';
import 'package:waylight_mobile/data/repositories/widget_data/widget_data_repository.dart';
import 'package:waylight_mobile/data/services/reminders/reminder_scheduler.dart';
import 'package:waylight_mobile/data/services/storage/key_value_store.dart';
import 'package:waylight_mobile/domain/models/everyday.dart';
import 'package:waylight_mobile/domain/models/information.dart';
import 'package:waylight_mobile/domain/models/reminder.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/domain/models/todo.dart';
import 'package:waylight_mobile/utils/result.dart';

/// Reminders on the device (#190): the person's choice, and a schedule
/// made again from the data the app loads anyway.
class ReminderRepository extends ChangeNotifier {
  /// Creates the repository.
  ReminderRepository({
    required this._scheduler,
    required this._store,
    required this._todos,
    required this._data,
    DateTime Function()? now,
    this.minInterval = const Duration(minutes: 15),
  }) : _now = now ?? DateTime.now;

  final ReminderScheduler _scheduler;
  final KeyValueStore _store;
  final TodosRepository _todos;
  final WidgetDataRepository _data;
  final DateTime Function() _now;
  final Logger _log = Logger('ReminderRepository');

  /// How often a dashboard load reschedules at most.
  final Duration minInterval;

  static const _todosKey = 'reminders.todos';
  static const _eventsKey = 'reminders.eventMinutes';
  static const _birthdaysKey = 'reminders.birthdays';

  ReminderSettings _settings = const ReminderSettings();
  DateTime? _last;
  ServerAddress? _lastServer;

  /// The current choice.
  ReminderSettings get settings => _settings;

  /// Reads the stored choice; call once at start.
  Future<void> restore() async {
    _settings = ReminderSettings(
      todos: await _store.read(_todosKey) == '1',
      eventMinutes: int.tryParse(await _store.read(_eventsKey) ?? '') ?? 0,
      birthdays: await _store.read(_birthdaysKey) == '1',
    );
    notifyListeners();
  }

  /// Stores [settings]. Turning the first kind on asks for the notification
  /// permission; `false` when it was refused (nothing is changed then).
  Future<bool> update(ReminderSettings settings) async {
    if (settings.any &&
        !_settings.any &&
        !await _scheduler.requestPermission()) {
      return false;
    }
    await _store.write(_todosKey, settings.todos ? '1' : '0');
    await _store.write(_eventsKey, '${settings.eventMinutes}');
    await _store.write(_birthdaysKey, settings.birthdays ? '1' : '0');
    _settings = settings;
    _last = null;
    notifyListeners();
    if (!settings.any) await _scheduler.cancelAll();
    return true;
  }

  /// Plans the reminders for [server] from its current data and replaces
  /// the scheduled ones. Skipped within [minInterval] of the last run for
  /// the same server unless [force]. When any data cannot be loaded (no
  /// network), the reminders already scheduled stay as they are, so they
  /// still fire offline.
  Future<void> reschedule(
    ServerAddress server,
    ReminderFormatter format, {
    bool force = false,
  }) async {
    if (!_settings.any) return;
    final now = _now();
    final last = _last;
    if (!force &&
        server == _lastServer &&
        last != null &&
        now.difference(last) < minInterval) {
      return;
    }
    _last = now;
    _lastServer = server;
    final s = _settings;
    final todos = s.todos
        ? await _todos.todos(server)
        : const Result<List<Todo>>.ok([]);
    final events = s.eventMinutes > 0
        ? await _data.read(server, calendarQuery)
        : const Result<List<CalendarEvent>>.ok([]);
    final birthdays = s.birthdays
        ? await _data.read(server, birthdaysQuery)
        : const Result<List<Birthday>>.ok([]);
    if (todos is Error || events is Error || birthdays is Error) {
      _log.info('Keeping the scheduled reminders: data not available.');
      _last = null;
      return;
    }
    final plan = planReminders(
      now: now,
      settings: s,
      format: format,
      todos: _valueOr(todos),
      events: _valueOr(events),
      birthdays: _valueOr(birthdays),
    );
    try {
      await _scheduler.replaceAll(plan);
    } on Exception catch (e) {
      _log.warning('Could not schedule reminders.', e);
    }
  }

  /// Cancels every reminder, e.g. on sign-out or when the server is
  /// forgotten. The choice stays on the device.
  Future<void> clear() async {
    _last = null;
    _lastServer = null;
    await _scheduler.cancelAll();
  }

  static List<T> _valueOr<T>(Result<List<T>> r) => switch (r) {
    Ok(:final value) => value,
    Error() => const [],
  };
}
