import 'package:flutter_test/flutter_test.dart';

import 'package:waylight_mobile/data/services/api/api_credentials.dart';
import 'package:waylight_mobile/domain/models/session.dart';

import '../../../testing/fakes/fake_server_repository.dart';

void main() {
  final session = BrowserSession(
    server: testServer('https://home.example.org/waylight'),
    cookie: 'waylight_session=s3cret',
    csrfToken: 'csrf',
  );
  final onServer = Uri.parse('https://home.example.org/waylight/api/todos');

  test('sends nothing when signed out', () {
    expect(ApiCredentials().headersFor('GET', onServer), isEmpty);
  });

  test('sends the cookie, and the CSRF token only on unsafe methods', () {
    final credentials = ApiCredentials()..session = session;

    expect(credentials.headersFor('GET', onServer), {
      'cookie': 'waylight_session=s3cret',
    });
    for (final method in ['POST', 'PUT', 'PATCH', 'DELETE']) {
      expect(credentials.headersFor(method, onServer)['X-CSRF-Token'], 'csrf');
    }
  });

  test('never sends the session to another server or path', () {
    final credentials = ApiCredentials()..session = session;

    for (final other in [
      'https://evil.example.org/waylight/api/todos',
      'http://home.example.org/waylight/api/todos',
      'https://home.example.org/other/api/todos',
    ]) {
      expect(credentials.headersFor('POST', Uri.parse(other)), isEmpty);
    }
  });

  test('reports a rejection only for requests that carried the session', () {
    var rejected = 0;
    final credentials = ApiCredentials()
      ..session = session
      ..onRejected = () => rejected++;

    credentials.rejected(Uri.parse('https://other.example.org/api/x'));
    expect(rejected, 0);

    credentials.rejected(onServer);
    expect(rejected, 1);
  });

  test('does not reveal the secrets in toString', () {
    expect(session.toString(), isNot(contains('s3cret')));
    expect(session.toString(), isNot(contains('csrf')));
  });

  test('sends an app session as bearer token without CSRF token', () {
    final credentials = ApiCredentials()
      ..session = AppSession(
        server: testServer('https://home.example.org/waylight'),
        token: 'wa_secret',
      );

    expect(credentials.headersFor('POST', onServer), {
      'authorization': 'Bearer wa_secret',
    });
    expect(
      credentials.headersFor('GET', Uri.parse('https://evil.example.org/x')),
      isEmpty,
    );
  });
}
