import 'package:waylight_mobile/data/repositories/places/places_repository.dart';
import 'package:waylight_mobile/domain/models/place.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// A [PlacesRepository] that answers with [result].
class FakePlacesRepository implements PlacesRepository {
  /// Creates the fake.
  FakePlacesRepository({this.canLocate = true, Result<Place>? result})
    : result =
          result ??
          const Result.ok(
            Place(id: 'p1', name: 'My location', lat: 52.37, lon: 9.73),
          );

  @override
  bool canLocate;

  /// What [useMyLocation] answers.
  Result<Place> result;

  /// The names asked for.
  final List<String> asked = [];

  @override
  Future<Result<Place>> useMyLocation(ServerAddress server, String name) async {
    asked.add(name);
    return result;
  }
}
