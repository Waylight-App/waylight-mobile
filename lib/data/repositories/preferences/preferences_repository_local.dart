import 'package:logging/logging.dart';

import 'package:waylight_mobile/data/repositories/preferences/preferences_repository.dart';
import 'package:waylight_mobile/data/services/storage/key_value_store.dart';
import 'package:waylight_mobile/domain/models/appearance.dart';
import 'package:waylight_mobile/utils/result.dart';

/// A [PreferencesRepository] in the device's [KeyValueStore].
class PreferencesRepositoryLocal extends PreferencesRepository {
  /// Creates the repository.
  PreferencesRepositoryLocal({required this._store});

  /// The keys of the stored values.
  static const themeKey = 'preferences.theme';

  /// See [themeKey].
  static const languageKey = 'preferences.language';

  final KeyValueStore _store;
  final Logger _log = Logger('PreferencesRepository');
  Appearance _appearance = const Appearance();

  @override
  Appearance get appearance => _appearance;

  @override
  Future<Result<void>> restore() async {
    try {
      _appearance = Appearance(
        theme:
            _byName(ThemeChoice.values, await _store.read(themeKey)) ??
            ThemeChoice.system,
        language:
            _byName(AppLanguage.values, await _store.read(languageKey)) ??
            AppLanguage.system,
      );
      notifyListeners();
      return const Result.ok(null);
    } on Exception catch (e) {
      _log.warning('Could not read the stored preferences.', e);
      return Result.error(e);
    }
  }

  @override
  Future<Result<void>> setAppearance(Appearance appearance) async {
    _appearance = appearance;
    notifyListeners();
    try {
      await _store.write(themeKey, appearance.theme.name);
      await _store.write(languageKey, appearance.language.name);
      return const Result.ok(null);
    } on Exception catch (e) {
      _log.warning('Could not store the preferences.', e);
      return Result.error(e);
    }
  }

  static T? _byName<T extends Enum>(List<T> values, String? name) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return null;
  }
}
