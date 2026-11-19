import 'package:flutter_test/flutter_test.dart';

import 'package:waylight_mobile/domain/models/outbox.dart';
import 'package:waylight_mobile/domain/models/todo.dart';

PendingChange change(
  String key,
  OutboxOp op,
  String id, {
  String title = '',
  int base = 0,
}) => PendingChange(
  key: key,
  op: op,
  todo: Todo(id: id, title: title),
  baseVersion: base,
);

void main() {
  test('merges changes of the same to-do like the web app', () {
    var s = const OutboxState();
    s = enqueue(s, change('1', OutboxOp.create, 'a', title: 'Milk'));
    s = enqueue(s, change('2', OutboxOp.update, 'a', title: 'Oat milk'));
    expect(s.queue.single.op, OutboxOp.create);
    expect(s.queue.single.todo.title, 'Oat milk');

    s = enqueue(s, change('3', OutboxOp.delete, 'a'));
    expect(s.queue, isEmpty, reason: 'create + delete leaves nothing');

    s = enqueue(s, change('4', OutboxOp.update, 'b', title: 'x', base: 3));
    s = enqueue(s, change('5', OutboxOp.delete, 'b'));
    expect(s.queue.single.op, OutboxOp.delete);
    expect(s.queue.single.baseVersion, 3);
  });

  test('settles results and resolves conflicts', () {
    var s = OutboxState(
      queue: [
        change('1', OutboxOp.update, 'a', base: 2),
        change('2', OutboxOp.update, 'b'),
      ],
    );

    expect(settle(s, const ReplayOffline()).queue, hasLength(2));
    s = settle(s, const ReplayChanged(5));
    expect(s.queue.single.key, '2');
    expect(s.conflicts.single.serverVersion, 5);

    final mine = keepMineChange(s, '1');
    expect(mine.conflicts, isEmpty);
    expect(mine.queue.last.baseVersion, 5);

    expect(discard(s, '1').conflicts, isEmpty);
    expect(
      settle(s, const ReplayRejected('too long')).conflicts.last.kind,
      ConflictKind.rejected,
    );
  });

  test('shows waiting changes on top of a loaded list', () {
    final s = OutboxState(
      queue: [
        change('1', OutboxOp.create, 'new', title: 'New'),
        change('2', OutboxOp.update, 'a', title: 'Changed'),
        change('3', OutboxOp.delete, 'b'),
      ],
    );
    final list = overlay(
      const [Todo(id: 'a', title: 'Old'), Todo(id: 'b', title: 'Gone')],
      s,
      '',
    );

    expect(list.map((t) => t.title), ['Changed', 'New']);
  });
}
