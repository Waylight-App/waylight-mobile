import 'package:flutter_test/flutter_test.dart';
import 'package:waylight_mobile/data/repositories/reminders/reminder_planner.dart';
import 'package:waylight_mobile/data/repositories/reminders/reminder_repository.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/everyday.dart';
import 'package:waylight_mobile/domain/models/information.dart';
import 'package:waylight_mobile/domain/models/reminder.dart';
import 'package:waylight_mobile/domain/models/todo.dart';
import 'package:waylight_mobile/l10n/generated/app_localizations_en.dart';
import 'package:waylight_mobile/ui/core/reminder_texts.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../../testing/fakes/fake_reminder_scheduler.dart';
import '../../../testing/fakes/fake_server_repository.dart';
import '../../../testing/fakes/fake_todos_repository.dart';
import '../../../testing/fakes/fake_widget_data_repository.dart';
import '../../../testing/fakes/in_memory_key_value_store.dart';

/// Reminders on the device (#190), with a fixed clock: Friday 20 Nov 2026,
/// 10:00 local time.
void main() {
  final now = DateTime(2026, 11, 20, 10);
  final texts = ReminderTexts(AppLocalizationsEn());
  const all = ReminderSettings(todos: true, eventMinutes: 15, birthdays: true);

  List<Reminder> plan(
    ReminderSettings settings, {
    List<Todo> todos = const [],
    List<CalendarEvent> events = const [],
    List<Birthday> birthdays = const [],
  }) => planReminders(
    now: now,
    settings: settings,
    format: texts,
    todos: todos,
    events: events,
    birthdays: birthdays,
  );

  group('planReminders', () {
    test('to-dos on the morning of their due day, open ones only', () {
      final got = plan(
        all,
        todos: [
          Todo(id: 'a', title: 'Tax return', due: DateTime(2026, 11, 21)),
          Todo(id: 'b', title: 'Done', due: DateTime(2026, 11, 21), done: true),
          const Todo(id: 'c', title: 'No date'),
          // Due today: 8:00 has passed, nothing is shown late.
          Todo(id: 'd', title: 'Today', due: DateTime(2026, 11, 20)),
        ],
      );
      expect(got, hasLength(1));
      expect(got.single.at, DateTime(2026, 11, 21, 8));
      expect(got.single.kind, ReminderKind.todo);
      expect((got.single.title, got.single.body), ('Tax return', 'Due today'));
    });

    test('events the chosen time before, all-day ones in the morning', () {
      final got = plan(
        all,
        events: [
          CalendarEvent(
            summary: 'Dentist',
            start: DateTime(2026, 11, 20, 10, 30),
            end: DateTime(2026, 11, 20, 11),
            location: 'Main St',
          ),
          CalendarEvent(
            summary: 'Holiday',
            start: DateTime(2026, 11, 22),
            end: DateTime(2026, 11, 23),
            allDay: true,
          ),
          // Starts in 10 minutes: its reminder time has passed.
          CalendarEvent(
            summary: 'Call',
            start: DateTime(2026, 11, 20, 10, 10),
            end: DateTime(2026, 11, 20, 10, 20),
          ),
        ],
      );
      expect(got.map((r) => r.at), [
        DateTime(2026, 11, 20, 10, 15),
        DateTime(2026, 11, 22, 8),
      ]);
      expect(got.first.body, 'At 10:30, in 15 min · Main St');
      expect(got.first.link, 'waylight://calendar');
      expect(got.last.body, 'All day today');
    });

    test('birthdays in the morning, with the age when known', () {
      final got = plan(
        all,
        birthdays: [
          Birthday(
            name: 'Grandpa',
            next: DateTime(2026, 11, 23),
            inDays: 3,
            age: 80,
          ),
          Birthday(name: 'Far away', next: DateTime(2027, 2), inDays: 73),
        ],
      );
      expect(got.single.at, DateTime(2026, 11, 23, 8));
      expect(got.single.title, "Grandpa's birthday");
      expect(got.single.body, 'Turns 80 today');
    });

    test('kinds that are off plan nothing; ids are stable', () {
      final todo = Todo(id: 'a', title: 'x', due: DateTime(2026, 11, 21));
      expect(plan(const ReminderSettings(), todos: [todo]), isEmpty);
      expect(
        plan(all, todos: [todo]).single.id,
        plan(all, todos: [todo]).single.id,
      );
      expect(reminderId('todo:a'), isNot(reminderId('todo:b')));
      expect(reminderId('todo:a'), greaterThanOrEqualTo(0));
    });

    test('keeps at most maxReminders, the earliest first', () {
      final todos = [
        for (var i = 0; i < 100; i++)
          Todo(id: '$i', title: '$i', due: DateTime(2026, 11, 21 + i % 6)),
      ];
      final got = plan(all, todos: todos);
      expect(got, hasLength(maxReminders));
      expect(got.first.at.isAfter(got.last.at), isFalse);
    });
  });

  group('ReminderRepository', () {
    late FakeReminderScheduler scheduler;
    late FakeTodosRepository todos;
    late FakeWidgetDataRepository data;
    late InMemoryKeyValueStore store;
    late DateTime clock;

    ReminderRepository repository() => ReminderRepository(
      scheduler: scheduler,
      store: store,
      todos: todos,
      data: data,
      now: () => clock,
    );

    setUp(() {
      scheduler = FakeReminderScheduler();
      todos = FakeTodosRepository()
        ..result = Result.ok([
          Todo(id: 'a', title: 'Tax', due: DateTime(2026, 11, 21)),
        ]);
      data = FakeWidgetDataRepository()
        ..json['/api/calendar/events'] = <Object?>[]
        ..json['/api/birthdays'] = <Object?>[];
      store = InMemoryKeyValueStore();
      clock = now;
    });

    test('all off by default; nothing is scheduled', () async {
      final repo = repository();
      await repo.restore();
      expect(repo.settings, const ReminderSettings());
      await repo.reschedule(testServer(), texts);
      expect(scheduler.replaced, 0);
    });

    test('a refused permission changes nothing', () async {
      scheduler.permission = false;
      final repo = repository();
      expect(await repo.update(const ReminderSettings(todos: true)), isFalse);
      expect(repo.settings.todos, isFalse);
    });

    test('schedules, limits reloads and keeps the choice', () async {
      final repo = repository();
      expect(await repo.update(const ReminderSettings(todos: true)), isTrue);
      await repo.reschedule(testServer(), texts);
      expect(scheduler.scheduled.single.title, 'Tax');
      await repo.reschedule(testServer(), texts);
      expect(scheduler.replaced, 1, reason: 'within the interval');
      clock = clock.add(const Duration(minutes: 16));
      await repo.reschedule(testServer(), texts);
      expect(scheduler.replaced, 2);

      final restored = repository();
      await restored.restore();
      expect(restored.settings.todos, isTrue);
    });

    test('offline: the scheduled reminders stay', () async {
      final repo = repository();
      await repo.update(const ReminderSettings(todos: true));
      await repo.reschedule(testServer(), texts);
      todos.result = const Result.error(ApiException(ApiFailure.unreachable));
      await repo.reschedule(testServer(), texts, force: true);
      expect(scheduler.scheduled, hasLength(1));
    });

    test('turning everything off and signing out cancel all', () async {
      final repo = repository();
      await repo.update(const ReminderSettings(todos: true));
      await repo.reschedule(testServer(), texts);
      await repo.update(const ReminderSettings());
      expect(scheduler.scheduled, isEmpty);

      await repo.update(const ReminderSettings(todos: true));
      await repo.reschedule(testServer(), texts, force: true);
      await repo.clear();
      expect(scheduler.scheduled, isEmpty);
      expect(repo.settings.todos, isTrue, reason: 'the choice stays');
    });
  });
}
