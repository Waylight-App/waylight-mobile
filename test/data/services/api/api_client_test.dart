import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:waylight_mobile/data/services/api/api_client.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/utils/result.dart';

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
}
