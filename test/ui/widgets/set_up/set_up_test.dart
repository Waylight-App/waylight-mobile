import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:waylight_mobile/data/repositories/dashboard/dashboard_repository.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/data/repositories/transit/transit_repository.dart';
import 'package:waylight_mobile/data/repositories/waste/waste_repository.dart';
import 'package:waylight_mobile/data/repositories/weather/weather_repository.dart';
import 'package:waylight_mobile/data/services/api/api_client.dart';
import 'package:waylight_mobile/data/services/api/dashboard_api.dart';
import 'package:waylight_mobile/data/services/api/transit_api.dart';
import 'package:waylight_mobile/data/services/api/waste_api.dart';
import 'package:waylight_mobile/data/services/api/weather_api.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/place.dart';
import 'package:waylight_mobile/ui/core/widget_size_scope.dart';
import 'package:waylight_mobile/ui/core/widgets/choice_search_sheet.dart';
import 'package:waylight_mobile/ui/widgets/transit/transit_widget.dart';
import 'package:waylight_mobile/ui/widgets/waste/waste_widget.dart';
import 'package:waylight_mobile/ui/widgets/weather/weather_widget.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../../testing/fakes/fake_dashboard_repository.dart';
import '../../../testing/fakes/fake_server_repository.dart';
import '../../../testing/fakes/fake_transit_repository.dart';
import '../../../testing/fakes/fake_waste_repository.dart';
import '../../../testing/fakes/fake_weather_repository.dart';
import '../../../testing/pump_app.dart';

/// Widgets without their settings offer *Set up* (#230).
void main() {
  setUpAll(initializeDateFormatting);

  late FakeTransitRepository transit;
  late FakeWeatherRepository weather;
  late FakeWasteRepository waste;
  late FakeDashboardRepository dashboard;

  setUp(() {
    transit = FakeTransitRepository();
    weather = FakeWeatherRepository();
    waste = FakeWasteRepository();
    dashboard = FakeDashboardRepository();
  });

  Future<void> pump(
    WidgetTester tester,
    Widget Function(BuildContext, WidgetPlacement) builder,
    WidgetPlacement placement, {
    WidgetSize? size,
  }) async {
    final child = Builder(builder: (context) => builder(context, placement));
    await tester.pumpScreen(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ServerRepository>.value(
            value: FakeServerRepository(current: testServer()),
          ),
          Provider<TransitRepository>.value(value: transit),
          Provider<WeatherRepository>.value(value: weather),
          Provider<WasteRepository>.value(value: waste),
          Provider<DashboardRepository>.value(value: dashboard),
        ],
        child: size == null
            ? SingleChildScrollView(child: child)
            : SizedBox(
                width: 180,
                height: 180,
                child: WidgetSizeScope(size: size, child: child),
              ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> search(WidgetTester tester, String query) async {
    await tester.enterText(
      find.byKey(const ValueKey('choiceSearch.field')),
      query,
    );
    await tester.pump(ChoiceSearchSheet.debounce);
    await tester.pumpAndSettle();
  }

  testWidgets('departures: chooses a stop and keeps the other settings', (
    tester,
  ) async {
    transit.stopsResult = const Result.ok([
      Stop(id: 'de:03403:10', name: 'Oldenburg Hbf'),
    ]);
    const placement = WidgetPlacement(
      id: 'w1',
      kind: 'transit',
      config: {'count': 4},
    );
    await pump(tester, TransitWidget.forPlacement, placement);

    expect(find.text(l10nEn.transitNoStop), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('setUp')));
    await tester.pumpAndSettle();
    expect(find.text(l10nEn.setUpStopTitle), findsOneWidget);

    await search(tester, 'O');
    expect(transit.stopQueries, isEmpty, reason: 'two letters at least');
    await search(tester, 'Olden');
    expect(transit.stopQueries, ['Olden']);
    await tester.tap(find.text('Oldenburg Hbf'));
    await tester.pumpAndSettle();

    expect(dashboard.updated['w1'], {
      'count': 4,
      'stopId': 'de:03403:10',
      'stopName': 'Oldenburg Hbf',
    });
    expect(transit.calls.last, ('de:03403:10', 4));
    expect(find.byKey(const ValueKey('setUp')), findsNothing);
  });

  testWidgets('weather: chooses a place, also from a small tile', (
    tester,
  ) async {
    weather.placesResult = const Result.ok([
      Place(
        name: 'Berlin',
        region: 'Berlin',
        country: 'Germany',
        lat: 52.5,
        lon: 13.4,
      ),
    ]);
    const placement = WidgetPlacement(id: 'w2', kind: 'weather');
    await pump(
      tester,
      WeatherWidget.forPlacement,
      placement,
      size: WidgetSize.small,
    );

    expect(find.text(l10nEn.setUpAction), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('setUp')));
    await tester.pumpAndSettle();
    await search(tester, 'Berl');
    expect(find.text('Berlin, Germany'), findsOneWidget);
    await tester.tap(find.text('Berlin, Germany'));
    await tester.pumpAndSettle();

    expect(dashboard.updated['w2'], {
      'lat': 52.5,
      'lon': 13.4,
      'label': 'Berlin',
    });
    expect(weather.calls.last, (52.5, 13.4));
  });

  testWidgets('waste: subscribes to a calendar and shows a refusal', (
    tester,
  ) async {
    waste.result = const Result.error(ApiException(ApiFailure.notFound));
    const placement = WidgetPlacement(id: 'w3', kind: 'waste');
    await pump(tester, WasteWidget.forPlacement, placement);

    expect(find.text(l10nEn.wasteNotConfigured), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('setUp')));
    await tester.pumpAndSettle();

    waste.subscribeResult = const Result.error(
      ApiException(ApiFailure.invalid),
    );
    await tester.enterText(find.byKey(const ValueKey('waste.url')), 'nonsense');
    await tester.tap(find.byKey(const ValueKey('waste.save')));
    await tester.pumpAndSettle();
    expect(
      find.text(l10nEn.setUpWasteTitle),
      findsOneWidget,
      reason: 'stays open',
    );

    waste
      ..subscribeResult = const Result.ok(null)
      ..result = const Result.ok([]);
    await tester.enterText(
      find.byKey(const ValueKey('waste.url')),
      ' webcal://example.org/waste.ics ',
    );
    await tester.tap(find.byKey(const ValueKey('waste.save')));
    await tester.pumpAndSettle();

    expect(waste.subscribed.last, 'webcal://example.org/waste.ics');
    expect(find.text(l10nEn.setUpWasteTitle), findsNothing);
    expect(find.text(l10nEn.wasteEmpty), findsOneWidget);
  });

  group('API', () {
    late List<http.Request> requests;
    late String answer;
    ApiClient client() => ApiClient(
      client: MockClient((r) async {
        requests.add(r);
        return http.Response.bytes(
          utf8.encode(answer),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    setUp(() {
      requests = [];
      answer = '{}';
    });

    test('searches stops and places', () async {
      answer = '[{"id":"s1","name":"Hbf","lat":53.1,"lon":8.2},{"id":"","name":"x"}]';
      final stops = await TransitApi(client()).stops(testServer(), 'Hb');
      expect((stops as Ok<List<Stop>>).value.single.name, 'Hbf');
      expect(requests.last.url.path, '/api/transit/stops');
      expect(requests.last.url.queryParameters, {'q': 'Hb'});

      answer = '[{"name":"Köln","region":"NRW","country":"Germany","lat":50.9,"lon":6.9}]';
      final places = await WeatherApi(client()).places(testServer(), 'Kö');
      final place = (places as Ok<List<Place>>).value.single;
      expect((place.name, place.region, place.lat), ('Köln', 'NRW', 50.9));
      expect(requests.last.url.path, '/api/weather/places');
      expect(parseStops({'x': 1}), isNull);
      expect(parsePlaces('x'), isNull);
    });

    test('stores a widget configuration and a waste calendar', () async {
      await DashboardApi(client())
          .updateWidget(testServer(), 'w 1', {'stopId': 's1'});
      expect(requests.last.method, 'PATCH');
      expect(requests.last.url.path, '/api/dashboard/widgets/w%201');
      expect(jsonDecode(requests.last.body), {
        'config': {'stopId': 's1'},
      });

      await WasteApi(client())
          .subscribe(testServer(), 'https://example.org/a.ics');
      expect(requests.last.method, 'PUT');
      expect(requests.last.url.path, '/api/waste/settings');
      expect(jsonDecode(requests.last.body), {
        'url': 'https://example.org/a.ics',
        'rules': <Object?>[],
      });
    });
  });
}
