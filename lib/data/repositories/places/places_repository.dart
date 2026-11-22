import 'package:waylight_mobile/data/services/api/module_api.dart';
import 'package:waylight_mobile/data/services/location/device_location.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/place.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The places saved on the server (`/api/places`) and the phone's own
/// position as one of them (#295).
abstract interface class PlacesRepository {
  /// Whether the phone can tell its position.
  bool get canLocate;

  /// Reads the coarse position, rounds it to about 100 m and saves it as a
  /// place called [name]; a place already saved at that spot is reused.
  /// Call it from a tap: it asks for the location permission.
  Future<Result<Place>> useMyLocation(ServerAddress server, String name);
}

/// A [PlacesRepository] on the server's places module.
class PlacesRepositoryRemote implements PlacesRepository {
  /// Creates the repository.
  const PlacesRepositoryRemote({required this._api, required this._location});

  final ModuleApi _api;
  final DeviceLocation _location;

  /// Three decimals are about 100 m, the same as the web interface.
  static const decimals = 3;

  @override
  bool get canLocate => _location.available;

  @override
  Future<Result<Place>> useMyLocation(ServerAddress server, String name) async {
    final Coordinates position;
    switch (await _location.coarse()) {
      case Ok(:final value):
        position = value;
      case Error(:final error):
        return Result.error(error);
    }
    final rounded = _round(position);

    final saved = await _api.read(server, '/api/places', parseSavedPlaces);
    if (saved case Ok(:final value)) {
      for (final place in value) {
        if (place.lat == rounded.lat && place.lon == rounded.lon) {
          return Result.ok(place);
        }
      }
    }
    final created = await _api.post(
      server,
      '/api/places',
      body: {'name': name, 'lat': rounded.lat, 'lon': rounded.lon},
    );
    return switch (created) {
      Ok(:final value) => switch (_place(value)) {
        final place? => Result.ok(place),
        null => const Result.error(ApiException(ApiFailure.server)),
      },
      Error(:final error) => Result.error(error),
    };
  }

  static Coordinates _round(Coordinates c) => (
    lat: double.parse(c.lat.toStringAsFixed(decimals)),
    lon: double.parse(c.lon.toStringAsFixed(decimals)),
  );
}

/// Maps `GET /api/places` (the saved places); `null` for an answer of another shape.
List<Place>? parseSavedPlaces(Object? json) => switch (json) {
  final List<Object?> list => [for (final p in list) ?_place(p)],
  _ => null,
};

Place? _place(Object? json) {
  if (json case {
    'id': final String id,
    'name': final String name,
    'lat': final num lat,
    'lon': final num lon,
  }) {
    return Place(id: id, name: name, lat: lat.toDouble(), lon: lon.toDouble());
  }
  return null;
}
