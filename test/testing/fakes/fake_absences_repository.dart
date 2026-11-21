import 'package:waylight_mobile/data/repositories/absences/absences_repository.dart';
import 'package:waylight_mobile/domain/models/absence.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// An [AbsencesRepository] in memory.
class FakeAbsencesRepository implements AbsencesRepository {
  /// What [list] returns.
  Result<List<Absence>> result = const Result.ok([]);

  /// What the changes return.
  Result<void> changeResult = const Result.ok(null);

  /// The changes, such as `create:holiday` or `delete:a1`.
  final List<String> calls = [];

  @override
  Future<Result<List<Absence>>> list(
    ServerAddress server, {
    required DateTime from,
    required DateTime to,
  }) async => result;

  @override
  Future<Result<void>> create(ServerAddress server, AbsenceInput input) async {
    calls.add('create:${input.kind.name}');
    return changeResult;
  }

  @override
  Future<Result<void>> update(
    ServerAddress server,
    String id,
    AbsenceInput input,
  ) async {
    calls.add('update:$id');
    return changeResult;
  }

  @override
  Future<Result<void>> delete(ServerAddress server, String id) async {
    calls.add('delete:$id');
    return changeResult;
  }
}
