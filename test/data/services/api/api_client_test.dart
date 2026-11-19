import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:waylight_mobile/data/services/api/api_client.dart';
import 'package:waylight_mobile/data/services/api/api_credentials.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/session.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../../testing/fakes/fake_server_repository.dart';

void main() {
  final uri = Uri.parse('https://home.example.org/api/todos');

  ApiClient clientAnswering(int status, String body) => ApiClient(
    client: MockClient((request) async => http.Response(body, status)),
  );

  test('decodes a successful JSON answer', () async {
    final client = clientAnswering(200, '{"ok":true}');

    final result = await client.getJson(uri);

    expect((result as Ok<Object?>).value, {'ok': true});
  });

  test('sends JSON bodies with the content type', () async {
    late http.Request sent;
    final client = ApiClient(
      client: MockClient((request) async {
        sent = request;
        return http.Response('', 204);
      }),
    );

    await client.postJson(uri, body: {'title': 'Milk'});

    expect(sent.method, 'POST');
    expect(sent.headers['content-type'], startsWith('application/json'));
    expect(jsonDecode(sent.body), {'title': 'Milk'});
  });

  test('maps the error envelope of the server', () async {
    final client = clientAnswering(
      422,
      '{"error":{"code":"invalid","message":"Too long.","field":"title"}}',
    );

    final result = await client.getJson(uri);

    final error = (result as Error<Object?>).error as ApiException;
    expect(error.failure, ApiFailure.invalid);
    expect(error.statusCode, 422);
    expect(error.code, 'invalid');
    expect(error.message, 'Too long.');
    expect(error.field, 'title');
  });

  final statuses = {
    401: ApiFailure.unauthorized,
    403: ApiFailure.forbidden,
    404: ApiFailure.notFound,
    429: ApiFailure.tooManyRequests,
    500: ApiFailure.server,
    502: ApiFailure.server,
  };
  for (final MapEntry(key: status, value: failure) in statuses.entries) {
    test('maps HTTP $status to ${failure.name}', () async {
      final result = await clientAnswering(status, '<html>').getJson(uri);

      expect(
        ((result as Error<Object?>).error as ApiException).failure,
        failure,
      );
    });
  }

  test('reports a connection error as unreachable', () async {
    final client = ApiClient(
      client: MockClient((request) => throw http.ClientException('refused')),
    );

    final result = await client.getJson(uri);

    expect(
      ((result as Error<Object?>).error as ApiException).failure,
      ApiFailure.unreachable,
    );
  });

  test('reports a timeout as unreachable', () async {
    final client = ApiClient(
      client: MockClient((request) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return http.Response('{}', 200);
      }),
      timeout: const Duration(milliseconds: 1),
    );

    final result = await client.getJson(uri);

    expect(
      ((result as Error<Object?>).error as ApiException).failure,
      ApiFailure.unreachable,
    );
  });

  group('with a session', () {
    late ApiCredentials credentials;
    late http.Request sent;

    ApiClient clientWith(int status) => ApiClient(
      credentials: credentials,
      client: MockClient((request) async {
        sent = request;
        return http.Response('', status);
      }),
    );

    setUp(() {
      credentials = ApiCredentials()
        ..session = BrowserSession(
          server: testServer(),
          cookie: 'waylight_session=s',
          csrfToken: 'csrf',
        );
    });

    test('adds cookie and CSRF token to requests to its server', () async {
      await clientWith(204).postJson(uri);

      expect(sent.headers['cookie'], 'waylight_session=s');
      expect(sent.headers['X-CSRF-Token'], 'csrf');
    });

    test('reports a 401 to the credentials', () async {
      var rejected = false;
      credentials.onRejected = () => rejected = true;

      final result = await clientWith(401).getJson(uri);

      expect(rejected, isTrue);
      expect(
        ((result as Error<Object?>).error as ApiException).failure,
        ApiFailure.unauthorized,
      );
    });

    test('returns status and headers on request', () async {
      final client = ApiClient(
        client: MockClient(
          (request) async =>
              http.Response('{"a":1}', 202, headers: {'set-cookie': 'x=y'}),
        ),
      );

      final result = await client.postJsonResponse(uri);

      final response = (result as Ok<ApiResponse>).value;
      expect(response.statusCode, 202);
      expect(response.body, {'a': 1});
      expect(response.headers['set-cookie'], 'x=y');
    });
  });

  test('decodes the body as UTF-8 without a charset', () async {
    final client = ApiClient(
      client: MockClient(
        (_) async => http.Response.bytes(
          utf8.encode('{"title":"Grüße 🏠"}'),
          200,
          headers: {'content-type': 'application/json'},
        ),
      ),
    );

    final result = await client.getJson(uri);

    expect((result as Ok<Object?>).value, {'title': 'Grüße 🏠'});
  });
}
