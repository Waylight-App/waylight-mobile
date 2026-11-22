import 'package:flutter_test/flutter_test.dart';

import 'package:waylight_mobile/domain/models/paste_link.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

void main() {
  test('reads the text of the assistant QR code', () {
    final result = parsePasteLinkText(
      'waylight://paste?server=https%3A%2F%2Fhome.example.org&code=ab_C-1.2~',
    );

    expect(result, isA<Ok<PasteLink>>());
    final link = (result as Ok<PasteLink>).value;
    expect(link.server.uri.toString(), 'https://home.example.org');
    expect(link.code, 'ab_C-1.2~');
  });

  test('accepts a private http address', () {
    expect(
      parsePasteLinkText(
        'waylight://paste?server=http://192.168.1.5:8090&code=c',
      ),
      isA<Ok<PasteLink>>(),
    );
  });

  test('rejects other texts, schemes, hosts and codes', () {
    const base = 'waylight://paste?server=https://home.example.org&code=c';
    final bad = {
      'https://home.example.org': isA<InvalidPasteLink>(),
      'waylight://pair?server=https://home.example.org&code=c':
          isA<InvalidPasteLink>(),
      'waylight://paste?code=c': isA<InvalidPasteLink>(),
      'waylight://paste?server=https://home.example.org':
          isA<InvalidPasteLink>(),
      'waylight://paste?server=https://home.example.org&code=a/b':
          isA<InvalidPasteLink>(),
      'waylight://paste?server=ftp://home.example.org&code=c':
          isA<InvalidServerAddress>(),
      'waylight://paste?server=http://public.example.org&code=c':
          isA<InvalidServerAddress>(),
      'waylight://paste?server=https://u:p@home.example.org&code=c':
          isA<InvalidServerAddress>(),
    };
    expect(parsePasteLinkText(base), isA<Ok<PasteLink>>());
    for (final MapEntry(key: text, value: matcher) in bad.entries) {
      final result = parsePasteLinkText(text);
      expect(result, isA<Error<PasteLink>>(), reason: text);
      expect((result as Error<PasteLink>).error, matcher, reason: text);
    }
  });
}
