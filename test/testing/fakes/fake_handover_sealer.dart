import 'dart:typed_data';

import 'package:waylight_mobile/data/services/watch/watch_handover.dart';

/// A [HandoverSealer] for tests: "seals" by prefixing a marker, or fails
/// when [supported] is false. The real AES-GCM is tested in Kotlin against
/// the watch's test vector.
class FakeHandoverSealer implements HandoverSealer {
  /// Creates the fake.
  FakeHandoverSealer({this.supported = true});

  /// Whether [seal] works.
  bool supported;

  /// The plaintexts passed to [seal].
  final sealed = <String>[];

  @override
  Future<Uint8List?> seal(Uint8List key, Uint8List plaintext) async {
    if (!supported) return null;
    sealed.add(String.fromCharCodes(plaintext));
    return Uint8List.fromList([...key.take(2), ...plaintext]);
  }
}
