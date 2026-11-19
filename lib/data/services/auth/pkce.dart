import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// A PKCE pair (RFC 7636, S256) for the browser sign-in (#45): the app
/// keeps [verifier] and sends [challenge]; only it can redeem the code the
/// server sends back.
final class Pkce {
  const Pkce._(this.verifier, this.challenge);

  /// Creates a new pair from 32 random bytes.
  factory Pkce.generate() {
    final verifier = randomToken(32);
    return Pkce._(verifier, challengeOf(verifier));
  }

  /// The secret the app keeps.
  final String verifier;

  /// The S256 challenge sent to the server.
  final String challenge;

  /// The S256 challenge of [verifier]: unpadded base64url of its SHA-256.
  static String challengeOf(String verifier) =>
      _base64Url(sha256.convert(ascii.encode(verifier)).bytes);

  /// [bytes] random bytes as unpadded base64url, from a secure source.
  static String randomToken(int bytes) {
    final random = Random.secure();
    return _base64Url([for (var i = 0; i < bytes; i++) random.nextInt(256)]);
  }

  static String _base64Url(List<int> bytes) =>
      base64Url.encode(bytes).replaceAll('=', '');
}
