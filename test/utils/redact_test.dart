import 'package:flutter_test/flutter_test.dart';

import 'package:waylight_mobile/utils/redact.dart';

void main() {
  test('removes addresses, hosts and IP addresses', () {
    expect(
      redact('GET https://user:pw@nas.home:8090/api/x?q=1 failed'),
      'GET <address> failed',
    );
    expect(redact('connect to nas.example.org:8090'), 'connect to <host>');
    expect(redact('from 192.168.178.115:8090'), 'from <ip>');
    expect(redact('peer fe80::1ff:fe23:4567:890a'), 'peer <ip>');
  });

  test('removes credentials and e-mail addresses', () {
    expect(
      redact('Authorization: Bearer abc.def-ghi'),
      'Authorization: <redacted>',
    );
    expect(
      redact('cookie=waylight_session=xyz; path=/'),
      'cookie=<redacted>; path=/',
    );
    expect(redact('password: hunter2'), 'password: <redacted>');
    expect(redact('token=123&next=1'), 'token=<redacted>&next=1');
    expect(redact('mail an tristan@example.org'), 'mail an <e-mail>');
  });

  test('removes long random strings but keeps ordinary text', () {
    expect(
      redact('key 9f8e7d6c5b4a39281706f5e4d3c2b1a0aabbccdd'),
      'key <redacted>',
    );
    expect(
      redact('Lint & test failed: HTTP 503 in 120 ms'),
      'Lint & test failed: HTTP 503 in 120 ms',
    );
    expect(
      redact('Widget weather could not load'),
      'Widget weather could not load',
    );
  });
}
