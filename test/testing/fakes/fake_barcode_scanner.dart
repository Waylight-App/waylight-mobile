import 'package:waylight_mobile/data/services/scanner/barcode_scanner.dart';

/// A [BarcodeScanner] for tests that "reads" [next].
class FakeBarcodeScanner implements BarcodeScanner {
  /// Creates the fake.
  FakeBarcodeScanner({this.next, this.isAvailable = true});

  /// What the next scan reads; `null` means cancelled.
  String? next;

  /// What [available] answers.
  bool isAvailable;

  @override
  Future<bool> available() async => isAvailable;

  @override
  Future<String?> scan({String prompt = ''}) async => next;
}
