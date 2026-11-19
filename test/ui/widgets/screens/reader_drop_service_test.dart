import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:waylight_mobile/data/repositories/actions/drop_repository.dart';
import 'package:waylight_mobile/data/repositories/actions/read_later_repository.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/data/repositories/widget_data/queries/media.dart';
import 'package:waylight_mobile/data/repositories/widget_data/widget_data_repository.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/ui/core/link_opener.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/app_theme.dart';
import 'package:waylight_mobile/ui/widgets/media/media_widgets.dart';
import 'package:waylight_mobile/ui/widgets/readlater/article_screen.dart';
import 'package:waylight_mobile/ui/widgets/services/service_details_screen.dart';

import '../../../testing/fakes/fake_action_repositories.dart';
import '../../../testing/fakes/fake_link_opener.dart';
import '../../../testing/fakes/fake_server_repository.dart';
import '../../../testing/fakes/fake_widget_data_repository.dart';
import '../../../testing/pump_app.dart';

void main() {
  setUpAll(initializeDateFormatting);

  // Recorded from https://demo.getwaylight.app.
  Object? fixture(String name) =>
      jsonDecode(File('test/fixtures/${name}_demo.json').readAsStringSync());

  final servers = FakeServerRepository(current: testServer());

  test('parses an article with its reader copy', () {
    final a = parseArticle(fixture('readlater_article'))!;
    expect(a.title, contains('3-2-1'));
    expect(a.content, startsWith('<p>'));
  });

  testWidgets('the reader marks an article read and archives it', (
    tester,
  ) async {
    final repo = FakeReadLaterRepository()
      ..list = [parseArticle(fixture('readlater_article'))!];
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: TextButton(
              onPressed: () => context.push('/a'),
              child: const Text('open'),
            ),
          ),
        ),
        GoRoute(
          path: '/a',
          builder: (context, state) => ArticleScreen(
            viewModel: ArticleViewModel(
              articleId: repo.list.single.id,
              serverRepository: servers,
              readLater: repo,
            ),
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      LinkOpenerScope(
        opener: FakeLinkOpener(),
        child: MaterialApp.router(
          theme: AppTheme.light,
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Three copies of your data'), findsOneWidget);
    expect(repo.calls, ['read:${repo.list.single.id}']);

    await tester.tap(find.byTooltip(l10nEn.readLaterArchive));
    await tester.pumpAndSettle();
    expect(repo.calls.last, 'archived:${repo.list.single.id}');
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('sends a text to the drop zone and deletes one', (tester) async {
    final drop = FakeDropRepository()..list = parseDrops(fixture('drop'))!;
    await tester.pumpScreen(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ServerRepository>.value(value: servers),
          Provider<DropRepository>.value(value: drop),
        ],
        child: const SingleChildScrollView(
          child: DropWidget(
            widget: WidgetPlacement(id: 'd', kind: 'drop'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10nEn.dropSend));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Door code 4711');
    await tester.tap(find.widgetWithText(FilledButton, l10nEn.dropSend));
    await tester.pumpAndSettle();
    expect(drop.calls, ['send:Door code 4711']);
    expect(find.text('Door code 4711'), findsOneWidget);

    await tester.tap(find.byTooltip(l10nEn.noteDelete).first);
    await tester.pumpAndSettle();
    expect(drop.calls.last, 'remove:new');
  });

  testWidgets('service details show uptime and say when nothing failed', (
    tester,
  ) async {
    final data = FakeWidgetDataRepository()
      ..json['/api/services/uptime'] = fixture('services_uptime')
      ..json['/api/services/incidents'] = <Object?>[];
    await tester.pumpScreen(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ServerRepository>.value(value: servers),
          Provider<WidgetDataRepository>.value(value: data),
        ],
        child: const ServiceDetailsScreen(
          id: '15e393e3e6f05a05bd0bc846b3b2bc38',
          name: 'DuckDuckGo',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(l10nEn.serviceMonth), findsOneWidget);
    expect(find.text('100 %'), findsWidgets);
    expect(find.text(l10nEn.serviceNoIncidents), findsOneWidget);
  });
}
