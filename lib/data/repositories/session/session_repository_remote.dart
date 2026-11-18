import 'dart:convert';

import 'package:logging/logging.dart';

import 'package:waylight_mobile/data/repositories/session/session_repository.dart';
import 'package:waylight_mobile/data/services/api/api_credentials.dart';
import 'package:waylight_mobile/data/services/api/auth_api.dart';
import 'package:waylight_mobile/data/services/storage/key_value_store.dart';
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
  }) {
    _credentials.onRejected = _onRejected;
  }

  /// The key under which the session is stored.
  static const storageKey = 'session';

  final AuthApi _authApi;
  final ApiCredentials _credentials;
  final KeyValueStore _store;
  final Logger _log = Logger('SessionRepository');

  bool _expired = false;

  @override
  bool get signedIn => _credentials.session != null;

  @override
  bool get expired => _expired;

  @override
  Future<Result<void>> restore(ServerAddress? server) async {
    try {
      final session = _decode(await _store.read(storageKey));
      if (session != null && session.server == server) {
        _use(session);
      } else if (session != null) {
        await _store.delete(storageKey);
      }
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
    final result = await _authApi.login(
      server,
      username: username.trim(),
      password: password,
      code: code.replaceAll(' ', ''),
    );
    switch (result) {
      case Ok(value: LoginNeedsCode(:final authenticatorApp)):
        return Result.ok(CodeRequired(authenticatorApp: authenticatorApp));
      case Ok(value: LoginSession(:final session)):
        try {
          await _store.write(storageKey, _encode(session));
        } on Exception catch (e) {
          _log.severe('Could not store the session.', e);
          return Result.error(e);
        }
        _expired = false;
        _use(session);
        return const Result.ok(SignedIn());
      case Error(:final error):
        return Result.error(error);
    }
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
    _expired = expired;
    _use(null);
    try {
      await _store.delete(storageKey);
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
    'cookie': s.cookie,
    'csrfToken': s.csrfToken,
  });

  static Session? _decode(String? raw) {
    if (raw == null) return null;
    final Object? json;
    try {
      json = jsonDecode(raw);
    } on FormatException {
      return null;
    }
    if (json case {
      'server': final String server,
      'cookie': final String cookie,
      'csrfToken': final String csrf,
    }) {
      if (ServerAddress.parse(server) case Ok(:final value)) {
        return Session(server: value, cookie: cookie, csrfToken: csrf);
      }
    }
    return null;
  }
}
