import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:waylight_mobile/data/repositories/attention/attention_repository.dart';
import 'package:waylight_mobile/data/services/api/api_client.dart';
import 'package:waylight_mobile/data/services/api/module_api.dart';
import 'package:waylight_mobile/domain/models/attention.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../../testing/fakes/fake_server_repository.dart';

/// The attention list (#229), with an answer in the server's shape.
void main() {
  final fixture = File('test/fixtures/attention_demo.json').readAsStringSync();

  test('parses entries with kind, action, widget and reason', () {
    final items = parseAttention(jsonDecode(fixture))!;
    expect(items.map((i) => i.id), [
      'module:immich',
      'module:grafana',
      'widget:w-transit',
      'module:nextcloud',
    ]);
    final transit = items[2];
    expect(transit.kind, AttentionKind.setup);
    expect(transit.action, AttentionAction.choose);
    expect(transit.field, 'stopId');
    expect(transit.tabId, 't-home');
    expect(transit.widgetId, 'w-transit');
    expect(transit.message, 'Please choose a stop in the widget settings.');
    expect(items.first.kind, AttentionKind.connection);
    expect(items.first.action, AttentionAction.fix);
    expect(items.first.since, DateTime.utc(2026, 11, 21, 8, 12));
  });

  test('tolerates unknown values and skips entries without an id', () {
    final items = parseAttention({
      'items': [
        {
          'id': 'module:x',
          'kind': 'new',
          'action': 'later',
          'integration': 'x',
        },
        {'kind': 'setup'},
        'nonsense',
      ],
      'count': 3,
    })!;
    expect(items, hasLength(1));
    expect(items.single.kind, AttentionKind.setup);
    expect(items.single.action, AttentionAction.check);
    expect(items.single.title, 'x', reason: 'falls back to the integration');
    expect(parseAttention({'count': 0}), isNull);
    expect(parseAttention({'items': <Object?>[], 'count': 0}), isEmpty);
  });

  test('keeps the last list, tells listeners and forgets it', () async {
    var answer = http.Response(fixture, 200);
    final repo = AttentionRepositoryRemote(
      api: ModuleApi(
        ApiClient(
          client: MockClient((r) async {
            expect(r.url.path, '/api/attention');
            return answer;
          }),
        ),
      ),
    );
    var notified = 0;
    repo.addListener(() => notified++);

    expect(await repo.refresh(testServer()), isA<Ok<List<AttentionItem>>>());
    expect(repo.items, hasLength(4));
    expect(notified, 1);

    answer = http.Response('', 500);
    expect(await repo.refresh(testServer()), isA<Error<List<AttentionItem>>>());
    expect(repo.items, hasLength(4), reason: 'a failure keeps the old list');

    await repo.clear();
    expect(repo.items, isEmpty);
    expect(notified, 2);
    await repo.clear();
    expect(notified, 2, reason: 'nothing to forget');
  });
}
