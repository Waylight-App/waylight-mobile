import 'dart:convert';
import 'dart:typed_data';

import 'package:waylight_mobile/data/services/api/module_api.dart';
import 'package:waylight_mobile/data/services/scanner/barcode_scanner.dart';
import 'package:waylight_mobile/data/services/watch/watch_handover.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/domain/models/watch_link.dart';
import 'package:waylight_mobile/utils/result.dart';

/// Pairs a Wear OS watch through this phone (#239, ADR 0015): reads the
/// watch's QR code, creates a pairing code with the phone's session and
/// hands server and code to the watch, encrypted with the key of the QR
/// code. The watch redeems the code for its own app session.
class WatchPairingRepository {
  /// Creates the repository.
  const WatchPairingRepository({
    required this._api,
    required this._scanner,
    required this._sealer,
    required this._watch,
  });

  final ModuleApi _api;
  final BarcodeScanner _scanner;
  final HandoverSealer _sealer;
  final WatchClient _watch;

  /// Whether this phone can pair a watch: it needs the camera scanner.
  Future<bool> available() => _scanner.available();

  /// Scans the watch's QR code; `Ok(null)` when the person cancelled.
  Future<Result<WatchLink?>> scan({String prompt = ''}) async {
    final text = await _scanner.scan(prompt: prompt);
    if (text == null) return const Result.ok(null);
    final link = WatchLink.parse(text);
    return link == null
        ? const Result.error(
            WatchPairingException(WatchPairingFailure.invalidCode),
          )
        : Result.ok(link);
  }

  /// Hands [server] to the watch of [link]. The pairing code is sealed
  /// before it leaves this repository; it is never sent in the clear.
  Future<Result<void>> pair(WatchLink link, ServerAddress server) async {
    final created = await _api.post(
      server,
      '/api/auth/app-sessions/pairing-code',
    );
    final String code;
    switch (created) {
      case Ok(value: {'code': final String value}) when value.isNotEmpty:
        code = value;
      case Ok():
        return const Result.error(ApiException(ApiFailure.server));
      case Error(:final error):
        return Result.error(error);
    }
    final sealed = await _sealer.seal(link.key, handoverMessage(server, code));
    if (sealed == null) return _fail(WatchPairingFailure.unsupported);
    final body = base64Url.encode(sealed).replaceAll('=', '');
    return switch (await _watch.pair(link.address, body)) {
      204 => const Result.ok(null),
      401 => _fail(WatchPairingFailure.rejected),
      422 => _fail(WatchPairingFailure.invalidServer),
      502 => _fail(WatchPairingFailure.serverUnreachable),
      400 => _fail(WatchPairingFailure.notDecryptable),
      _ => _fail(WatchPairingFailure.watchUnreachable),
    };
  }

  /// The plaintext the watch expects: compact JSON, server first, as in
  /// the watch's test vector.
  static Uint8List handoverMessage(ServerAddress server, String code) =>
      utf8.encode(jsonEncode({'server': server.toString(), 'code': code}));

  static Result<void> _fail(WatchPairingFailure failure) =>
      Result.error(WatchPairingException(failure));
}
