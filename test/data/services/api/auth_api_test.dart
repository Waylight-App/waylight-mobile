import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:waylight_mobile/data/services/api/api_client.dart';
import 'package:waylight_mobile/data/services/api/auth_api.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../../testing/fakes/fake_server_repository.dart';

void main() {
  late http.Request sent;

  AuthApi apiAnswering(
    int status,
    Object? body, {
    Map<String, String> headers = const {},
  }) => AuthApi(
    ApiClient(
      client: MockClient((request) async {
        sent = request;
        return http.Response(jsonEncode(body), status, headers: headers);
      }),
    ),
  );

  test('sends only the fields that are set', () async {
    await apiAnswering(
      401,
      null,
    ).login(testServer(), username: '', password: 'pw');

    expect(sent.url.path, '/api/auth/login');
    expect(jsonDecode(sent.body), {'password': 'pw'});
  });

  test('reads the session from cookie and body', () async {
    final api = apiAnswering(
      200,
      {'csrfToken': 'csrf', 'expiresAt': '2026-12-01T00:00:00Z'},
      headers: {
        'set-cookie': '__Host-waylight_session=abc123; Path=/; HttpOnly; Secure; SameSite=Strict',
      },
    );

    final result = await api.login(
      testServer(),
      username: 'anna',
      password: 'pw',
      code: '123456',
    );

    final session =
        ((result as Ok<LoginResponse>).value as LoginSession).session;
    expect(session.cookie, '__Host-waylight_session=abc123');
    expect(session.csrfToken, 'csrf');
    expect(session.server, testServer());
    expect(jsonDecode(sent.body), {
      'username': 'anna',
      'password': 'pw',
      'code': '123456',
    });
  });

  test('asks for a code when the server wants a second step', () async {
    final result = await apiAnswering(202, {
      'secondFactor': {'totp': false, 'ticket': 't'},
    }).login(testServer(), username: '', password: 'pw');

    final step = (result as Ok<LoginResponse>).value as LoginNeedsCode;
    expect(step.authenticatorApp, isFalse);
  });

  test('asks for a code when the TOTP code is missing', () async {
    final result = await apiAnswering(422, {
      'error': {'code': 'invalid', 'field': 'totpCode'},
    }).login(testServer(), username: '', password: 'pw');

    final step = (result as Ok<LoginResponse>).value as LoginNeedsCode;
    expect(step.authenticatorApp, isTrue);
  });

  test('fails when the answer carries no session cookie', () async {
    final result = await apiAnswering(200, {
      'csrfToken': 'csrf',
    }).login(testServer(), username: '', password: 'pw');

    expect(
      ((result as Error<LoginResponse>).error as ApiException).failure,
      ApiFailure.server,
    );
  });

  test('passes wrong credentials on', () async {
    final result = await apiAnswering(401, {
      'error': {'code': 'unauthorized'},
    }).login(testServer(), username: '', password: 'pw');

    expect(
      ((result as Error<LoginResponse>).error as ApiException).failure,
      ApiFailure.unauthorized,
    );
  });
}
