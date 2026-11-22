import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:waylight_mobile/data/repositories/actions/read_later_repository.dart';
import 'package:waylight_mobile/data/repositories/actions/rss_repository.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/data/repositories/waste/waste_repository.dart';
import 'package:waylight_mobile/data/repositories/widget_data/widget_data_repository.dart';
import 'package:waylight_mobile/data/services/api/waste_api.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/media.dart';
import 'package:waylight_mobile/ui/core/widget_size_scope.dart';
import 'package:waylight_mobile/ui/widgets/registry.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../../testing/fakes/fake_action_repositories.dart';
import '../../../testing/fakes/fake_server_repository.dart';
import '../../../testing/fakes/fake_waste_repository.dart';
import '../../../testing/fakes/fake_widget_data_repository.dart';
import '../../../testing/pump_app.dart';

void main() {
  setUpAll(initializeDateFormatting);

  // Recorded from https://demo.getwaylight.app.
  Object? fixture(String name) =>
      jsonDecode(File('test/fixtures/${name}_demo.json').readAsStringSync());

  late FakeWidgetDataRepository data;
  late FakeWasteRepository waste;
  late FakeRssRepository rss;
  late FakeReadLaterRepository readLater;

  setUp(() {
    data = FakeWidgetDataRepository()
      ..json['/api/fuel/overview'] = fixture('fuel_overview')
      ..json['/api/markets/watchlist'] = fixture('markets_watchlist');
    waste = FakeWasteRepository()
      ..result = Result.ok(parseWaste(fixture('waste'))!);
    rss = FakeRssRepository()
      ..articles = parseFeedArticles(fixture('rss_items'))!;
    readLater = FakeReadLaterRepository()
      ..list = [
        Article(
          id: 'a',
          url: Uri.parse('https://example.org/a'),
          title: 'A long article title that needs more than one line',
        ),
      ];
  });

  test('the radar needs a tall tile', () {
    expect(nativeWidgets.sizesFor('radar').supported, [
      WidgetSize.medium,
      WidgetSize.large,
    ]);
    expect(nativeWidgets.sizesFor('radar').defaultSize, WidgetSize.large);
  });

  const keyText = {
    'fuel': '€',
    'markets': 'EUR/USD',
    'waste': 'Organic waste',
    'rss': 'unread',
    'readlater': 'unread',
  };

  for (final kind in keyText.keys) {
    for (final (size, pixels) in [
      (WidgetSize.small, const Size(150, 150)),
      (WidgetSize.strip, const Size(328, 70)),
    ]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('$kind fits a ${size.name} tile at ${scale}x text (#211)', (
          tester,
        ) async {
          await tester.pumpScreen(
            MultiProvider(
              providers: [
                ChangeNotifierProvider<ServerRepository>.value(
                  value: FakeServerRepository(current: testServer()),
                ),
                Provider<WidgetDataRepository>.value(value: data),
                Provider<WasteRepository>.value(value: waste),
                Provider<RssRepository>.value(value: rss),
                Provider<ReadLaterRepository>.value(value: readLater),
              ],
              child: Builder(
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(scale)),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: SizedBox.fromSize(
                      size: pixels,
                      child: WidgetSizeScope(
                        size: size,
                        child: nativeWidgets.builderFor(kind)!(
                          context,
                          WidgetPlacement(id: kind, kind: kind),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          // An overflow would have failed the test with an exception.
          expect(find.textContaining(keyText[kind]!), findsWidgets);
        });
      }
    }
  }
}
