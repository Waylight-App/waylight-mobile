import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'package:waylight_mobile/data/services/storage/key_value_store.dart';
import 'package:waylight_mobile/domain/models/push.dart';

/// The device's side of the push encryption (server ADR 0025, point 5).
///
/// The server encrypts each message for the device's X25519 public key:
/// an ephemeral key agreement, HKDF-SHA256 with the info
/// `waylight-push-v1` to a 32-byte key and AES-256-GCM. A payload is
/// `0x01 ‖ ephemeral public key (32) ‖ nonce (12) ‖ ciphertext and tag`.
/// The private key never leaves the secure storage.
final class PushCrypto {
  /// Creates the service on top of the secure key-value store.
  PushCrypto(this._store);

  final KeyValueStore _store;

  static const _storageKey = 'push.private_key';
  static const _version = 0x01;
  static const _info = 'waylight-push-v1';
  static final _x25519 = X25519();
  static final _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
  static final _aes = AesGcm.with256bits();

  /// The device's public key, creating the key pair on first use.
  Future<Uint8List> publicKey() async {
    final pair = await _keyPair() ?? await _createKeyPair();
    final pub = await pair.extractPublicKey();
    return Uint8List.fromList(pub.bytes);
  }

  /// Forgets the key pair, e.g. when notifications are turned off; a new
  /// one is created when they are turned on again.
  Future<void> forget() => _store.delete(_storageKey);

  /// Decrypts a payload; `null` if it is not for this device or damaged.
  Future<PushContent?> open(Uint8List sealed) async {
    const head = 1 + 32;
    const nonceLength = 12;
    const tagLength = 16;
    if (sealed.length < head + nonceLength + tagLength ||
        sealed[0] != _version) {
      return null;
    }
    final pair = await _keyPair();
    if (pair == null) return null;
    try {
      final shared = await _x25519.sharedSecretKey(
        keyPair: pair,
        remotePublicKey: SimplePublicKey(
          sealed.sublist(1, head),
          type: KeyPairType.x25519,
        ),
      );
      final key = await _hkdf.deriveKey(
        secretKey: shared,
        info: utf8.encode(_info),
      );
      final rest = sealed.sublist(head);
      final plain = await _aes.decrypt(
        SecretBox(
          rest.sublist(nonceLength, rest.length - tagLength),
          nonce: rest.sublist(0, nonceLength),
          mac: Mac(rest.sublist(rest.length - tagLength)),
        ),
        secretKey: key,
      );
      return _content(jsonDecode(utf8.decode(plain)));
    } on SecretBoxAuthenticationError {
      return null;
    } on FormatException {
      return null;
    }
  }

  Future<SimpleKeyPair?> _keyPair() async {
    final stored = await _store.read(_storageKey);
    if (stored == null) return null;
    return _x25519.newKeyPairFromSeed(base64Decode(stored));
  }

  Future<SimpleKeyPair> _createKeyPair() async {
    final pair = await _x25519.newKeyPair();
    final seed = await pair.extractPrivateKeyBytes();
    await _store.write(_storageKey, base64Encode(seed));
    return pair;
  }

  static PushContent? _content(Object? json) {
    if (json case {'title': final String title, 'body': final String body}) {
      final link = json['link'];
      return PushContent(
        title: title,
        body: body,
        link: link is String ? Uri.tryParse(link) : null,
      );
    }
    return null;
  }
}
