import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:waylight_mobile/data/services/api/api_client.dart';
import 'package:waylight_mobile/data/services/api/dashboard_api.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../../testing/fakes/fake_server_repository.dart';

void main() {
  // Recorded from https://demo.getwaylight.app (GET /api/dashboard).
  final demo = File('test/fixtures/dashboard_demo.json').readAsStringSync();
  final demoJson = jsonDecode(demo) as Map<String, Object?>;

  test('reads the tabs of the demo in their order', () {
    final dashboard = parseDashboard(demoJson)!;

    expect(dashboard.tabs.map((t) => t.name), [
      'Home',
      'Out and about',
      'Server',
    ]);
  });

  test('orders the widgets like the phone layout of the server', () {
    final dashboard = parseDashboard(demoJson)!;
    final tabs = demoJson['tabs']! as List<Object?>;

    for (final (i, tab) in dashboard.tabs.indexed) {
      final json = tabs.cast<Map<String, Object?>>().firstWhere(
        (t) => t['id'] == tab.id,
      );
      final expected = [
        for (final item
            in (json['mobile']! as List<Object?>).cast<Map<String, Object?>>())
          if (item['hidden'] != true) item['id'],
      ];
      expect(tab.widgets.map((w) => w.id), expected, reason: 'tab $i');
      expect(tab.widgets, isNotEmpty);
    }
  });

  test('keeps kind, title and configuration', () {
    final dashboard = parseDashboard({
      'tabs': [
        {
          'id': 't',
          'name': 'Tab',
          'position': 0,
          'widgets': [
            {
              'id': 'w',
              'kind': 'clock',
              'x': 0,
              'y': 0,
              'config': {'title': ' Kitchen ', 'zone': 'Europe/Berlin'},
            },
          ],
        },
      ],
    })!;

    final widget = dashboard.tabs.single.widgets.single;
    expect(widget.kind, 'clock');
    expect(widget.title, 'Kitchen');
    expect(widget.config['zone'], 'Europe/Berlin');
  });

  test('rejects JSON that is not a dashboard', () {
    expect(parseDashboard(null), isNull);
    expect(parseDashboard({'tabs': 'no'}), isNull);
    expect(
      parseDashboard({
        'tabs': [
          {
            'id': 't',
            'name': 'x',
            'widgets': [
              {'id': 'w'},
            ],
          },
        ],
      }),
      isNull,
    );
  });

  test('loads the dashboard over the client', () async {
    final api = DashboardApi(
      ApiClient(
        client: MockClient((request) async {
          expect(request.url.path, '/api/dashboard');
          return http.Response(demo, 200);
        }),
      ),
    );

    final result = await api.dashboard(testServer());

    expect((result as Ok<Dashboard>).value.tabs, hasLength(3));
  });

  test('fails on an answer that is not a dashboard', () async {
    final api = DashboardApi(
      ApiClient(client: MockClient((_) async => http.Response('[]', 200))),
    );

    final result = await api.dashboard(testServer());

    expect(
      ((result as Error<Dashboard>).error as ApiException).failure,
      ApiFailure.server,
    );
  });

  group('widget sizes (#208)', () {
    Map<String, Object?> tab(List<Map<String, Object?>> mobile) => {
      'tabs': [
        {
          'id': 't',
          'name': 'Home',
          'widgets': [
            {'id': 'a', 'kind': 'clock', 'x': 0, 'y': 0},
            {'id': 'b', 'kind': 'notes', 'x': 0, 'y': 4},
          ],
          'mobile': mobile,
        },
      ],
    };

    test('reads sizes and knows the server has them', () {
      final parsed = parseDashboard(
        tab([
          {'id': 'a', 'hidden': false, 'rows': 1, 'size': 'small'},
          {'id': 'b', 'hidden': false, 'rows': 1, 'size': ''},
        ]),
      )!.tabs.single;

      expect(parsed.sizesOnServer, isTrue);
      expect(parsed.sizes, {'a': WidgetSize.small});
      expect(parsed.layout.map((i) => i.size), [WidgetSize.small, null]);
    });

    test('knows when the server has no sizes', () {
      final parsed = parseDashboard(
        tab([
          {'id': 'a', 'hidden': false, 'rows': 1},
        ]),
      )!.tabs.single;

      expect(parsed.sizesOnServer, isFalse);
      expect(parsed.sizes, isEmpty);
    });
  });
}
