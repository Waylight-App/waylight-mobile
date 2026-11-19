import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:waylight_mobile/data/services/push/push_crypto.dart';

import '../../../testing/fakes/in_memory_key_value_store.dart';

void main() {
  // Sealed by the server's pushproto.Seal for the key pair below
  // (waylight internal/shared/pushproto), so both sides agree on the format.
  const seed = 'AQIDBAUGBwgJCgsMDQ4PEBESExQVFhcYGRobHB0eHyA=';
  const publicKey = 'B6N8vBQgk8i3VdwbEOhstCY3StFqqFPtC9/AsrhtHHw=';
  final sealed = base64Decode(
    'AYtcRHUuPrVHMtVw30E/M3Ak7E2NnESU2aA2JbeGpURFLcbdxObFuR5k0y5gIPRyoh3OhTvg'
    '07Hr8DN0/CCsJeqqdxgb37dMNwf1KmCC4oxMY76QCGQxtgpiVZ+pCYjPVh+dII/TZf4VCFEr'
    'h6CHTjIYEM/dVn5HN6+T+oW2o127o8Jt',
  );

  PushCrypto withSeed() =>
      PushCrypto(InMemoryKeyValueStore()..values['push.private_key'] = seed);

  test('opens a payload sealed by the server', () async {
    final crypto = withSeed();

    expect(base64Encode(await crypto.publicKey()), publicKey);
    final content = await crypto.open(sealed);
    expect(content?.title, 'Backup failed');
    expect(content?.body, 'nas: exit 1');
    expect(content?.link, Uri.parse('waylight://open'));
  });

  test('rejects damaged payloads and other versions', () async {
    final crypto = withSeed();
    final tampered = Uint8List.fromList(sealed)..[sealed.length - 1] ^= 1;
    final otherVersion = Uint8List.fromList(sealed)..[0] = 2;

    expect(await crypto.open(tampered), isNull);
    expect(await crypto.open(otherVersion), isNull);
    expect(await crypto.open(Uint8List(10)), isNull);
  });

  test('creates a key pair once and forgets it', () async {
    final store = InMemoryKeyValueStore();
    final crypto = PushCrypto(store);

    final first = await crypto.publicKey();
    expect(first, hasLength(32));
    expect(await crypto.publicKey(), first);
    expect(await crypto.open(sealed), isNull, reason: 'not this device');

    await crypto.forget();
    expect(await crypto.publicKey(), isNot(first));
  });
}
