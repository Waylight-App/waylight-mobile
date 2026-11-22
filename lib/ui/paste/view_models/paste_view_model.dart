import 'package:flutter/foundation.dart';

import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/data/repositories/setup_paste/setup_paste_repository.dart';
import 'package:waylight_mobile/domain/models/paste_link.dart';
import 'package:waylight_mobile/utils/command.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The code belongs to a server this app is not connected to.
final class PasteOtherServer implements Exception {
  /// Creates the exception.
  const PasteOtherServer();

  @override
  String toString() => 'PasteOtherServer()';
}

/// Sends a value to the setup assistant (#303): the code comes from a
/// `waylight://paste` link or from the scanner, the person enters the value.
class PasteViewModel extends ChangeNotifier {
  /// Creates the view model; [server] and [code] are the parts of an opened
  /// link, both empty when the screen was opened from the settings.
  PasteViewModel({
    required String server,
    required String code,
    required this._serverRepository,
    required this._pasteRepository,
  }) {
    if (server.isNotEmpty || code.isNotEmpty) {
      switch (parsePasteLink(server, code)) {
        case Ok(:final value):
          _link = value;
        case Error(:final error):
          linkError = error;
      }
    }
    scan = Command1(_scan);
    send = Command1(_send);
    _pasteRepository.available().then((value) {
      if (_disposed) return;
      _available = value;
      notifyListeners();
    }).ignore();
  }

  final ServerRepository _serverRepository;
  final SetupPasteRepository _pasteRepository;

  PasteLink? _link;
  bool _available = true;
  bool _disposed = false;

  /// Why the opened link cannot be used; `null` when it can.
  Exception? linkError;

  /// The code waiting for a value.
  PasteLink? get link => _link;

  /// Whether this phone can scan.
  bool get available => _available;

  /// Opens the camera; the argument is the hint shown over it.
  late final Command1<void, String> scan;

  /// Sends the value (argument) to the server of [link].
  late final Command1<void, String> send;

  Future<Result<void>> _scan(String prompt) async {
    send.clearResult();
    final result = await _pasteRepository.scan(prompt: prompt);
    switch (result) {
      case Ok(:final value):
        // A cancelled scan keeps the code found before.
        if (value != null) {
          _link = value;
          linkError = null;
        }
        notifyListeners();
        return const Result.ok(null);
      case Error(:final error):
        _link = null;
        linkError = null;
        notifyListeners();
        return Result.error(error);
    }
  }

  Future<Result<void>> _send(String value) async {
    final link = _link;
    final current = _serverRepository.current;
    if (link == null) return const Result.error(InvalidPasteLink());
    // The session only belongs to the connected server; a code for any
    // other server must not get the value.
    if (current == null || !_serverRepository.addresses.contains(link.server)) {
      return const Result.error(PasteOtherServer());
    }
    final result = await _pasteRepository.send(
      current,
      link.code,
      value.trim(),
    );
    // The code takes one value; a new one needs a new scan.
    if (result is Ok<void>) {
      _link = null;
      notifyListeners();
    }
    return result;
  }

  @override
  void dispose() {
    _disposed = true;
    scan.dispose();
    send.dispose();
    super.dispose();
  }
}
