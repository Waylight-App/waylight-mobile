import 'package:waylight_mobile/data/services/api/api_client.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/domain/models/session.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The answer of `POST /api/auth/login`.
sealed class LoginResponse {
  const LoginResponse();
}

/// The server started a session.
final class LoginSession extends LoginResponse {
  /// Creates the response.
  const LoginSession(this.session);

  /// The new session.
  final Session session;
}

/// The account needs a second factor; repeat the login with a code.
final class LoginNeedsCode extends LoginResponse {
  /// Creates the response.
  const LoginNeedsCode({required this.authenticatorApp});

  /// Whether a code of the authenticator app is accepted; otherwise only a
  /// recovery code.
  final bool authenticatorApp;
}

/// The sign-in endpoints of the server (`api/modules/auth.yaml`).
class AuthApi {
  /// Creates the service on top of an [ApiClient].
  const AuthApi(this._client);

  final ApiClient _client;

  // The browser cookie of the server: waylight_session, or with the
  // __Host- prefix when COOKIE_SECURE is on.
  static final _sessionCookie = RegExp(
    r'(?:^|[,\s])((?:__Host-)?waylight_session)=([^;,\s]+)',
  );

  /// Signs in on [server]; [username] is empty for the owner, [code] is the
  /// TOTP or recovery code of a second step.
  Future<Result<LoginResponse>> login(
    ServerAddress server, {
    required String username,
    required String password,
    String code = '',
  }) async {
    final result = await _client.postJsonResponse(
      server.resolve('/api/auth/login'),
      body: {
        if (username.isNotEmpty) 'username': username,
        'password': password,
        if (code.isNotEmpty) 'code': code,
      },
    );
    switch (result) {
      case Ok(value: final response):
        return _parse(server, response);
      // Accounts with an authenticator app but no passkey get a validation
      // error for the missing code instead of a second step.
      case Error(
        error: ApiException(failure: ApiFailure.invalid, field: 'totpCode'),
      ):
        return const Result.ok(LoginNeedsCode(authenticatorApp: true));
      case Error(:final error):
        return Result.error(error);
    }
  }

  static Result<LoginResponse> _parse(ServerAddress server, ApiResponse res) {
    // 202: a second factor is needed (passkeys, optionally TOTP as well).
    if (res.statusCode == 202) {
      final totp = switch (res.body) {
        {'secondFactor': {'totp': final bool totp}} => totp,
        _ => false,
      };
      return Result.ok(LoginNeedsCode(authenticatorApp: totp));
    }
    final csrf = switch (res.body) {
      {'csrfToken': final String token} when token.isNotEmpty => token,
      _ => null,
    };
    final cookie = _sessionCookie.firstMatch(res.headers['set-cookie'] ?? '');
    if (csrf == null || cookie == null) {
      return const Result.error(ApiException(ApiFailure.server));
    }
    return Result.ok(
      LoginSession(
        BrowserSession(
          server: server,
          cookie: '${cookie.group(1)}=${cookie.group(2)}',
          csrfToken: csrf,
        ),
      ),
    );
  }

  /// Creates an app session (`POST /api/auth/app-sessions`, server #559)
  /// for [device]. Servers without app sessions answer with
  /// `ApiFailure.notFound`; then [login] is the way in.
  Future<Result<LoginResponse>> createAppSession(
    ServerAddress server, {
    required String device,
    required String username,
    required String password,
    String code = '',
  }) async {
    final result = await _client.postJsonResponse(
      server.resolve('/api/auth/app-sessions'),
      body: {
        'device': device,
        if (username.isNotEmpty) 'username': username,
        'password': password,
        if (code.isNotEmpty) 'code': code,
      },
    );
    switch (result) {
      case Ok(value: final response) when response.statusCode == 202:
        return _parse(server, response);
      case Ok(value: ApiResponse(body: {'token': final String token}))
          when token.isNotEmpty:
        return Result.ok(
          LoginSession(AppSession(server: server, token: token)),
        );
      case Ok():
        return const Result.error(ApiException(ApiFailure.server));
      case Error(
        error: ApiException(failure: ApiFailure.invalid, field: 'totpCode'),
      ):
        return const Result.ok(LoginNeedsCode(authenticatorApp: true));
      case Error(:final error):
        return Result.error(error);
    }
  }

  /// Ends the session the client currently sends (`POST /api/auth/logout`).
  Future<Result<void>> logout(ServerAddress server) async =>
      switch (await _client.postJson(server.resolve('/api/auth/logout'))) {
        Ok() => const Result.ok(null),
        Error(:final error) => Result.error(error),
      };
}
