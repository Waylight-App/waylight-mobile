import 'package:flutter/foundation.dart';

import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/data/repositories/watch/watch_pairing_repository.dart';
import 'package:waylight_mobile/domain/models/watch_link.dart';
import 'package:waylight_mobile/utils/command.dart';
import 'package:waylight_mobile/utils/result.dart';

/// Pairs a Wear OS watch from this phone (#239): scan the watch's QR code,
/// confirm the watch, hand the server over.
class PairWatchViewModel extends ChangeNotifier {
  /// Creates the view model.
  PairWatchViewModel({
    required this._serverRepository,
    required this._watchRepository,
  }) {
    scan = Command1(_scan);
    pair = Command0(_pair);
    _watchRepository.available().then((value) {
      if (_disposed) return;
      _available = value;
      notifyListeners();
    }).ignore();
  }

  final ServerRepository _serverRepository;
  final WatchPairingRepository _watchRepository;

  bool _available = true;
  bool _disposed = false;
  WatchLink? _watch;

  /// Whether this phone can scan the watch's code.
  bool get available => _available;

  /// The watch found by the last scan, waiting for [pair].
  WatchLink? get watch => _watch;

  /// Opens the camera; the argument is the hint shown over it.
  late final Command1<void, String> scan;

  /// Hands the server and a fresh pairing code to [watch].
  late final Command0<void> pair;

  Future<Result<void>> _scan(String prompt) async {
    pair.clearResult();
    final result = await _watchRepository.scan(prompt: prompt);
    switch (result) {
      case Ok(:final value):
        // A cancelled scan keeps the watch found before.
        if (value != null) _watch = value;
        notifyListeners();
        return const Result.ok(null);
      case Error(:final error):
        _watch = null;
        notifyListeners();
        return Result.error(error);
    }
  }

  Future<Result<void>> _pair() async {
    final watch = _watch;
    final server = _serverRepository.current;
    if (watch == null || server == null) {
      return const Result.error(
        WatchPairingException(WatchPairingFailure.invalidCode),
      );
    }
    final result = await _watchRepository.pair(watch, server);
    // The watch stops listening after a handover; its key is spent.
    if (result is Ok<void>) {
      _watch = null;
      notifyListeners();
    }
    return result;
  }

  @override
  void dispose() {
    _disposed = true;
    scan.dispose();
    pair.dispose();
    super.dispose();
  }
}
