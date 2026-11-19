import 'package:flutter_test/flutter_test.dart';

import 'package:waylight_mobile/data/repositories/preferences/preferences_repository_local.dart';
import 'package:waylight_mobile/domain/models/appearance.dart';

import '../../../testing/fakes/in_memory_key_value_store.dart';

void main() {
  test('stores the appearance and restores it after a restart', () async {
    final store = InMemoryKeyValueStore();
    final first = PreferencesRepositoryLocal(store: store);
    var notified = 0;
    first.addListener(() => notified++);

    await first.setAppearance(
      const Appearance(theme: ThemeChoice.dark, language: AppLanguage.de),
    );
    expect(notified, 1);

    final second = PreferencesRepositoryLocal(store: store);
    await second.restore();
    expect(
      second.appearance,
      const Appearance(theme: ThemeChoice.dark, language: AppLanguage.de),
    );
  });

  test('falls back to the system for unknown values', () async {
    final store = InMemoryKeyValueStore()
      ..values[PreferencesRepositoryLocal.themeKey] = 'purple';
    final repository = PreferencesRepositoryLocal(store: store);

    await repository.restore();

    expect(repository.appearance, const Appearance());
  });
}
