import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:waylight_mobile/data/repositories/home_widgets/home_widgets_repository.dart';
import 'package:waylight_mobile/domain/models/home_snapshot.dart';
import 'package:waylight_mobile/ui/home_widgets/background_refresh.dart';

import '../../testing/fakes/fake_dashboard_repository.dart';
import '../../testing/fakes/fake_home_widget_store.dart';
import '../../testing/fakes/fake_preferences_repository.dart';
import '../../testing/fakes/fake_server_repository.dart';
import '../../testing/fakes/fake_session_repository.dart';
import '../../testing/fakes/fake_todos_repository.dart';
import '../../testing/fakes/fake_transit_repository.dart';

void main() {
  late FakeHomeWidgetStore store;

  Future<void> run({
    required bool signedIn,
    bool expired = false,
    Locale? locale,
  }) {
    store = FakeHomeWidgetStore()..scheduled = true;
    return refreshHomeWidgetsInBackground(
      server: FakeServerRepository(current: testServer()),
      session: FakeSessionRepository(signedIn: signedIn, expired: expired),
      preferences: FakePreferencesRepository(),
      homeWidgets: HomeWidgetsRepository(
        dashboard: FakeDashboardRepository(),
        todos: FakeTodosRepository(),
        transit: FakeTransitRepository(),
        store: store,
      ),
      systemLocale: locale ?? const Locale('de', 'DE'),
    );
  }

  test('signed in, it refreshes the cards in the system language', () async {
    await run(signedIn: true);
    expect(store.cards[HomeWidgetKind.todos]?.title, 'Aufgaben heute');
    expect(store.finishedCount, 1);
    expect(store.scheduled, isTrue);
  });

  test('an unsupported system language falls back to English', () async {
    await run(signedIn: true, locale: const Locale('fr'));
    expect(store.cards[HomeWidgetKind.todos]?.title, 'To-dos today');
  });

  test('signed out, it clears the cards and stops the schedule', () async {
    await run(signedIn: false);
    expect(store.cards, isEmpty);
    expect(store.scheduled, isFalse);
    expect(store.finishedCount, 1);
  });

  test('an expired session clears the cards', () async {
    await run(signedIn: true, expired: true);
    expect(store.cards, isEmpty);
    expect(store.scheduled, isFalse);
  });
}
