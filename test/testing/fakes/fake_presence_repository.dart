import 'package:waylight_mobile/data/repositories/presence/presence_repository.dart';
import 'package:waylight_mobile/domain/models/presence.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// A [PresenceRepository] in memory.
class FakePresenceRepository implements PresenceRepository {
  /// What [board] returns.
  Result<PresenceBoard> result = const Result.ok(
    PresenceBoard(people: [], counts: {}),
  );

  /// What [setMine] returns.
  Result<void> setResult = const Result.ok(null);

  /// The statuses set, with their day of return.
  final List<(PresenceStatus, DateTime?)> set = [];

  @override
  Future<Result<PresenceBoard>> board(
    ServerAddress server, {
    String group = '',
  }) async => result;

  @override
  Future<Result<void>> setMine(
    ServerAddress server,
    PresenceStatus status, {
    DateTime? returnOn,
  }) async {
    set.add((status, returnOn));
    return setResult;
  }
}
