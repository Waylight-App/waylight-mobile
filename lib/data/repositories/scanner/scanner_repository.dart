import 'package:waylight_mobile/data/services/scanner/barcode_scanner.dart';
import 'package:waylight_mobile/domain/models/kiosk.dart';
import 'package:waylight_mobile/domain/models/tracking_number.dart';
import 'package:waylight_mobile/utils/result.dart';

/// Scanning for the app's forms (#196): the camera reads a code, this turns
/// it into what the form needs.
class ScannerRepository {
  /// Creates the repository.
  const ScannerRepository({required this._scanner});

  final BarcodeScanner _scanner;

  /// Whether this phone can scan.
  Future<bool> available() => _scanner.available();

  /// Scans a shipping label; the tracking number, or `null` when the
  /// person cancelled or the code holds none. [raw] receives the text when
  /// no number was found, so the form can show what was read.
  Future<String?> scanTrackingNumber({
    String prompt = '',
    void Function(String raw)? raw,
  }) async {
    final text = await _scanner.scan(prompt: prompt);
    if (text == null) return null;
    final number = trackingNumberFrom(text);
    if (number == null) raw?.call(text);
    return number;
  }

  /// Scans the QR code of a wall display (#294); the link it holds, or
  /// `null` when the person cancelled or the code is no kiosk link.
  /// [raw] receives the text when it is none, so the form can say so.
  Future<String?> scanKioskLink({
    String prompt = '',
    void Function(String raw)? raw,
  }) async {
    final text = await _scanner.scan(prompt: prompt);
    if (text == null) return null;
    if (parseKioskLink(text) is Ok) return text.trim();
    raw?.call(text);
    return null;
  }
}
