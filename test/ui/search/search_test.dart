import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/data/services/api/search_api.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/search.dart';
import 'package:waylight_mobile/ui/core/link_opener.dart';
import 'package:waylight_mobile/ui/search/view_models/search_view_model.dart';
import 'package:waylight_mobile/ui/search/widgets/search_screen.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../testing/fakes/fake_dashboard_repository.dart';
import '../../testing/fakes/fake_link_opener.dart';
import '../../testing/fakes/fake_search_repository.dart';
import '../../testing/fakes/fake_server_repository.dart';
import '../../testing/fakes/fake_todos_repository.dart';
import '../../testing/pump_app.dart';

void main() {
  // The settings of https://demo.getwaylight.app, plus own keywords.
  final settings = parseSearchSettings({
    'defaultProvider': 'duckduckgo',
    'providers': [
      {'id': 'duckduckgo', 'name': 'DuckDuckGo'},
    ],
    'shortcuts': [
      {
        'keyword': 'maps',
        'name': 'OpenStreetMap',
        'urlTemplate': 'https://www.openstreetmap.org/search?query={query}',
      },
    ],
    'keywords': [
      {
        'keyword': 'nas',
        'kind': 'url',
        'target': 'https://nas.local',
        'label': 'NAS',
      },
      {'keyword': 'w', 'kind': 'widget', 'target': 'w2', 'label': ''},
      {
        'keyword': 'news',
        'kind': 'query',
        'target': 'tagesschau',
        'label': 'News',
      },
    ],
    'bar': {
      'openInNewTab': false,
      'capturePrefixes': {'todo': 't', 'note': 'n', 'bookmark': 'b'},
    },
  })!;
  const dashboard = Dashboard(
    tabs: [
      DashboardTab(
        id: 't1',
        name: 'Home',
        widgets: [WidgetPlacement(id: 'w1', kind: 'weather', title: 'Berlin')],
      ),
      DashboardTab(
        id: 't2',
        name: 'Server',
        widgets: [WidgetPlacement(id: 'w2', kind: 'docker')],
      ),
    ],
  );

  group('results', () {
    test('quick capture of a to-do', () {
      expect(
        searchResults('t Buy milk', settings, dashboard).first,
        isA<CaptureTodo>().having((r) => r.title, 'title', 'Buy milk'),
      );
    });

    test('own keywords and shortcuts', () {
      final nas =
          searchResults('nas', settings, dashboard).first as OpenAddress;
      expect(nas.uri, Uri.parse('https://nas.local'));

      final maps =
          searchResults('!maps Berlin Mitte', settings, dashboard).first
              as OpenAddress;
      expect(
        maps.uri.toString(),
        'https://www.openstreetmap.org/search?query=Berlin+Mitte',
      );

      final news =
          searchResults('news sport', settings, dashboard).first as OpenAddress;
      expect(news.uri.queryParameters['q'], 'tagesschau sport');

      final widget =
          searchResults('w', settings, dashboard).first as OpenWidget;
      expect(widget.tab.id, 't2');
    });

    test('widgets by title or kind', () {
      final results = searchResults('berl', settings, dashboard);
      expect(
        results.single,
        isA<OpenWidget>().having((r) => r.tab.name, 'tab', 'Home'),
      );
      expect(searchResults('docker', settings, dashboard), isNotEmpty);
      expect(searchResults('  ', settings, dashboard), isEmpty);
    });

    test('the web search of the provider', () {
      expect(
        webSearch('google', 'a b').toString(),
        'https://www.google.com/search?q=a+b',
      );
      expect(webSearch('unknown', 'x').host, 'duckduckgo.com');
    });
  });

  group('screen', () {
    late FakeTodosRepository todos;
    late FakeLinkOpener opener;

    Future<SearchViewModel> pump(WidgetTester tester) async {
      todos = FakeTodosRepository();
      opener = FakeLinkOpener();
      final viewModel = SearchViewModel(
        serverRepository: FakeServerRepository(current: testServer()),
        searchRepository: FakeSearchRepository()..result = Result.ok(settings),
        dashboardRepository: FakeDashboardRepository()
          ..result = const Result.ok(dashboard),
        todosRepository: todos,
        debounce: Duration.zero,
      );
      await tester.pumpScreen(
        LinkOpenerScope(
          opener: opener,
          child: SearchScreen(viewModel: viewModel),
        ),
      );
      await tester.pumpAndSettle();
      return viewModel;
    }

    testWidgets('adds a to-do from the quick capture', (tester) async {
      await pump(tester);

      await tester.enterText(
        find.byKey(const ValueKey('search.field')),
        't Buy milk',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10nEn.searchAddTodo('Buy milk')));
      await tester.pumpAndSettle();

      expect(todos.writes, ['create Buy milk']);
      expect(find.text(l10nEn.searchTodoAdded('Buy milk')), findsOneWidget);
    });

    testWidgets('always offers the web search', (tester) async {
      await pump(tester);

      await tester.enterText(
        find.byKey(const ValueKey('search.field')),
        'waylight',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('search.web')));
      await tester.pump();

      expect(
        opener.opened.single.toString(),
        'https://duckduckgo.com/?q=waylight',
      );
    });
  });

  test('starts with the text of a shortcut', () {
    final viewModel = SearchViewModel(
      serverRepository: FakeServerRepository(current: testServer()),
      searchRepository: FakeSearchRepository(),
      dashboardRepository: FakeDashboardRepository(),
      todosRepository: FakeTodosRepository(),
      initialQuery: 't ',
    );

    expect(viewModel.query, 't ');
    viewModel.dispose();
  });

  test('reads the pages of the wiki search', () {
    final hits = parseWikiHits({
      'pages': [
        {
          'title': 'Backups',
          'url': 'https://wiki.example.org/books/ops/backups',
          'wiki': 'BookStack',
          'excerpt': 'restic …',
        },
        {'title': 'Broken', 'url': 'not a url'},
      ],
      'failed': <Object?>[],
    })!;
    expect(hits.single.title, 'Backups');
    expect(hits.single.wiki, 'BookStack');
  });

  testWidgets('adds wiki pages after the other results', (tester) async {
    final search = FakeSearchRepository()
      ..result = Result.ok(settings)
      ..wikiHits = [
        WikiHit(
          title: 'Backups',
          url: Uri.parse('https://wiki.example.org/books/ops/backups'),
          wiki: 'BookStack',
        ),
      ];
    final opener = FakeLinkOpener();
    final viewModel = SearchViewModel(
      serverRepository: FakeServerRepository(current: testServer()),
      searchRepository: search,
      dashboardRepository: FakeDashboardRepository(),
      todosRepository: FakeTodosRepository(),
      debounce: Duration.zero,
    );
    addTearDown(viewModel.dispose);
    await tester.pumpScreen(
      LinkOpenerScope(
        opener: opener,
        child: SearchScreen(viewModel: viewModel),
      ),
    );
    await tester.enterText(
      find.byKey(const ValueKey('search.field')),
      'backup',
    );
    await tester.pumpAndSettle();
    expect(search.wikiQueries.last, 'backup');
    await tester.tap(find.text('Backups · BookStack'));
    await tester.pump();
    expect(opener.opened.single.host, 'wiki.example.org');
  });
}
