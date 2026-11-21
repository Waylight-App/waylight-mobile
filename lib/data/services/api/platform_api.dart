import 'package:waylight_mobile/data/services/api/api_client.dart';
import 'package:waylight_mobile/data/services/api/models/auth_status_api_model.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The public endpoints every Waylight server offers before sign-in.
class PlatformApi {
  /// Creates the service on top of an [ApiClient].
  const PlatformApi(this._client);

  final ApiClient _client;

  /// Reads `GET /api/auth/status` of [server].
  ///
  /// Fails with `ApiFailure.server` if the answer is not the JSON of a
  /// Waylight server, for example a router page or a reverse proxy error.
  Future<Result<AuthStatusApiModel>> authStatus(ServerAddress server) async {
    final result = await _client.getJson(server.resolve('/api/auth/status'));
    switch (result) {
      case Ok(:final value):
        final status = AuthStatusApiModel.fromJson(value);
        return status == null
            ? const Result.error(ApiException(ApiFailure.server))
            : Result.ok(status);
      case Error(:final error):
        return Result.error(error);
    }
  }

  /// Asks [via], another address of [server], for `GET /api/auth/status`
  /// with [server]'s session (#189). Any HTTP error, or an answer that is
  /// not Waylight's, counts as not reachable.
  Future<Result<AuthStatusApiModel>> probeAuthStatus(
    ServerAddress server, {
    required ServerAddress via,
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final result = await _client.probe(
      server.resolve('/api/auth/status'),
      via: via.resolve('/api/auth/status'),
      timeout: timeout,
    );
    return switch (result) {
      Ok(:final value) when value.statusCode == 200 =>
        switch (AuthStatusApiModel.fromJson(value.body)) {
          final status? => Result.ok(status),
          null => const Result.error(ApiException(ApiFailure.server)),
        },
      Ok() => const Result.error(ApiException(ApiFailure.server)),
      Error(:final error) => Result.error(error),
    };
  }

  /// Reads the running version from `GET /api/system/version`; accounts
  /// that may not see it get an error.
  Future<Result<String>> version(ServerAddress server) async {
    final result = await _client.getJson(server.resolve('/api/system/version'));
    return switch (result) {
      Ok(value: {'current': final String current}) => Result.ok(current),
      Ok() => const Result.error(ApiException(ApiFailure.server)),
      Error(:final error) => Result.error(error),
    };
  }
}
