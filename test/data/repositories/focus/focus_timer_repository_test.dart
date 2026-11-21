import 'package:flutter_test/flutter_test.dart';
import 'package:waylight_mobile/data/repositories/focus/focus_timer_repository.dart';
import 'package:waylight_mobile/data/services/focus/focus_timer_service.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/focus_timer.dart';

import '../../../testing/fakes/fake_action_repositories.dart';
import '../../../testing/fakes/fake_server_repository.dart';
import '../../../testing/fakes/in_memory_key_value_store.dart';

/// The focus timer in the background (#191), with a fake clock.
void main() {
  late DateTime now;
  late FakeFocusRepository sessions;
  late InMemoryKeyValueStore store;
  late int asked;

  FocusTimerRepository repository() => FocusTimerRepository(
    timer: InAppFocusTimer(now: () => now),
    sessions: sessions,
    store: store,
    askPermission: () async {
      asked++;
      return true;
    },
  );

  setUp(() {
    now = DateTime(2026, 11, 21, 9);
    sessions = FakeFocusRepository();
    store = InMemoryKeyValueStore();
    asked = 0;
  });

  test('a focus phase ends, is recorded once; breaks are not', () async {
    final repo = repository();
    await repo.start(FocusPhase.focus);
    expect(repo.state?.left(now), FocusTimerRepository.focusLength);
    now = now.add(const Duration(minutes: 26));
    await repo.refresh(testServer());
    expect(repo.state, isNull);
    expect(sessions.calls, ['save:25']);
    await repo.refresh(testServer());
    expect(sessions.calls, ['save:25']);

    await repo.start(FocusPhase.rest);
    now = now.add(const Duration(minutes: 6));
    await repo.refresh(testServer());
    expect(sessions.calls, ['save:25']);
  });

  test('pause keeps the time left; stop records nothing', () async {
    final repo = repository();
    await repo.start(FocusPhase.focus);
    now = now.add(const Duration(minutes: 5));
    await repo.pause();
    now = now.add(const Duration(hours: 1));
    expect(repo.state?.left(now), const Duration(minutes: 20));
    await repo.resume();
    now = now.add(const Duration(minutes: 10));
    expect(repo.state?.left(now), const Duration(minutes: 10));
    await repo.stop();
    now = now.add(const Duration(hours: 1));
    await repo.refresh(testServer());
    expect(sessions.calls, isEmpty);
  });

  test('offline phases wait in a queue and are sent later', () async {
    final repo = repository();
    sessions.fail = const ApiException(ApiFailure.unreachable);
    await repo.start(FocusPhase.focus);
    now = now.add(const Duration(minutes: 30));
    await repo.refresh(testServer());
    expect(store.values['focus.unsent'], contains('"minutes":25'));

    sessions.fail = null;
    await repo.refresh(testServer());
    expect(sessions.calls.where((c) => c == 'save:25'), hasLength(2));
    expect(store.values.containsKey('focus.unsent'), isFalse);
  });

  test(
    'asks for the notification permission on the first start only',
    () async {
      final repo = repository();
      await repo.start(FocusPhase.focus);
      await repo.start(FocusPhase.rest);
      expect(asked, 1);
    },
  );
}
