import 'package:waylight_mobile/data/services/scanner/barcode_scanner.dart';
import 'package:waylight_mobile/domain/models/tracking_number.dart';

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
}
