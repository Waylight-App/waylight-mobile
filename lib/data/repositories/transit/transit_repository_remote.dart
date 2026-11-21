import 'package:waylight_mobile/data/repositories/transit/transit_repository.dart';
import 'package:waylight_mobile/data/services/api/transit_api.dart';
import 'package:waylight_mobile/domain/models/departure.dart';
import 'package:waylight_mobile/domain/models/place.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// A [TransitRepository] that asks the server every time.
class TransitRepositoryRemote implements TransitRepository {
  /// Creates the repository.
  const TransitRepositoryRemote({required this._api});

  final TransitApi _api;

  @override
  Future<Result<List<Departure>>> departures(
    ServerAddress server, {
    required String stop,
    required int count,
  }) => _api.departures(server, stop: stop, count: count);

  @override
  Future<Result<List<Stop>>> stops(ServerAddress server, String query) =>
      _api.stops(server, query);
}
