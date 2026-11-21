import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:waylight_mobile/data/repositories/presence/presence_repository.dart';
import 'package:waylight_mobile/data/services/api/api_client.dart';
import 'package:waylight_mobile/data/services/api/module_api.dart';
import 'package:waylight_mobile/domain/models/presence.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../../testing/fakes/fake_server_repository.dart';

/// The presence API (#200), with an answer in the server's shape.
void main() {
  final fixture = File('test/fixtures/presence_demo.json').readAsStringSync();

  test('parses the board with counts and my own entry', () {
    final board = parsePresence(jsonDecode(fixture))!;
    expect(board.people.map((p) => p.status), [
      PresenceStatus.office,
      PresenceStatus.away,
      PresenceStatus.none,
    ]);
    expect(board.people[1].fromAbsence, isTrue);
    expect(board.people[1].returnOn, DateTime(2026, 11, 24));
    expect(board.counts[PresenceStatus.away], 1);
    expect(board.mine?.status, PresenceStatus.office);
    expect(parsePresence({'people': 'x'}), isNull);
    expect(
      parsePresence({
        ...jsonDecode(fixture) as Map<String, Object?>,
        'mine': null,
      })!.mine,
      isNull,
      reason: 'guests and kiosk displays',
    );
  });

  test('reads a group and sets and clears my status', () async {
    final requests = <http.Request>[];
    final repo = PresenceRepositoryRemote(
      api: ModuleApi(
        ApiClient(
          client: MockClient((r) async {
            requests.add(r);
            return r.method == 'GET'
                ? http.Response(fixture, 200)
                : http.Response('', 204);
          }),
        ),
      ),
    );
    expect(
      await repo.board(testServer(), group: 'team'),
      isA<Ok<PresenceBoard>>(),
    );
    expect(requests.last.url.queryParameters['group'], 'team');

    await repo.setMine(
      testServer(),
      PresenceStatus.away,
      returnOn: DateTime(2026, 11, 24),
    );
    expect(jsonDecode(requests.last.body), {
      'status': 'away',
      'returnOn': '2026-11-24',
    });
    await repo.setMine(
      testServer(),
      PresenceStatus.home,
      returnOn: DateTime(2026, 11, 24),
    );
    expect(jsonDecode(requests.last.body), {'status': 'home', 'returnOn': ''});
    await repo.setMine(testServer(), PresenceStatus.none);
    expect(jsonDecode(requests.last.body), {'status': '', 'returnOn': ''});
  });
}
