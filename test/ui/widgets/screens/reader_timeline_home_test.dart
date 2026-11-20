import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:waylight_mobile/data/repositories/actions/rss_repository.dart';
import 'package:waylight_mobile/data/repositories/actions/smarthome_repository.dart';
import 'package:waylight_mobile/data/repositories/actions/summary_repository.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/data/repositories/widget_data/queries/home_server.dart';
import 'package:waylight_mobile/data/repositories/widget_data/widget_data_repository.dart';
import 'package:waylight_mobile/domain/models/actions.dart';
import 'package:waylight_mobile/domain/models/home_server.dart';
import 'package:waylight_mobile/ui/core/link_opener.dart';
import 'package:waylight_mobile/ui/widgets/common/items_view_model.dart';
import 'package:waylight_mobile/ui/widgets/common/remote_widget.dart';
import 'package:waylight_mobile/ui/widgets/rss/rss_reader_view_model.dart';
import 'package:waylight_mobile/ui/widgets/rss/rss_screen.dart';
import 'package:waylight_mobile/ui/widgets/smarthome/smarthome_screen.dart';
import 'package:waylight_mobile/ui/widgets/timeline/timeline_screen.dart';

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
  final summaries = FakeSummaryRepository()..configured = true;

  Future<void> pump(
    WidgetTester tester,
    Widget screen,
    List<Provider<Object?>> extra,
  ) async {
    await tester.pumpScreen(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ServerRepository>.value(value: servers),
          Provider<SummaryRepository>.value(value: summaries),
          ...extra,
        ],
        child: LinkOpenerScope(opener: FakeLinkOpener(), child: screen),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the reader filters by feed and marks all read', (tester) async {
    final rss = FakeRssRepository()
      ..articles = parseFeedArticles(fixture('rss_items'))!
      ..feedList = parseFeeds(fixture('rss_feeds'))!;
    final vm = RssReaderViewModel(serverRepository: servers, rss: rss);
    addTearDown(vm.dispose);
    await pump(tester, RssScreen(viewModel: vm), [
      Provider<RssRepository>.value(value: rss),
    ]);
    expect(find.text('Welcome to the Waylight demo'), findsOneWidget);

    final feed = rss.feedList.first;
    await tester.tap(find.text('${feed.title} (${feed.unread})'));
    await tester.pumpAndSettle();
    expect(vm.feedId, rss.feedList.first.id);

    await tester.tap(find.byTooltip(l10nEn.rssAllRead));
    await tester.pumpAndSettle();
    expect(rss.calls, ['all:${rss.feedList.first.id}']);
  });

  testWidgets('the timeline filters by importance', (tester) async {
    final data = FakeWidgetDataRepository()
      ..json['/api/timeline'] = fixture('timeline');
    final vm = RemoteWidgetViewModel<List<TimelineEntry>>(
      server: servers,
      data: data,
      query: timelineQuery,
    );
    addTearDown(vm.dispose);
    await pump(tester, TimelineScreen(viewModel: vm), [
      Provider<WidgetDataRepository>.value(value: data),
    ]);
    final all =
        find.byType(ListTile).evaluate().length +
        find.textContaining('·').evaluate().length;
    await tester.tap(find.text(l10nEn.timelineCritical));
    await tester.pumpAndSettle();
    final critical = parseTimeline(fixture('timeline'))!
        .where((e) => e.severity == 'critical');
    expect(find.text(critical.first.message), findsOneWidget);
    expect(find.textContaining('·').evaluate().length, lessThan(all));
    expect(widgetOfSource('container'), 'docker');
  });

  testWidgets('the smart home screen groups entities by domain', (
    tester,
  ) async {
    final home = FakeSmartHomeRepository()
      ..list = parseEntities(fixture('smarthome_entities'))!;
    final vm = ItemsViewModel<SmartEntity>(
      serverRepository: servers,
      fetch: home.entities,
      id: (e) => e.id,
    );
    addTearDown(vm.dispose);
    await pump(tester, SmartHomeScreen(viewModel: vm), [
      Provider<SmartHomeRepository>.value(value: home),
    ]);
    expect(find.text('sensor'), findsOneWidget);
    expect(find.text('Balcony solar'), findsOneWidget);
  });

  testWidgets('a long press on an article summarises it', (tester) async {
    final rss = FakeRssRepository()
      ..articles = parseFeedArticles(fixture('rss_items'))!
      ..feedList = parseFeeds(fixture('rss_feeds'))!;
    final vm = RssReaderViewModel(serverRepository: servers, rss: rss);
    addTearDown(vm.dispose);
    await pump(tester, RssScreen(viewModel: vm), []);
    await tester.longPress(find.byType(ListTile).first);
    await tester.pumpAndSettle();
    expect(find.text('In short: keep three copies.'), findsOneWidget);
    expect(summaries.calls.last, startsWith('summarise:http'));
  });
}
