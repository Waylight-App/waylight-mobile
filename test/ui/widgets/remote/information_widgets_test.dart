import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/data/repositories/widget_data/queries/information.dart';
import 'package:waylight_mobile/data/repositories/widget_data/widget_data_repository.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/ui/core/link_opener.dart';
import 'package:waylight_mobile/ui/widgets/calendar/calendar_widget.dart';
import 'package:waylight_mobile/ui/widgets/markets/markets_widget.dart';
import 'package:waylight_mobile/ui/widgets/registry.dart';

import '../../../testing/fakes/fake_link_opener.dart';
import '../../../testing/fakes/fake_server_repository.dart';
import '../../../testing/fakes/fake_widget_data_repository.dart';
import '../../../testing/pump_app.dart';

void main() {
  setUpAll(initializeDateFormatting);

  // Recorded from https://demo.getwaylight.app.
  Object? fixture(String name) =>
      jsonDecode(File('test/fixtures/${name}_demo.json').readAsStringSync());

  const endpoints = {
    '/api/fuel/overview': 'fuel_overview',
    '/api/markets/watchlist': 'markets_watchlist',
    '/api/arr/overview': 'arr_overview',
    '/api/media/overview': 'media_overview',
    '/api/immich/overview': 'immich_overview',
    '/api/nextcloud/status': 'nextcloud_status',
    '/api/releases': 'releases',
    '/api/gamedeals/overview': 'gamedeals_overview',
    '/api/space/launches': 'space_launches',
    '/api/study/progress': 'study_progress',
    '/api/phonelist/entries': 'phonelist_entries',
    '/api/briefing': 'briefing',
    '/api/calendar/events': 'calendar_events',
    '/api/sports/overview': 'sports_overview',
  };

  late FakeWidgetDataRepository data;
  late FakeLinkOpener links;

  setUp(() {
    data = FakeWidgetDataRepository();
    for (final MapEntry(:key, :value) in endpoints.entries) {
      data.json[key] = fixture(value);
    }
    links = FakeLinkOpener();
  });

  Future<void> pump(
    WidgetTester tester,
    Widget Function(BuildContext) build,
  ) async {
    await tester.pumpScreen(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ServerRepository>.value(
            value: FakeServerRepository(current: testServer()),
          ),
          Provider<WidgetDataRepository>.value(value: data),
        ],
        child: LinkOpenerScope(
          opener: links,
          child: SingleChildScrollView(child: Builder(builder: build)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpKind(WidgetTester tester, String kind) => pump(
    tester,
    (context) => nativeWidgets.builderFor(kind)!(
      context,
      WidgetPlacement(id: kind, kind: kind),
    ),
  );

  test('the parsers read the demo', () {
    expect(parseFuel(fixture('fuel_overview'))!.stations.first.brand, 'JET');
    expect(parseMarkets(fixture('markets_watchlist'))!.first.symbol, 'fx:USD');
    expect(parseArr(fixture('arr_overview'))!.map((s) => s.title), [
      'arr.health',
      'arr.upcoming',
      'arr.queue',
    ]);
    expect(parseMedia(fixture('media_overview'))!.first.title, 'media.playing');
    expect(parseImmich(fixture('immich_overview'))!.photos, 18432);
    expect(parseNextcloud(fixture('nextcloud_status'))!.users, 4);
    expect(parseReleases(fixture('releases'))!.single.items, isNotEmpty);
    expect(
      parseGameDeals(fixture('gamedeals_overview'))!.first.title,
      'gamedeals.free',
    );
    expect(
      parseLaunches(fixture('space_launches'))!.single.items.first.title,
      'Starlink Group 12-7',
    );
    expect(
      parseStudy(fixture('study_progress'))!.inProgress,
      contains('Computer Networks'),
    );
    expect(
      parsePhoneList(fixture('phonelist_entries'))!.first.dial,
      '+494415550100',
    );
    expect(
      parseBriefing(fixture('briefing'))!.first.title,
      'briefing.warnings',
    );
    expect(
      parseCalendar(fixture('calendar_events'))!.first.summary,
      'Team call',
    );
    expect(
      parseSports(fixture('sports_overview'))!.rows.first.team,
      'Musterstadt',
    );
  });

  for (final kind in [
    'fuel',
    'markets',
    'arr',
    'media',
    'immich',
    'nextcloud',
    'releases',
    'gamedeals',
    'space',
    'study',
    'phonelist',
    'briefing',
    'calendar',
    'sports',
  ]) {
    testWidgets('$kind renders the demo data', (tester) async {
      await pumpKind(tester, kind);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text(l10nEn.listEmpty), findsNothing);
    });
  }

  testWidgets('markets ask for the symbols of the settings', (tester) async {
    await pump(
      tester,
      (context) => const MarketsWidget(
        widget: WidgetPlacement(
          id: 'm',
          kind: 'markets',
          config: {
            'symbols': ['fx:GBP'],
          },
        ),
      ),
    );
    expect(data.asked.last.query, {'symbols': 'fx:GBP'});
    expect(MarketsWidget.label('stooq:^dax'), 'DAX');
    expect(MarketsWidget.label('fx:USD'), 'EUR/USD');
  });

  testWidgets('the calendar groups by day; the phone list calls', (
    tester,
  ) async {
    await pump(
      tester,
      (context) => CalendarWidget(
        widget: const WidgetPlacement(id: 'c', kind: 'calendar'),
        now: () => DateTime.utc(2026, 11, 19, 21).toLocal(),
      ),
    );
    expect(find.text('Team call'), findsOneWidget);
    expect(find.text(l10nEn.todosTomorrow), findsOneWidget);

    await pumpKind(tester, 'phonelist');
    await tester.tap(find.text('Anna Schröder'));
    expect(links.opened.single.toString(), 'tel:+494415550100');
  });

  testWidgets('the briefing shows its sections', (tester) async {
    await pumpKind(tester, 'briefing');
    expect(find.text(l10nEn.briefingWarnings), findsOneWidget);
    expect(find.text(l10nEn.briefingTodos), findsOneWidget);
  });
}
