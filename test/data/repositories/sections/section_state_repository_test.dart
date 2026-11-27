import 'package:flutter_test/flutter_test.dart';

import 'package:waylight_mobile/data/repositories/sections/section_state_repository.dart';

import '../../../testing/fakes/fake_server_repository.dart';
import '../../../testing/fakes/in_memory_key_value_store.dart';

void main() {
  late InMemoryKeyValueStore store;

  setUp(() => store = InMemoryKeyValueStore());

  test('keeps the state per server, tab and section across starts', () async {
    final other = testServer('https://other.example');
    final repo = SectionStateRepository(store: store);
    var notified = 0;
    repo.addListener(() => notified++);

    await repo.setCollapsed(testServer(), 't', 'server', collapsed: true);
    await repo.setCollapsed(testServer(), 't', 'server', collapsed: true);

    expect(notified, 1, reason: 'collapsing twice changes nothing');
    final restarted = SectionStateRepository(store: store);
    await restarted.restore();
    expect(restarted.isCollapsed(testServer(), 't', 'server'), isTrue);
    expect(restarted.isCollapsed(testServer(), 't', 'everyday'), isFalse);
    expect(restarted.isCollapsed(testServer(), 'u', 'server'), isFalse);
    expect(restarted.isCollapsed(other, 't', 'server'), isFalse);

    await restarted.setCollapsed(testServer(), 't', 'server', collapsed: false);
    final again = SectionStateRepository(store: store);
    await again.restore();
    expect(again.isCollapsed(testServer(), 't', 'server'), isFalse);
  });

  test('opens every section when the stored state cannot be read', () async {
    await store.write(SectionStateRepository.storageKey, 'not json');
    final repo = SectionStateRepository(store: store);

    await repo.restore();

    expect(repo.isCollapsed(testServer(), 't', 'server'), isFalse);
  });
}
