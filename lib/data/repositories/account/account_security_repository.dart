import 'package:waylight_mobile/data/repositories/widget_data/queries/json.dart';
import 'package:waylight_mobile/data/services/api/module_api.dart';
import 'package:waylight_mobile/domain/models/account_security.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// Password, two-factor sign-in and sessions of the account (#110).
abstract interface class AccountSecurityRepository {
  /// The active sessions; the app's own one is marked.
  Future<Result<List<AccountSession>>> sessions(ServerAddress server);

  /// Signs out one session.
  Future<Result<void>> revoke(ServerAddress server, String id);

  /// Signs out every session but the current one.
  Future<Result<void>> revokeOthers(ServerAddress server);

  /// Changes the password; the server signs out every other session.
  Future<Result<void>> changePassword(
    ServerAddress server, {
    required String current,
    required String next,
  });

  /// Whether two-factor sign-in is on.
  Future<Result<bool>> totpEnabled(ServerAddress server);

  /// Starts connecting an authenticator app.
  Future<Result<TotpSetup>> startTotp(ServerAddress server);

  /// Confirms with a code and returns the one-time recovery codes.
  Future<Result<List<String>>> confirmTotp(ServerAddress server, String code);

  /// Turns two-factor sign-in off.
  Future<Result<void>> disableTotp(
    ServerAddress server, {
    required String password,
    required String code,
  });
}

/// An [AccountSecurityRepository] on `/api/auth`.
class AccountSecurityRepositoryRemote implements AccountSecurityRepository {
  /// Creates the repository.
  const AccountSecurityRepositoryRemote({required this._api});

  final ModuleApi _api;

  static Result<void> _done(Result<Object?> r) => switch (r) {
    Ok() => const Result.ok(null),
    Error(:final error) => Result.error(error),
  };

  @override
  Future<Result<List<AccountSession>>> sessions(ServerAddress server) =>
      _api.read(server, '/api/auth/sessions', parseSessions);

  @override
  Future<Result<void>> revoke(ServerAddress server, String id) =>
      _api.delete(server, '/api/auth/sessions/${Uri.encodeComponent(id)}');

  @override
  Future<Result<void>> revokeOthers(ServerAddress server) async =>
      _done(await _api.post(server, '/api/auth/sessions/revoke-others'));

  @override
  Future<Result<void>> changePassword(
    ServerAddress server, {
    required String current,
    required String next,
  }) async => _done(
    await _api.put(
      server,
      '/api/auth/password',
      body: {'currentPassword': current, 'newPassword': next},
    ),
  );

  @override
  Future<Result<bool>> totpEnabled(ServerAddress server) => _api.read(
    server,
    '/api/auth/totp',
    (json) => switch (json) {
      {'enabled': final bool e} => e,
      _ => null,
    },
  );

  @override
  Future<Result<TotpSetup>> startTotp(ServerAddress server) async =>
      switch (await _api.post(server, '/api/auth/totp/setup')) {
        Ok(value: {'secret': final String secret, 'uri': final String uri}) =>
          Result.ok(TotpSetup(secret: secret, uri: Uri.parse(uri))),
        Ok() => const Result.error(ApiException(ApiFailure.server)),
        Error(:final error) => Result.error(error),
      };

  @override
  Future<Result<List<String>>> confirmTotp(
    ServerAddress server,
    String code,
  ) async => switch (await _api.post(
    server,
    '/api/auth/totp/confirm',
    body: {'code': code},
  )) {
    Ok(value: {'codes': final List<Object?> codes}) => Result.ok([
      for (final c in codes)
        if (c is String) c,
    ]),
    Ok() => const Result.error(ApiException(ApiFailure.server)),
    Error(:final error) => Result.error(error),
  };

  @override
  Future<Result<void>> disableTotp(
    ServerAddress server, {
    required String password,
    required String code,
  }) async => _done(
    await _api.post(
      server,
      '/api/auth/totp/disable',
      body: {'password': password, 'code': code},
    ),
  );
}

/// Maps `GET /api/auth/sessions`.
List<AccountSession>? parseSessions(Object? json) =>
    listOf<AccountSession>(json, (s) {
      if (s case {'id': final String id}) {
        String text(Object? v) => v is String ? v : '';
        return AccountSession(
          id: id,
          device: text(s['device']),
          userAgent: text(s['userAgent']),
          clientIp: text(s['clientIp']),
          lastSeenAt: asDateTime(s['lastSeenAt'])?.toLocal() ?? DateTime(1970),
          current: s['current'] == true,
        );
      }
      return null;
    });
