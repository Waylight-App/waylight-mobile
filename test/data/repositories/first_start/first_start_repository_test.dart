import 'package:flutter_test/flutter_test.dart';
import 'package:waylight_mobile/data/repositories/first_start/first_start_repository.dart';

import '../../../testing/fakes/fake_server_repository.dart';
import '../../../testing/fakes/in_memory_key_value_store.dart';

void main() {
  final home = testServer();
  final other = testServer('https://other.example.org');

  test('remembers the finished first start per server', () async {
    final store = InMemoryKeyValueStore();
    final repository = FirstStartRepository(store: store);
    await repository.restore();
    expect(repository.isDone(home), isFalse);

    await repository.markDone(home);
    expect(repository.isDone(home), isTrue);
    expect(repository.isDone(other), isFalse);

    final restored = FirstStartRepository(store: store);
    await restored.restore();
    expect(restored.isDone(home), isTrue);
    expect(restored.isDone(other), isFalse);
  });

  test('counts a session from before the first start as done', () async {
    final store = InMemoryKeyValueStore();
    final repository = FirstStartRepository(store: store);
    await repository.restore(signedInOn: home);
    expect(repository.isDone(home), isTrue);

    // Only once: afterwards the stored list decides.
    final later = FirstStartRepository(store: store);
    await later.restore(signedInOn: other);
    expect(later.isDone(other), isFalse);
  });

  test('does not trap the person when the stored list is broken', () async {
    final store = InMemoryKeyValueStore()
      ..values[FirstStartRepository.doneKey] = '{broken';
    final repository = FirstStartRepository(store: store);
    await repository.restore(signedInOn: home);
    expect(repository.isDone(home), isTrue);
  });

  test('notifies when a server is done', () async {
    final repository = FirstStartRepository(store: InMemoryKeyValueStore());
    var calls = 0;
    repository.addListener(() => calls++);
    await repository.markDone(home);
    await repository.markDone(home);
    expect(calls, 1);
  });
}
