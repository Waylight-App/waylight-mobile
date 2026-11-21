import 'dart:convert';
import 'dart:typed_data';

import 'package:waylight_mobile/domain/models/server_address.dart';

/// The QR code a Wear OS watch shows while it waits to be paired (#239,
/// ADR 0015): `waylight://watch?addr=<ipv4>:<port>&key=<base64url key>`.
final class WatchLink {
  const WatchLink._(this.address, this.key);

  /// The watch's listener in the local network, `ip:port`.
  final String address;

  /// The 256-bit key for this one handover.
  final Uint8List key;

  /// The number of bytes in [key].
  static const keyLength = 32;

  /// Reads a scanned [text]; `null` when it is not a watch's pairing code.
  ///
  /// Only private IPv4 addresses are accepted: the watch is in the same
  /// Wi-Fi, and a code that points elsewhere did not come from a watch.
  static WatchLink? parse(String text) {
    final uri = Uri.tryParse(text.trim());
    if (uri == null || uri.scheme != 'waylight' || uri.host != 'watch') {
      return null;
    }
    final address = uri.queryParameters['addr'] ?? '';
    final match = RegExp(r'^(\d{1,3}(?:\.\d{1,3}){3}):(\d{1,5})$')
        .firstMatch(address);
    if (match == null || !isPrivateHost(match.group(1)!)) return null;
    final port = int.parse(match.group(2)!);
    if (port < 1 || port > 65535) return null;
    final key = _decodeKey(uri.queryParameters['key'] ?? '');
    if (key == null) return null;
    return WatchLink._(address, key);
  }

  static Uint8List? _decodeKey(String encoded) {
    try {
      final bytes = base64Url.decode(base64Url.normalize(encoded));
      return bytes.length == keyLength ? bytes : null;
    } on FormatException {
      return null;
    }
  }

  // The key is a secret; keep it out of logs.
  @override
  String toString() => 'WatchLink($address)';
}

/// Why handing the server over to a watch failed.
enum WatchPairingFailure {
  /// The scanned code is not a watch's pairing code.
  invalidCode,

  /// The phone cannot encrypt the handover (no Android).
  unsupported,

  /// The watch did not answer: another network, or its screen was closed.
  watchUnreachable,

  /// The watch could not read the handover: an old or another QR code.
  notDecryptable,

  /// The server rejected the pairing code the watch redeemed.
  rejected,

  /// The watch does not accept the server address.
  invalidServer,

  /// The watch cannot reach the server.
  serverUnreachable,
}

/// Pairing a watch failed for [failure].
final class WatchPairingException implements Exception {
  /// Creates the exception.
  const WatchPairingException(this.failure);

  /// What went wrong.
  final WatchPairingFailure failure;

  @override
  String toString() => 'WatchPairingException(${failure.name})';
}
