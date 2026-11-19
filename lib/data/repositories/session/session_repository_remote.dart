import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:waylight_mobile/data/repositories/session/session_repository.dart';
import 'package:waylight_mobile/data/services/api/api_credentials.dart';
import 'package:waylight_mobile/data/services/api/auth_api.dart';
import 'package:waylight_mobile/data/services/auth/pkce.dart';
import 'package:waylight_mobile/data/services/cache/response_cache.dart';
import 'package:waylight_mobile/data/services/storage/key_value_store.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/domain/models/session.dart';
import 'package:waylight_mobile/domain/models/sign_in_result.dart';
import 'package:waylight_mobile/utils/result.dart';

/// A [SessionRepository] that signs in over the network, keeps the session
/// in the secure [KeyValueStore] and hands it to the [ApiCredentials] of the
/// API client.
class SessionRepositoryRemote extends SessionRepository {
  /// Creates the repository.
  SessionRepositoryRemote({
    required this._authApi,
    required this._credentials,
    required this._store,
    required this.deviceName,
    this._cache,
    this._onForget = const [],
  }) {
    _credentials.onRejected = _onRejected;
  }

  /// The key under which the session is stored.
  static const storageKey = 'session';

  /// The name the server lists app sessions of this device under.
  final String deviceName;

  final AuthApi _authApi;
  final ResponseCache? _cache;

  // Other data of the account that must not outlive the session, e.g. the
  // to-do outbox (#24).
  final List<Future<void> Function()> _onForget;
  final ApiCredentials _credentials;
  final KeyValueStore _store;
  final Logger _log = Logger('SessionRepository');

  bool _expired = false;

  @override
  bool get signedIn => _credentials.session != null;

  @override
  bool get expired => _expired;

  @override
  Future<void> discard(ServerAddress server) async {
    try {
      await _store.delete(keyFor(server));
    } on Exception catch (e) {
      _log.warning('Could not delete a stored session.', e);
    }
  }

  /// The key of the session of [server]; each server keeps its own (#51).
  static String keyFor(ServerAddress server) => '$storageKey@$server';

  @override
  Future<Result<void>> restore(ServerAddress? server) async {
    try {
      if (server == null) {
        _use(null);
        return const Result.ok(null);
      }
      var session = _decode(await _store.read(keyFor(server)));
      // A session stored before several servers moves to its server's key.
      final legacy = _decode(await _store.read(storageKey));
      if (legacy != null) {
        await _store.write(keyFor(legacy.server), _encode(legacy));
        await _store.delete(storageKey);
        if (legacy.server == server) session ??= legacy;
      }
      _expired = false;
      _use(session?.server == server ? session : null);
      return const Result.ok(null);
    } on Exception catch (e) {
      _log.severe('Could not read the stored session.', e);
      return Result.error(e);
    }
  }

  @override
  Future<Result<SignInResult>> signIn(
    ServerAddress server, {
    String username = '',
    required String password,
    String code = '',
  }) async {
    final name = username.trim();
    final cleanCode = code.replaceAll(' ', '');
    // An app session where the server offers one (phase 2); older servers
    // answer 404 and get the browser session of phase 1 (ADR 0004).
    var result = await _authApi.createAppSession(
      server,
      device: deviceName,
      username: name,
      password: password,
      code: cleanCode,
    );
    if (result case Error(error: ApiException(failure: ApiFailure.notFound))) {
      result = await _authApi.login(
        server,
        username: name,
        password: password,
        code: cleanCode,
      );
    }
    switch (result) {
      case Ok(value: LoginNeedsCode(:final authenticatorApp)):
        return Result.ok(CodeRequired(authenticatorApp: authenticatorApp));
      case Ok(value: LoginSession(:final session)):
        return switch (await _keep(session)) {
          Ok() => const Result.ok(SignedIn()),
          Error(:final error) => Result.error(error),
        };
      case Error(:final error):
        return Result.error(error);
    }
  }

  @override
  Future<Result<void>> pair(ServerAddress server, String code) async {
    final result = await _authApi.redeemPairingCode(
      server,
      device: deviceName,
      code: code.trim(),
    );
    switch (result) {
      case Ok(value: final session):
        return _keep(session);
      case Error(:final error):
        return Result.error(error);
    }
  }

  /// The key of a browser sign-in that waits for the server's answer.
  static const pendingKey = 'session.browserSignIn';

  @override
  Future<bool> supportsBrowserSignIn(ServerAddress server) =>
      _authApi.supportsAppSessions(server);

  @override
  Future<Result<Uri>> startBrowserSignIn(ServerAddress server) async {
    final pkce = Pkce.generate();
    final state = Pkce.randomToken(16);
    try {
      // Kept in the secure storage: the system may end the app while the
      // browser is open.
      await _store.write(
        pendingKey,
        jsonEncode({
          'server': server.toString(),
          'verifier': pkce.verifier,
          'state': state,
        }),
      );
    } on Exception catch (e) {
      return Result.error(e);
    }
    return Result.ok(
      server
          .resolve('/app-sign-in')
          .replace(
            queryParameters: {'challenge': pkce.challenge, 'state': state},
          ),
    );
  }

  @override
  Future<Result<void>> finishBrowserSignIn({
    required String code,
    required String state,
  }) async {
    final Object? pending;
    try {
      final raw = await _store.read(pendingKey);
      await _store.delete(pendingKey);
      pending = raw == null ? null : jsonDecode(raw);
    } on Exception catch (e) {
      return Result.error(e);
    }
    // Only an answer to the sign-in this app started is accepted.
    if (pending
        case {
          'server': final String address,
          'verifier': final String verifier,
          'state': final String expected,
        }
        when expected == state && code.isNotEmpty) {
      if (ServerAddress.parse(address) case Ok(value: final server)) {
        final result = await _authApi.redeemPairingCode(
          server,
          device: deviceName,
          code: code,
          verifier: verifier,
        );
        return switch (result) {
          Ok(value: final session) => _keep(session),
          Error(:final error) => Result.error(error),
        };
      }
    }
    return const Result.error(UnexpectedSignIn());
  }

  Future<Result<void>> _keep(Session session) async {
    try {
      await _store.write(keyFor(session.server), _encode(session));
    } on Exception catch (e) {
      _log.severe('Could not store the session.', e);
      return Result.error(e);
    }
    _expired = false;
    _use(session);
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> signOut() async {
    final session = _credentials.session;
    if (session == null) return const Result.ok(null);
    // The server may be unreachable; the device forgets the session anyway,
    // and the user can end it in the web interface's session list.
    final logout = await _authApi.logout(session.server);
    if (logout case Error(:final error)) {
      _log.info('Sign-out did not reach the server: $error');
    }
    return _forget(expired: false);
  }

  void _onRejected() {
    _log.info('The server rejected the session.');
    _forget(expired: true).ignore();
  }

  Future<Result<void>> _forget({required bool expired}) async {
    final server = _credentials.session?.server;
    _expired = expired;
    _use(null);
    // The offline copy belongs to the account; nothing of it stays (#23).
    await _cache?.clear();
    for (final forget in _onForget) {
      await forget();
    }
    try {
      if (server != null) await _store.delete(keyFor(server));
      return const Result.ok(null);
    } on Exception catch (e) {
      _log.severe('Could not delete the stored session.', e);
      return Result.error(e);
    }
  }

  void _use(Session? session) {
    _credentials.session = session;
    notifyListeners();
  }

  static String _encode(Session s) => jsonEncode({
    'server': s.server.toString(),
    ...switch (s) {
      AppSession(:final token) => {'kind': 'app', 'token': token},
      BrowserSession(:final cookie, :final csrfToken) => {
        'kind': 'browser',
        'cookie': cookie,
        'csrfToken': csrfToken,
      },
    },
  });

  static Session? _decode(String? raw) {
    if (raw == null) return null;
    final Object? json;
    try {
      json = jsonDecode(raw);
    } on FormatException {
      return null;
    }
    if (json is! Map<String, Object?>) return null;
    final server = switch (json['server']) {
      final String s => switch (ServerAddress.parse(s)) {
        Ok(:final value) => value,
        Error() => null,
      },
      _ => null,
    };
    if (server == null) return null;
    // Sessions stored before app sessions have no kind: browser sessions.
    return switch (json) {
      {'kind': 'app', 'token': final String token} => AppSession(
        server: server,
        token: token,
      ),
      {'cookie': final String cookie, 'csrfToken': final String csrf} =>
        BrowserSession(server: server, cookie: cookie, csrfToken: csrf),
      _ => null,
    };
  }
}
