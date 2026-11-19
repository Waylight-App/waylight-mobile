import 'package:waylight_mobile/data/services/api/api_client.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/domain/models/waste_collection.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The waste calendar endpoint of the server (`api/modules/waste.yaml`).
class WasteApi {
  /// Creates the service on top of an [ApiClient].
  const WasteApi(this._client);

  final ApiClient _client;

  /// Reads `GET /api/waste/upcoming`; fails with `ApiFailure.notFound`
  /// while no waste calendar is set up.
  Future<Result<List<WasteCollection>>> upcoming(ServerAddress server) async {
    final result = await _client.getJson(server.resolve('/api/waste/upcoming'));
    switch (result) {
      case Ok(:final value):
        final collections = parseWaste(value);
        return collections == null
            ? const Result.error(ApiException(ApiFailure.server))
            : Result.ok(collections);
      case Error(:final error):
        return Result.error(error);
    }
  }
}

/// Maps the JSON of `GET /api/waste/upcoming`; `null` if it does not match.
List<WasteCollection>? parseWaste(Object? json) {
  if (json case {'types': final List<Object?> types}) {
    final collections = <WasteCollection>[];
    for (final type in types) {
      if (type case {
        'label': final String label,
        'dates': final List<Object?> dates,
        'daysUntil': final int daysUntil,
      }) {
        collections.add(
          WasteCollection(
            label: label,
            daysUntil: daysUntil,
            icon: switch (type['icon']) {
              final String i => i,
              _ => '',
            },
            dates: [
              for (final d in dates)
                if (d is String) ?DateTime.tryParse(d),
            ],
          ),
        );
      } else {
        return null;
      }
    }
    return collections;
  }
  return null;
}
