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
    expect(secure('http://192.168.1.2'), isFalse);
  });

  test('addresses with the same URI are equal', () {
    expect(
      (ServerAddress.parse('example.org/') as Ok<ServerAddress>).value,
      (ServerAddress.parse('https://example.org') as Ok<ServerAddress>).value,
    );
  });

  group('plain HTTP (ADR 0006)', () {
    test('is accepted for private addresses', () {
      for (final address in [
        'http://192.168.178.115:8090',
        'http://10.0.2.2:8090',
        'http://172.20.1.5',
        'http://127.0.0.1:8090',
        'http://localhost:8090',
        'http://169.254.10.1',
        'http://waylight.local',
        'http://server.home.arpa',
        'http://[fd12:3456::1]:8090',
        'http://[fe80::1]',
        'http://[::1]:8090',
      ]) {
        expect(
          ServerAddress.parse(address),
          isA<Ok<ServerAddress>>(),
          reason: address,
        );
      }
    });

    test('is rejected for every other address', () {
      for (final address in [
        'http://home.example.org',
        'http://8.8.8.8',
        'http://172.32.0.1',
        'http://192.169.1.1',
        'http://server.fritz.box',
        'http://[2001:db8::1]',
      ]) {
        final result = ServerAddress.parse(address);
        expect(
          ((result as Error<ServerAddress>).error as InvalidServerAddress)
              .reason,
          InvalidServerAddressReason.insecure,
          reason: address,
        );
      }
    });

    test('HTTPS works for any address', () {
      expect(
        ServerAddress.parse('https://home.example.org'),
        isA<Ok<ServerAddress>>(),
      );
    });
  });
}
