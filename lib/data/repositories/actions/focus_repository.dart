import 'package:waylight_mobile/data/services/api/module_api.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// Saves finished focus sessions on the server (#123).
abstract interface class FocusRepository {
  /// Saves a session of [minutes] that ended at [endedAt].
  Future<Result<void>> save(
    ServerAddress server, {
    required int minutes,
    required DateTime endedAt,
  });
}

/// A [FocusRepository] on `/api/focus/sessions`.
class FocusRepositoryRemote implements FocusRepository {
  /// Creates the repository.
  const FocusRepositoryRemote({required this._api});

  final ModuleApi _api;

  @override
  Future<Result<void>> save(
    ServerAddress server, {
    required int minutes,
    required DateTime endedAt,
  }) async => switch (await _api.post(
    server,
    '/api/focus/sessions',
    body: {'minutes': minutes, 'endedAt': endedAt.toUtc().toIso8601String()},
  )) {
    Ok() => const Result.ok(null),
    Error(:final error) => Result.error(error),
  };
}
