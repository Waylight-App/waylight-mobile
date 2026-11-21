import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:waylight_mobile/data/repositories/absences/absences_repository.dart';
import 'package:waylight_mobile/data/services/api/api_client.dart';
import 'package:waylight_mobile/data/services/api/module_api.dart';
import 'package:waylight_mobile/domain/models/absence.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../../testing/fakes/fake_server_repository.dart';

/// The absences API (#201), with an answer in the server's shape.
void main() {
  final fixture = File('test/fixtures/absences_demo.json').readAsStringSync();

  test('parses kinds, periods, privacy and who may edit', () {
    final list = parseAbsences(jsonDecode(fixture))!;
    expect(list.map((a) => a.kind), [
      AbsenceKind.holiday,
      AbsenceKind.away,
      AbsenceKind.remote,
    ]);
    expect(list.first.from, DateTime(2026, 11, 20));
    expect(list.first.covers(DateTime(2026, 11, 23, 18)), isTrue);
    expect(list.first.covers(DateTime(2026, 11, 24)), isFalse);
    expect(list[1].private, isTrue);
    expect(list.first.editable, isTrue);
    expect(parseAbsences({'x': 1}), isNull);
  });

  test('reads a range and sends the form', () async {
    final requests = <http.Request>[];
    final repo = AbsencesRepositoryRemote(
      api: ModuleApi(
        ApiClient(
          client: MockClient((r) async {
            requests.add(r);
            return r.method == 'GET'
                ? http.Response(fixture, 200)
                : http.Response('{}', 200);
          }),
        ),
      ),
    );
    expect(
      await repo.list(
        testServer(),
        from: DateTime(2026, 11, 21),
        to: DateTime(2026, 11, 22),
      ),
      isA<Ok<List<Absence>>>(),
    );
    expect(requests.last.url.queryParameters, {
      'from': '2026-11-21',
      'to': '2026-11-22',
    });

    final input = AbsenceInput(
      from: DateTime(2026, 12),
      to: DateTime(2026, 12, 3),
      kind: AbsenceKind.sick,
      note: ' flu ',
      private: true,
    );
    await repo.create(testServer(), input);
    expect(requests.last.method, 'POST');
    expect(jsonDecode(requests.last.body), {
      'from': '2026-12-01',
      'to': '2026-12-03',
      'kind': 'sick',
      'note': 'flu',
      'private': true,
    });
    await repo.create(
      testServer(),
      AbsenceInput(
        from: input.from,
        to: input.to,
        kind: input.kind,
        accountId: 'm2',
      ),
    );
    expect(
      (jsonDecode(requests.last.body) as Map<String, Object?>)['accountId'],
      'm2',
    );
    await repo.update(
      testServer(),
      'a1',
      AbsenceInput(
        from: input.from,
        to: input.to,
        kind: input.kind,
        accountId: 'm2',
      ),
    );
    expect(jsonDecode(requests.last.body), isNot(contains('accountId')));
    expect(
      (requests.last.method, requests.last.url.path),
      ('PUT', '/api/absences/a1'),
    );
    await repo.delete(testServer(), 'a1');
    expect(requests.last.method, 'DELETE');
  });

  test('lists active members for the person of an absence', () {
    final members = parseMembers({
      'available': true,
      'members': [
        {'id': 'm1', 'name': 'Anna', 'disabled': false},
        {'id': 'm2', 'name': 'Ben', 'disabled': true},
        {'name': 'no id'},
      ],
    })!;
    expect(members.map((m) => m.id), ['m1']);
    expect(parseMembers([]), isNull);
  });
}
