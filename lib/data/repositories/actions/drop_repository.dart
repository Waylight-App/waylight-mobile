import 'package:waylight_mobile/data/repositories/widget_data/queries/media.dart';
import 'package:waylight_mobile/data/services/api/module_api.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/media.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The drop zone of the server (#105): move texts and links between
/// devices.
abstract interface class DropRepository {
  /// The items, newest first.
  Future<Result<List<Drop>>> drops(ServerAddress server);

  /// Drops [text] for [hours] hours (1, 24 or 168).
  Future<Result<Drop>> sendText(
    ServerAddress server,
    String text, {
    int hours = 24,
  });

  /// Deletes an item.
  Future<Result<void>> remove(ServerAddress server, String id);
}

/// A [DropRepository] on `/api/drop`.
class DropRepositoryRemote implements DropRepository {
  /// Creates the repository.
  const DropRepositoryRemote({required this._api});

  final ModuleApi _api;

  @override
  Future<Result<List<Drop>>> drops(ServerAddress server) =>
      _api.read(server, '/api/drop', parseDrops);

  @override
  Future<Result<Drop>> sendText(
    ServerAddress server,
    String text, {
    int hours = 24,
  }) async => switch (await _api.post(
    server,
    '/api/drop/text',
    body: {'text': text, 'expiresInHours': hours},
  )) {
    Ok(:final value) => switch (parseDrops([value])) {
      [final d] => Result.ok(d),
      _ => const Result.error(ApiException(ApiFailure.server)),
    },
    Error(:final error) => Result.error(error),
  };

  @override
  Future<Result<void>> remove(ServerAddress server, String id) =>
      _api.delete(server, '/api/drop/${Uri.encodeComponent(id)}');
}
