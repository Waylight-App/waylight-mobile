import 'package:flutter_test/flutter_test.dart';

import 'package:waylight_mobile/data/repositories/todos/todos_repository_outbox.dart';
import 'package:waylight_mobile/data/services/api/offline_status.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/outbox.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/domain/models/todo.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../../testing/fakes/fake_server_repository.dart';
import '../../../testing/fakes/fake_todos_repository.dart';
import '../../../testing/fakes/in_memory_key_value_store.dart';

/// Answers each update with the next of its errors, then like the fake.
class _Sequence extends FakeTodosRepository {
  _Sequence(this.errors);

  final List<Exception> errors;
  int updates = 0;

  @override
  Future<Result<Todo>> update(
    ServerAddress server,
    Todo todo, {
    String source = '',
  }) async {
    updates++;
    if (errors.isEmpty) return super.update(server, todo, source: source);
    return Result.error(errors.removeAt(0));
  }
}

void main() {
  late FakeTodosRepository remote;
  late InMemoryKeyValueStore store;
  late OfflineStatus offline;

  TodosRepositoryOutbox create([FakeTodosRepository? over]) =>
      TodosRepositoryOutbox(
        remote: over ?? remote,
        store: store,
        offline: offline,
        server: testServer,
      );

  const unreachable = ApiException(ApiFailure.unreachable);

  setUp(() {
    remote = FakeTodosRepository();
    store = InMemoryKeyValueStore();
    offline = OfflineStatus();
  });

  test(
    'keeps offline changes, survives a restart and replays them in order',
    () async {
      final outbox = create();
      remote.failWith = unreachable;

      final created = await outbox.create(testServer(), title: 'Milk');
      await outbox.update(
        testServer(),
        const Todo(id: 'b', title: 'Bread', version: 2),
      );
      expect(
        created,
        isA<Ok<Todo>>(),
        reason: 'the change is accepted locally',
      );
      expect(outbox.outbox.isPending((created as Ok<Todo>).value), isTrue);

      outbox.dispose(); // the app is closed
      final restarted = create();
      await restarted.restore();
      remote.failWith = null;
      offline
        ..servedStored(DateTime(2026))
        ..reachedServer();
      await Future<void>.delayed(Duration.zero);

      expect(remote.writes, ['create Milk', 'update b']);
      expect(
        store.values[TodosRepositoryOutbox.storageKey],
        contains('"queue":[]'),
      );
    },
  );

  test('stops at the first change that cannot be delivered', () async {
    final outbox = create();
    remote.failWith = unreachable;
    final one = await outbox.create(testServer(), title: 'One');
    await outbox.create(testServer(), title: 'Two');

    await outbox.flush();

    expect(remote.writes, isEmpty);
    expect(outbox.outbox.isPending((one as Ok<Todo>).value), isTrue);
  });

  test('keeps a change made elsewhere as a conflict to decide', () async {
    final outbox = create();
    remote.failWith = unreachable;
    await outbox.update(
      testServer(),
      const Todo(id: 'b', title: 'Mine', version: 2),
    );

    remote
      ..failWith = const ApiException(ApiFailure.conflict)
      ..result = const Result.ok([Todo(id: 'b', title: 'Theirs', version: 7)]);
    await outbox.flush();

    final conflict = outbox.outbox.conflicts.single;
    expect(conflict.kind, ConflictKind.changed);
    expect(conflict.serverVersion, 7);

    remote.failWith = null;
    await outbox.keepMine(conflict.change.key);
    expect(outbox.outbox.conflicts, isEmpty);
    expect(remote.writes, ['update b']);
  });

  test(
    'drops changes of to-dos deleted elsewhere and lists rejected ones',
    () async {
      remote.failWith = unreachable;
      final first = create();
      await first.update(testServer(), const Todo(id: 'gone', title: 'x'));
      await first.update(testServer(), const Todo(id: 'bad', title: 'y'));

      final sequence = _Sequence([
        const ApiException(ApiFailure.notFound),
        const ApiException(ApiFailure.invalid, message: 'Title too long'),
      ]);
      final replay = create(sequence);
      await replay.restore();
      await replay.flush();

      expect(sequence.updates, 2);
      expect(replay.outbox.conflicts.single.kind, ConflictKind.rejected);
      expect(replay.outbox.conflicts.single.message, 'Title too long');
    },
  );

  test('clearing deletes the outbox', () async {
    final outbox = create();
    remote.failWith = unreachable;
    await outbox.create(testServer(), title: 'Milk');

    await outbox.clear();

    expect(store.values.containsKey(TodosRepositoryOutbox.storageKey), isFalse);
  });
}
