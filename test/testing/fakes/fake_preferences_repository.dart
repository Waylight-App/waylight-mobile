import 'package:waylight_mobile/data/repositories/preferences/preferences_repository.dart';
import 'package:waylight_mobile/domain/models/appearance.dart';
import 'package:waylight_mobile/utils/result.dart';

/// A [PreferencesRepository] in memory for tests.
class FakePreferencesRepository extends PreferencesRepository {
  @override
  Appearance appearance = const Appearance();

  @override
  Future<Result<void>> restore() async => const Result.ok(null);

  @override
  Future<Result<void>> setAppearance(Appearance appearance) async {
    this.appearance = appearance;
    notifyListeners();
    return const Result.ok(null);
  }
}
