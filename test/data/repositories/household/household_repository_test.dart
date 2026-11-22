import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:waylight_mobile/data/repositories/household/household_repository.dart';
import 'package:waylight_mobile/data/services/api/api_client.dart';
import 'package:waylight_mobile/data/services/api/module_api.dart';
import 'package:waylight_mobile/domain/models/household.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../../testing/fakes/fake_server_repository.dart';

void main() {
  test('reads chores and leaves out records without an id', () {
    final chores = parseChores([
      {
        'id': 'c1',
        'title': 'Bins',
        'assignee': 'Anna',
        'due': '2026-11-23',
        'dueNow': true,
        'overdue': false,
      },
      {'title': 'no id'},
    ])!;

    expect(chores, hasLength(1));
    expect(chores.single.assignee, 'Anna');
    expect(chores.single.due, DateTime(2026, 11, 23));
    expect(chores.single.dueNow, isTrue);
    expect(parseChores({'not': 'a list'}), isNull);
  });

  test('reads meters with and without a reading', () {
    final meters = parseMeters([
      {
        'id': 'm1',
        'name': 'Power',
        'kind': 'electricity',
        'unit': 'kWh',
        'last': {'day': '2026-11-01', 'value': 1234.5},
      },
      {'id': 'm2', 'name': 'Water', 'last': null},
    ])!;

    expect(meters[0].lastValue, 1234.5);
    expect(meters[0].lastDay, DateTime(2026, 11));
    expect(meters[1].lastValue, isNull);
  });

  test('reads contracts, documents, gifts, board and meals', () {
    expect(
      parseContracts([
        {
          'id': 'k',
          'name': 'Internet',
          'monthlyCents': 3999,
          'deadline': '2027-01-31',
          'open': true,
          'soon': true,
        },
      ])!.single.monthlyCents,
      3999,
    );
    expect(
      parseDocuments([
        {'id': 'd', 'title': 'Washer', 'status': 'ending', 'fileName': 'a.pdf'},
      ])!.single,
      isA<DocumentRecord>()
          .having((d) => d.status, 'status', WarrantyStatus.ending)
          .having((d) => d.hasFile, 'hasFile', isTrue),
    );
    expect(
      parseGifts([
        {'id': 'g', 'person': 'Ben', 'title': 'Book', 'bought': true},
      ])!.single.bought,
      isTrue,
    );
    expect(
      parseBoard([
        {'id': 'b', 'text': 'Milk', 'pinned': true, 'expiresOn': ''},
      ])!.single.pinned,
      isTrue,
    );
    expect(
      parseMeals([
        {'id': 'x', 'dish': 'Soup', 'date': '2026-11-23', 'meal': 'dinner'},
      ])!.single.meal,
      'dinner',
    );
  });

  group('actions', () {
    final requests = <http.Request>[];
    final repository = HouseholdRepositoryRemote(
      api: ModuleApi(
        ApiClient(
          client: MockClient((request) async {
            requests.add(request);
            return http.Response('{}', 200);
          }),
        ),
      ),
    );

    setUp(requests.clear);

    test('ticks off a chore', () async {
      final result = await repository.markChoreDone(testServer(), 'c1');

      expect(result, isA<Ok<void>>());
      expect(requests.single.method, 'POST');
      expect(requests.single.url.path, '/api/chores/c1/done');
    });

    test('adds a reading with the day and the value', () async {
      await repository.addReading(
        testServer(),
        'm1',
        day: DateTime(2026, 11, 2),
        value: 12.5,
      );

      expect(requests.single.url.path, '/api/meters/m1/readings');
      expect(jsonDecode(requests.single.body), {
        'day': '2026-11-02',
        'value': 12.5,
      });
    });

    test('sends the whole gift idea when it is marked as bought', () async {
      await repository.setGiftBought(
        testServer(),
        const GiftIdea(id: 'g', person: 'Ben', title: 'Book', note: 'blue'),
        bought: true,
      );

      expect(requests.single.method, 'PUT');
      expect(jsonDecode(requests.single.body), {
        'person': 'Ben',
        'title': 'Book',
        'link': '',
        'note': 'blue',
        'bought': true,
      });
    });

    test('asks for a week of meals from a day', () async {
      await repository.meals(testServer(), from: DateTime(2026, 11, 23));

      expect(requests.single.url.queryParameters, {
        'from': '2026-11-23',
        'days': '7',
      });
    });
  });
}
