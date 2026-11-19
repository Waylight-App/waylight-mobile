import 'package:waylight_mobile/data/services/api/api_client.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/departure.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The departures endpoint of the server (`api/modules/transit.yaml`).
class TransitApi {
  /// Creates the service on top of an [ApiClient].
  const TransitApi(this._client);

  final ApiClient _client;

  /// Reads the next [count] departures at [stop].
  Future<Result<List<Departure>>> departures(
    ServerAddress server, {
    required String stop,
    required int count,
  }) async {
    final uri = server
        .resolve('/api/transit/departures')
        .replace(queryParameters: {'stop': stop, 'n': '$count'});
    final result = await _client.getJson(uri);
    switch (result) {
      case Ok(:final value):
        final departures = parseDepartures(value);
        return departures == null
            ? const Result.error(ApiException(ApiFailure.server))
            : Result.ok(departures);
      case Error(:final error):
        return Result.error(error);
    }
  }
}

/// Maps the JSON of `GET /api/transit/departures`; `null` if it does not
/// match.
List<Departure>? parseDepartures(Object? json) {
  if (json is! List<Object?>) return null;
  final departures = <Departure>[];
  for (final item in json) {
    if (item case {
      'line': final String line,
      'headsign': final String headsign,
      'planned': final String planned,
    }) {
      final plannedAt = DateTime.tryParse(planned);
      if (plannedAt == null) return null;
      departures.add(
        Departure(
          line: line,
          headsign: headsign,
          mode: TransitMode.fromName(switch (item['mode']) {
            final String m => m,
            _ => '',
          }),
          planned: plannedAt.toLocal(),
          expected:
              (switch (item['expected']) {
                        final String e => DateTime.tryParse(e),
                        _ => null,
                      } ??
                      plannedAt)
                  .toLocal(),
          delayMinutes: switch (item['delayMinutes']) {
            final int d => d,
            _ => 0,
          },
          track: switch (item['track']) {
            final String t => t,
            _ => '',
          },
          cancelled: item['cancelled'] == true,
        ),
      );
    } else {
      return null;
    }
  }
  return departures;
}
