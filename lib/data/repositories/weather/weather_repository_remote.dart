import 'package:waylight_mobile/data/repositories/weather/weather_repository.dart';
import 'package:waylight_mobile/data/services/api/weather_api.dart';
import 'package:waylight_mobile/domain/models/place.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/domain/models/weather.dart';
import 'package:waylight_mobile/utils/result.dart';

/// A [WeatherRepository] that asks the server every time; the server
/// caches the weather service itself.
class WeatherRepositoryRemote implements WeatherRepository {
  /// Creates the repository.
  const WeatherRepositoryRemote({required this._api});

  final WeatherApi _api;

  @override
  Future<Result<Weather>> weather(
    ServerAddress server, {
    required double lat,
    required double lon,
  }) => _api.weather(server, lat: lat, lon: lon);

  @override
  Future<Result<List<Place>>> places(ServerAddress server, String query) =>
      _api.places(server, query);
}
