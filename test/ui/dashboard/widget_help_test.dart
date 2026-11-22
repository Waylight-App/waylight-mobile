import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';
import 'package:waylight_mobile/data/repositories/help/help_repository.dart';
import 'package:waylight_mobile/data/services/api/api_client.dart';
import 'package:waylight_mobile/data/services/api/help_api.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/compact_state.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/help.dart';
import 'package:waylight_mobile/ui/core/link_opener.dart';
import 'package:waylight_mobile/ui/core/widget_registry.dart';
import 'package:waylight_mobile/ui/dashboard/view_models/dashboard_view_model.dart';
import 'package:waylight_mobile/ui/dashboard/widgets/dashboard_screen.dart';
import 'package:waylight_mobile/ui/dashboard/widgets/widget_card.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../testing/fakes/fake_dashboard_repository.dart';
import '../../testing/fakes/fake_help_repository.dart';
import '../../testing/fakes/fake_link_opener.dart';
import '../../testing/fakes/fake_server_repository.dart';
import '../../testing/pump_app.dart';

void main() {
  group('API', () {
    test('reads the help and leaves out entries it cannot use', () {
      final help = parseWidgetHelp({
        'widgets': [
          {
            'kind': 'docker',
            'shows': {'text': 'Your containers.', 'key': 'help.docker.shows'},
            'setUp': {'text': 'Enter the address.'},
            'docsUrl': 'https://getwaylight.app/docs/modules/docker/',
          },
          {'kind': 'broken'},
          {
            'kind': 'noUrl',
            'shows': {'text': 'a'},
            'setUp': {'text': 'b'},
            'docsUrl': 'docs',
          },
        ],
      })!;

      expect(help.map((h) => h.kind), ['docker']);
      expect(help.single.shows.key, 'help.docker.shows');
      expect(help.single.docsUrl.host, 'getwaylight.app');
    });

    test('rejects an answer without the list', () {
      expect(parseWidgetHelp({'other': 1}), isNull);
    });

    group('request', () {
      final requests = <Uri>[];
      late HelpRepositoryRemote repository;
      HelpRepositoryRemote create() => HelpRepositoryRemote(
        api: HelpApi(
          ApiClient(
            client: MockClient((request) async {
              requests.add(request.url);
              return http.Response('{"widgets": []}', 200);
            }),
          ),
        ),
      );

      setUp(() {
        requests.clear();
        repository = create();
      });

      test('sends the app language as lang', () async {
        await repository.helpOf(testServer(), 'docker', language: 'de');

        expect(requests.single.path, '/api/help/widgets');
        expect(requests.single.queryParameters, {'lang': 'de'});
      });

      test('keeps the texts of each language apart', () async {
        await repository.helpOf(testServer(), 'docker', language: 'en');
        await repository.helpOf(testServer(), 'meters', language: 'en');
        await repository.helpOf(testServer(), 'docker', language: 'de');

        expect(requests.map((u) => u.queryParameters['lang']), ['en', 'de']);
      });

      test('sends no lang without a language', () async {
        await repository.helpOf(testServer(), 'docker');

        expect(requests.last.queryParameters, isEmpty);
      });
    });
  });

  group('screen', () {
    late FakeServerRepository servers;
    late FakeDashboardRepository dashboards;
    late FakeHelpRepository help;
    late FakeLinkOpener opener;

    setUp(() {
      servers = FakeServerRepository(current: testServer());
      dashboards = FakeDashboardRepository()
        ..result = const Result.ok(
          Dashboard(
            tabs: [
              DashboardTab(
                id: 't',
                name: 'Home',
                widgets: [WidgetPlacement(id: 'w', kind: 'docker')],
              ),
            ],
          ),
        );
      help = FakeHelpRepository()
        ..byKind = {
          'docker': WidgetHelp(
            kind: 'docker',
            shows: const CompactText(text: 'Your containers.'),
            setUp: const CompactText(text: 'Enter the address.'),
            docsUrl: Uri.parse('https://getwaylight.app/docs/modules/docker/'),
          ),
        };
      opener = FakeLinkOpener();
    });

    Future<void> pump(
      WidgetTester tester, {
      bool withHelp = true,
      Locale locale = const Locale('en'),
    }) async {
      await tester.pumpScreen(
        locale: locale,
        LinkOpenerScope(
          opener: opener,
          child: DashboardScreen(
            viewModel: DashboardViewModel(
              serverRepository: servers,
              dashboardRepository: dashboards,
              helpRepository: withHelp ? help : null,
            ),
            registry: const WidgetRegistry({}),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> openHelp(WidgetTester tester) async {
      await tester.longPress(find.byType(WidgetCard));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('dashboard.help')));
      await tester.pumpAndSettle();
    }

    testWidgets('holding a widget offers the help and the edit mode', (
      tester,
    ) async {
      await pump(tester);
      await tester.longPress(find.byType(WidgetCard));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('dashboard.help')), findsOneWidget);
      expect(find.byKey(const ValueKey('dashboard.arrange')), findsOneWidget);
    });

    testWidgets('shows what the widget shows and how to set it up', (
      tester,
    ) async {
      await pump(tester);
      await openHelp(tester);

      expect(help.asked, ['docker']);
      expect(find.text('Your containers.'), findsOneWidget);
      expect(find.text('Enter the address.'), findsOneWidget);

      await tester.tap(find.text('Read more in the documentation'));
      await tester.pump();
      expect(opener.opened.single.path, '/docs/modules/docker/');
    });

    testWidgets('asks for the texts in the app language', (tester) async {
      await pump(tester, locale: const Locale('de'));
      await openHelp(tester);

      expect(help.languages, ['de']);
    });

    testWidgets('says so when the help cannot be loaded', (tester) async {
      help.failure = const Result.error(ApiException(ApiFailure.server));
      await pump(tester);
      await openHelp(tester);

      expect(find.textContaining('could not be loaded'), findsOneWidget);
      await tester.tap(find.text('Read more in the documentation'));
      await tester.pump();
      expect(opener.opened.single, documentationUrl);
    });

    testWidgets('without help a held widget opens the edit mode', (
      tester,
    ) async {
      await pump(tester, withHelp: false);
      await tester.longPress(find.byType(WidgetCard));
      await tester.pump(const Duration(seconds: 1));

      expect(find.byKey(const ValueKey('dashboard.help')), findsNothing);
      expect(find.byKey(const ValueKey('arrange')), findsOneWidget);
    });
  });
}
