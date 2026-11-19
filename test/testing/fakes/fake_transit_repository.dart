import 'package:waylight_mobile/data/repositories/transit/transit_repository.dart';
import 'package:waylight_mobile/domain/models/departure.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// A [TransitRepository] without network for tests.
class FakeTransitRepository implements TransitRepository {
  /// What [departures] returns; an empty list by default.
  Result<List<Departure>> result = const Result.ok([]);

  /// The arguments of every call.
  final List<(String, int)> calls = [];

  @override
  Future<Result<List<Departure>>> departures(
    ServerAddress server, {
    required String stop,
    required int count,
  }) async {
    calls.add((stop, count));
    return result;
  }
}
