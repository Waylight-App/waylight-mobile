import 'package:waylight_mobile/domain/models/departure.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The transit module of the server (#49).
abstract interface class TransitRepository {
  /// The next [count] departures at [stop] on [server].
  Future<Result<List<Departure>>> departures(
    ServerAddress server, {
    required String stop,
    required int count,
  });
}
