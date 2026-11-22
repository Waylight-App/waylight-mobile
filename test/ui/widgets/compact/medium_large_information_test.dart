import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:waylight_mobile/data/repositories/actions/read_later_repository.dart';
import 'package:waylight_mobile/data/repositories/actions/rss_repository.dart';
import 'package:waylight_mobile/data/repositories/transit/transit_repository.dart';
import 'package:waylight_mobile/data/repositories/waste/waste_repository.dart';
import 'package:waylight_mobile/data/repositories/widget_data/widget_data_repository.dart';
import 'package:waylight_mobile/data/services/api/transit_api.dart';
import 'package:waylight_mobile/data/services/api/waste_api.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/media.dart';
import 'package:waylight_mobile/ui/widgets/electricity/electricity_widget.dart';
import 'package:waylight_mobile/ui/widgets/registry.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../../testing/fakes/fake_action_repositories.dart';
import '../../../testing/fakes/fake_transit_repository.dart';
import '../../../testing/fakes/fake_waste_repository.dart';
import '../../../testing/fakes/fake_widget_data_repository.dart';
import '../../../testing/tile_harness.dart';

void main() {
  setUpAll(initializeDateFormatting);

  // Recorded from https://demo.getwaylight.app.
  Object? fixture(String name) =>
      jsonDecode(File('test/fixtures/${name}_demo.json').readAsStringSync());

  late FakeWidgetDataRepository data;
  late FakeWasteRepository waste;
  late FakeRssRepository rss;
  late FakeReadLaterRepository readLater;
  late FakeTransitRepository transit;

  setUp(() {
    data = FakeWidgetDataRepository()
      ..json['/api/fuel/overview'] = fixture('fuel_overview')
      ..json['/api/markets/watchlist'] = fixture('markets_watchlist')
      ..json['/api/electricity/prices'] = fixture('electricity_prices');
    waste = FakeWasteRepository()
      ..result = Result.ok(parseWaste(fixture('waste'))!);
    rss = FakeRssRepository()
      ..articles = parseFeedArticles(fixture('rss_items'))!;
    readLater = FakeReadLaterRepository()
      ..list = [
        for (var i = 0; i < 12; i++)
          Article(
            id: 'a$i',
            url: Uri.parse('https://example.org/$i'),
            title: 'Article $i with a title that needs more than one line',
          ),
      ];
    transit = FakeTransitRepository()
      ..result = Result.ok(parseDepartures(fixture('transit'))!);
  });

  const placements = {
    'fuel': WidgetPlacement(id: 'fuel', kind: 'fuel'),
    'markets': WidgetPlacement(id: 'markets', kind: 'markets'),
    'waste': WidgetPlacement(id: 'waste', kind: 'waste'),
    'rss': WidgetPlacement(id: 'rss', kind: 'rss'),
    'readlater': WidgetPlacement(id: 'readlater', kind: 'readlater'),
    'transit': WidgetPlacement(
      id: 'transit',
      kind: 'transit',
      config: {'stop': 'demo', 'stopName': 'Demo stop'},
    ),
    'electricity': WidgetPlacement(
      id: 'electricity',
      kind: 'electricity',
      config: {'zone': 'AT'},
    ),
  };

  for (final MapEntry(key: kind, value: placement) in placements.entries) {
    for (final size in tiles.keys) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('$kind fits a ${size.name} tile at ${scale}x text (#211)', (
          tester,
        ) async {
          await pumpTile(
            tester,
            size: size,
            scale: scale,
            providers: [
              Provider<WidgetDataRepository>.value(value: data),
              Provider<WasteRepository>.value(value: waste),
              Provider<RssRepository>.value(value: rss),
              Provider<ReadLaterRepository>.value(value: readLater),
              Provider<TransitRepository>.value(value: transit),
            ],
            child: Builder(
              builder: (context) => kind == 'electricity'
                  ? ElectricityWidget(
                      widget: placement,
                      now: () => DateTime.parse('2026-11-19T00:30:00+01:00'),
                    )
                  : nativeWidgets.builderFor(kind)!(context, placement),
            ),
          );

          // An overflow would have failed the test with an exception.
          expectFits(tester, size, scale);
        });
      }
    }
  }
}
