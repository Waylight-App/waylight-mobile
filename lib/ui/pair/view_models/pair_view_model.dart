import 'package:flutter/foundation.dart';

import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/data/repositories/session/session_repository.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/command.dart';
import 'package:waylight_mobile/utils/result.dart';

/// A pairing link without server or code.
final class InvalidPairingLink implements Exception {
  /// Creates the exception.
  const InvalidPairingLink();
}

/// Pairs the app from the QR code of the web settings (#43): connects the
/// server of the link and redeems its code for an app session. The router
/// shows the dashboard once that worked.
class PairViewModel extends ChangeNotifier {
  /// Creates the view model and starts pairing.
  PairViewModel({
    required this._server,
    required this._code,
    required this._serverRepository,
    required this._sessionRepository,
  }) {
    pair = Command0(_pair)..execute().ignore();
    disconnect = Command0(_serverRepository.disconnect);
  }

  final String _server;
  final String _code;
  final ServerRepository _serverRepository;
  final SessionRepository _sessionRepository;

  /// Connects and signs in; run again to retry.
  late final Command0<void> pair;

  /// Forgets a server connected by a failed pairing, for entering an
  /// address by hand.
  late final Command0<void> disconnect;

  Future<Result<void>> _pair() async {
    if (_code.trim().isEmpty) return const Result.error(InvalidPairingLink());
    final ServerAddress server;
    switch (ServerAddress.parse(_server)) {
      case Ok(:final value):
        server = value;
      case Error(:final error):
        return Result.error(
          _server.trim().isEmpty ? const InvalidPairingLink() : error,
        );
    }
    if (_serverRepository.current != server) {
      final connected = await _serverRepository.connect(server);
      if (connected case Error(:final error)) return Result.error(error);
    }
    return _sessionRepository.pair(server, _code);
  }

  @override
  void dispose() {
    pair.dispose();
    disconnect.dispose();
    super.dispose();
  }
}
