import 'package:flutter_test/flutter_test.dart';

import 'package:waylight_mobile/data/services/auth/pkce.dart';

void main() {
  test('computes the S256 challenge of RFC 7636, appendix B', () {
    expect(
      Pkce.challengeOf('dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk'),
      'E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM',
    );
  });

  test('generates a fresh 43-character verifier with its challenge', () {
    final a = Pkce.generate();
    final b = Pkce.generate();

    expect(a.verifier, hasLength(43));
    expect(a.challenge, Pkce.challengeOf(a.verifier));
    expect(a.verifier, isNot(b.verifier));
    expect(a.verifier, matches(RegExp(r'^[A-Za-z0-9_-]+$')));
  });
}
