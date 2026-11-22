import 'package:waylight_mobile/data/services/api/module_api.dart';
import 'package:waylight_mobile/data/services/scanner/barcode_scanner.dart';
import 'package:waylight_mobile/domain/models/paste_link.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// Sends a key copied on the phone to the setup assistant (#303): the
/// assistant shows a QR code, the person scans it and enters the value
/// here.
class SetupPasteRepository {
  /// Creates the repository.
  const SetupPasteRepository({required this._api, required this._scanner});

  final ModuleApi _api;
  final BarcodeScanner _scanner;

  /// Whether this phone can scan.
  Future<bool> available() => _scanner.available();

  /// Scans the assistant's QR code; `Ok(null)` when the person cancelled.
  Future<Result<PasteLink?>> scan({String prompt = ''}) async {
    final text = await _scanner.scan(prompt: prompt);
    if (text == null) return const Result.ok(null);
    return switch (parsePasteLinkText(text)) {
      Ok(:final value) => Result.ok(value),
      Error(:final error) => Result.error(error),
    };
  }

  /// Hands [value] to the assistant that showed [code] on [server]. The
  /// value goes into the request body only.
  Future<Result<void>> send(
    ServerAddress server,
    String code,
    String value,
  ) async {
    final result = await _api.put(
      server,
      '/api/setup/paste/${Uri.encodeComponent(code)}',
      body: {'value': value},
    );
    return switch (result) {
      Ok() => const Result.ok(null),
      Error(:final error) => Result.error(error),
    };
  }
}
