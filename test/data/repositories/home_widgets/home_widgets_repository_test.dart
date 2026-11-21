import 'package:flutter_test/flutter_test.dart';

import 'package:waylight_mobile/data/repositories/home_widgets/home_widgets_repository.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/compact_state.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/departure.dart';
import 'package:waylight_mobile/domain/models/home_snapshot.dart';
import 'package:waylight_mobile/domain/models/todo.dart';
import 'package:waylight_mobile/ui/home_widgets/home_widget_texts.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../../testing/fakes/fake_compact_state_repository.dart';
import '../../../testing/fakes/fake_dashboard_repository.dart';
import '../../../testing/fakes/fake_home_widget_store.dart';
import '../../../testing/fakes/fake_server_repository.dart';
import '../../../testing/fakes/fake_todos_repository.dart';
import '../../../testing/fakes/fake_transit_repository.dart';
import '../../../testing/pump_app.dart';

void main() {
  final now = DateTime(2026, 11, 20, 10, 42);
  late FakeTodosRepository todos;
  late FakeTransitRepository transit;
  late FakeDashboardRepository dashboard;
  late FakeHomeWidgetStore store;
  late DateTime clock;
  late HomeWidgetsRepository repo;
  final format = HomeWidgetTexts(l10nEn);

  const withStop = Dashboard(
    tabs: [
      DashboardTab(
        id: 't',
        name: 'Home',
        widgets: [
          WidgetPlacement(id: 'c', kind: 'clock'),
          WidgetPlacement(
            id: 'w',
            kind: 'transit',
            config: {'stopId': 'de:1', 'stopName': 'Main Station'},
          ),
        ],
      ),
    ],
  );

  setUp(() {
    clock = now;
    todos = FakeTodosRepository()
      ..result = Result.ok([
        Todo(id: '1', title: 'Pay rent', due: DateTime(2026, 11, 20, 18)),
        const Todo(id: '2', title: 'Old task', overdue: true),
        Todo(id: '3', title: 'Next week', due: DateTime(2026, 11, 27)),
        const Todo(id: '4', title: 'Someday'),
      ]);
    transit = FakeTransitRepository()
      ..result = Result.ok([
        Departure(
          line: 'S1',
          headsign: 'Airport',
          mode: TransitMode.suburban,
          planned: DateTime(2026, 11, 20, 10, 50),
          expected: DateTime(2026, 11, 20, 10, 52),
          delayMinutes: 2,
        ),
        Departure(
          line: '7',
          headsign: 'Zoo',
          mode: TransitMode.tram,
          planned: DateTime(2026, 11, 20, 10, 55),
          expected: DateTime(2026, 11, 20, 10, 55),
          cancelled: true,
        ),
      ]);
    dashboard = FakeDashboardRepository()..result = const Result.ok(withStop);
    store = FakeHomeWidgetStore();
    repo = HomeWidgetsRepository(
      dashboard: dashboard,
      todos: todos,
      transit: transit,
      store: store,
      clock: () => clock,
    );
  });

  test('stores to-dos due today and the next departures', () async {
    expect(await repo.refresh(testServer(), format: format), isA<Ok<void>>());

    final today = store.cards[HomeWidgetKind.todos]!;
    expect(today.title, 'To-dos today');
    expect(today.lines, ['Pay rent', '! Old task']);
    expect(today.footer, 'Updated 10:42');

    final departures = store.cards[HomeWidgetKind.departures]!;
    expect(transit.calls.single, ('de:1', HomeWidgetsRepository.maxLines));
    expect(departures.title, 'Main Station');
    expect(departures.lines, ['10:52 S1 Airport +2', '10:55 7 Zoo cancelled']);
    expect(departures.toJson()['link'], 'waylight://');
  });

  test('cards carry the compact state line and level (#242)', () async {
    final compact = FakeCompactStateRepository(kinds: {'todos'})
      ..result = const Result.ok(
        CompactState(
          title: CompactText(text: '2 open · 1 overdue'),
          level: CompactLevel.attention,
        ),
      );
    repo = HomeWidgetsRepository(
      dashboard: dashboard,
      todos: todos,
      transit: transit,
      store: store,
      compact: compact,
      clock: () => clock,
    );
    await repo.refresh(testServer(), format: format);

    final today = store.cards[HomeWidgetKind.todos]!.toJson();
    expect(compact.asked, ['todos']);
    expect(today['summary'], '2 open · 1 overdue');
    expect(today['level'], 'attention');

    // Derived from the departures already read, without another request.
    final departures = store.cards[HomeWidgetKind.departures]!;
    expect(transit.calls, hasLength(1));
    expect(departures.summary, 'S1 to Airport in 10 min');
    expect(departures.level, CompactLevel.attention);
  });

  test('without a compact state the cards have no summary', () async {
    await repo.refresh(testServer(), format: format);
    final today = store.cards[HomeWidgetKind.todos]!;
    expect(today.summary, isEmpty);
    expect(today.level, CompactLevel.none);
  });

  test('without a transit widget the card asks for one', () async {
    await repo.refresh(
      testServer(),
      format: format,
      dashboard: const Dashboard(tabs: []),
    );
    final card = store.cards[HomeWidgetKind.departures]!;
    expect(card.lines, isEmpty);
    expect(card.empty, l10nEn.homeWidgetNoStop);
    expect(transit.calls, isEmpty);
  });

  test('skips refreshes within five minutes unless forced', () async {
    await repo.refresh(testServer(), format: format);
    store.cards.clear();
    clock = now.add(const Duration(minutes: 2));
    await repo.refresh(testServer(), format: format);
    expect(store.cards, isEmpty);
    await repo.refresh(testServer(), format: format, force: true);
    expect(store.cards, hasLength(2));
  });

  test('keeps the older cards when nothing loads', () async {
    const failure = Result<Never>.error(ApiException(ApiFailure.unreachable));
    todos.result = failure;
    dashboard.result = failure;
    final result = await repo.refresh(testServer(), format: format);
    expect(result, isA<Error<void>>());
    expect(store.cards, isEmpty);
  });

  test('clearing removes the cards and stops the schedule', () async {
    await repo.schedule();
    expect(store.scheduled, isTrue);
    await repo.refresh(testServer(), format: format);
    await repo.clear();
    expect(store.cards, isEmpty);
    expect(store.scheduled, isFalse);
  });
}
