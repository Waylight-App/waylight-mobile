import 'package:flutter_test/flutter_test.dart';

import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

void main() {
  group('ServerAddress.parse accepts and normalises', () {
    const cases = {
      'https://home.example.org': 'https://home.example.org',
      '  https://home.example.org/  ': 'https://home.example.org',
      'home.example.org': 'https://home.example.org',
      'http://192.168.178.115:8090': 'http://192.168.178.115:8090',
      'https://example.org/waylight//': 'https://example.org/waylight',
      'HTTPS://Example.org': 'https://example.org',
    };
    for (final MapEntry(key: input, value: expected) in cases.entries) {
      test('"$input" as $expected', () {
        final result = ServerAddress.parse(input);
        expect(result, isA<Ok<ServerAddress>>());
        expect((result as Ok<ServerAddress>).value.toString(), expected);
      });
    }
  });

  group('ServerAddress.parse rejects', () {
    const cases = {
      '': InvalidServerAddressReason.empty,
      '   ': InvalidServerAddressReason.empty,
      'ftp://example.org': InvalidServerAddressReason.unsupportedScheme,
      'https://': InvalidServerAddressReason.malformed,
      'https://user:secret@example.org':
          InvalidServerAddressReason.unexpectedParts,
      'https://example.org/?a=b': InvalidServerAddressReason.unexpectedParts,
      'https://example.org/#top': InvalidServerAddressReason.unexpectedParts,
    };
    for (final MapEntry(key: input, value: reason) in cases.entries) {
      test('"$input" as ${reason.name}', () {
        final result = ServerAddress.parse(input);
        expect(result, isA<Error<ServerAddress>>());
        final error = (result as Error<ServerAddress>).error;
        expect(error, isA<InvalidServerAddress>());
        expect((error as InvalidServerAddress).reason, reason);
      });
    }
  });

  test('resolve keeps the base path of a reverse proxy', () {
    final server = (ServerAddress.parse(
      'https://example.org/waylight',
    ) as Ok<ServerAddress>).value;

    expect(
      server.resolve('/api/auth/status').toString(),
      'https://example.org/waylight/api/auth/status',
    );
  });

  test('isSecure is true for https only', () {
    bool secure(String input) =>
        (ServerAddress.parse(input) as Ok<ServerAddress>).value.isSecure;

    expect(secure('https://example.org'), isTrue);
    expect(secure('http://example.org'), isFalse);
  });

  test('addresses with the same URI are equal', () {
    expect(
      (ServerAddress.parse('example.org/') as Ok<ServerAddress>).value,
      (ServerAddress.parse('https://example.org') as Ok<ServerAddress>).value,
    );
  });
}
