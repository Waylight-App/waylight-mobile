import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/domain/models/weather.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The weather module of the server (#63).
abstract interface class WeatherRepository {
  /// The weather at [lat]/[lon] from [server].
  Future<Result<Weather>> weather(
    ServerAddress server, {
    required double lat,
    required double lon,
  });
}
