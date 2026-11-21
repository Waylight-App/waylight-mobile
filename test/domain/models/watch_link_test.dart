import 'package:flutter_test/flutter_test.dart';

import 'package:waylight_mobile/domain/models/watch_link.dart';

void main() {
  // Bytes 0..31, as in the watch's tests.
  const key = 'AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8';

  test('reads the address and the key of a watch code', () {
    final link = WatchLink.parse(
      'waylight://watch?addr=192.168.1.23:41234&key=$key',
    )!;

    expect(link.address, '192.168.1.23:41234');
    expect(link.key, List.generate(32, (i) => i));
  });

  test('accepts the key with padding', () {
    expect(
      WatchLink.parse('waylight://watch?addr=10.0.0.5:5000&key=$key='),
      isNotNull,
    );
  });

  test('rejects other codes, public addresses and short keys', () {
    for (final text in [
      'https://example.org',
      'waylight://pair?server=https://h.example&code=c',
      'waylight://watch?addr=8.8.8.8:5000&key=$key',
      'waylight://watch?addr=watch.local:5000&key=$key',
      'waylight://watch?addr=192.168.1.23&key=$key',
      'waylight://watch?addr=192.168.1.23:0&key=$key',
      'waylight://watch?addr=192.168.1.23:5000&key=AAEC',
      'waylight://watch?addr=192.168.1.23:5000&key=not*base64',
      'waylight://watch?addr=192.168.1.23:5000',
    ]) {
      expect(WatchLink.parse(text), isNull, reason: text);
    }
  });

  test('keeps the key out of strings', () {
    final link = WatchLink.parse(
      'waylight://watch?addr=192.168.1.23:41234&key=$key',
    )!;
    expect(link.toString(), 'WatchLink(192.168.1.23:41234)');
  });
}
