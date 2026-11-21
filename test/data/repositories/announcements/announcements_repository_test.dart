import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:waylight_mobile/data/repositories/announcements/announcements_repository.dart';
import 'package:waylight_mobile/data/services/api/api_client.dart';
import 'package:waylight_mobile/data/services/api/module_api.dart';
import 'package:waylight_mobile/domain/models/announcement.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../../testing/fakes/fake_server_repository.dart';

/// The announcements API (#202), with an answer in the server's shape.
void main() {
  final fixture = File('test/fixtures/announcements_demo.json')
      .readAsStringSync();

  test('parses and sorts: pinned first, then newest', () {
    final list = sortAnnouncements(parseAnnouncements(jsonDecode(fixture))!);
    expect(list.map((a) => a.id), ['n2', 'n3', 'n1']);
    expect(list.first.expiresAt, isNotNull);
    expect(list.first.editable, isTrue);
    expect(list.last.read, isTrue);
    expect(parseAnnouncements({'x': 1}), isNull);
  });

  test('reads, marks read and sends the form', () async {
    final requests = <http.Request>[];
    final repo = AnnouncementsRepositoryRemote(
      api: ModuleApi(
        ApiClient(
          client: MockClient((r) async {
            requests.add(r);
            return switch (r.url.path) {
              '/api/announcements' when r.method == 'GET' => http.Response(
                fixture,
                200,
              ),
              '/api/announcements/me' => http.Response(
                '{"mayWrite":true}',
                200,
              ),
              _ => http.Response('{}', 200),
            };
          }),
        ),
      ),
    );
    expect(
      (await repo.list(testServer()) as Ok<List<Announcement>>).value.first.id,
      'n2',
    );
    expect(await repo.mayWrite(testServer()), isA<Ok<bool>>());
    await repo.markRead(testServer(), 'n2');
    expect(
      (requests.last.method, requests.last.url.path),
      ('POST', '/api/announcements/n2/read'),
    );
    await repo.create(
      testServer(),
      AnnouncementInput(
        title: ' Closed ',
        body: 'x',
        pinned: true,
        expiresAt: DateTime.utc(2026, 12),
      ),
    );
    expect(jsonDecode(requests.last.body), {
      'title': 'Closed',
      'body': 'x',
      'pinned': true,
      'expiresAt': '2026-12-01T00:00:00.000Z',
      'notify': false,
    });
    await repo.delete(testServer(), 'n2');
    expect(requests.last.method, 'DELETE');
  });
}
