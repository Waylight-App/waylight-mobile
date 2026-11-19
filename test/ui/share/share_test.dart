import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/routing/router.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/app_theme.dart';
import 'package:waylight_mobile/ui/share/view_models/share_view_model.dart';
import 'package:waylight_mobile/ui/share/widgets/share_screen.dart';

import '../../testing/fakes/fake_action_repositories.dart';
import '../../testing/fakes/fake_bookmarks_repository.dart';
import '../../testing/fakes/fake_notes_repository.dart';
import '../../testing/fakes/fake_server_repository.dart';
import '../../testing/fakes/fake_todos_repository.dart';
import '../../testing/fakes/fake_widget_data_repository.dart';
import '../../testing/pump_app.dart';

void main() {
  late FakeWidgetDataRepository data;
  late FakeTodosRepository todos;
  late FakeReadLaterRepository readLater;
  late FakeDropRepository drop;

  setUp(() {
    data = FakeWidgetDataRepository()
      ..json['/api/modules'] = {
        'modules': ['todos', 'notes', 'readlater', 'drop'],
      };
    todos = FakeTodosRepository();
    readLater = FakeReadLaterRepository();
    drop = FakeDropRepository();
  });

  ShareViewModel create(String text) => ShareViewModel(
    text: text,
    serverRepository: FakeServerRepository(current: testServer()),
    data: data,
    todos: todos,
    notes: FakeNotesRepository(),
    readLater: readLater,
    bookmarks: FakeBookmarksRepository(),
    drop: drop,
  );

  test('finds the first link of the shared text', () {
    expect(
      firstLink('Read this: https://example.org/a?b=1 later')?.host,
      'example.org',
    );
    expect(firstLink('no link here'), isNull);
  });

  test('a shared link maps to the share route', () {
    final route = routeOf(
      Uri.parse('waylight://share?text=Hello%20https%3A%2F%2Fexample.org'),
    );
    expect(route.path, '/share');
    expect(route.queryParameters['text'], 'Hello https://example.org');
  });

  test('offers only the targets of enabled modules', () async {
    final withLink = create('Backups https://example.org/backups');
    await withLink.load.execute();
    expect(withLink.targets, [
      ShareTarget.todo,
      ShareTarget.note,
      ShareTarget.readLater,
      ShareTarget.drop,
    ]);
    final plain = create('Buy milk');
    await plain.load.execute();
    expect(plain.targets, isNot(contains(ShareTarget.readLater)));
  });

  testWidgets('saves a shared link to read later and returns home', (
    tester,
  ) async {
    final vm = create('Backups https://example.org/backups');
    addTearDown(vm.dispose);
    final router = GoRouter(
      initialLocation: '/share',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const Text('home')),
        GoRoute(
          path: '/share',
          builder: (context, state) => ShareScreen(viewModel: vm),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light,
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10nEn.readLaterTitle));
    await tester.pumpAndSettle();
    expect(readLater.calls, ['save:https://example.org/backups']);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('saves text as a to-do', (tester) async {
    final vm = create('Buy milk');
    addTearDown(vm.dispose);
    await tester.pumpScreen(ShareScreen(viewModel: vm));
    await tester.pumpAndSettle();
    expect(find.text(l10nEn.shareTodo), findsOneWidget);
    await vm.save.execute(ShareTarget.drop);
    expect(drop.calls, ['send:Buy milk']);
  });
}
