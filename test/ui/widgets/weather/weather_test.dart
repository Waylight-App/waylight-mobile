import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/data/repositories/weather/weather_repository.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/weather.dart';
import 'package:waylight_mobile/ui/widgets/weather/weather_view_model.dart';
import 'package:waylight_mobile/ui/widgets/weather/weather_widget.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../../testing/fakes/fake_server_repository.dart';
import '../../../testing/fakes/fake_weather_repository.dart';
import '../../../testing/pump_app.dart';

void main() {
  setUpAll(initializeDateFormatting);

  late FakeWeatherRepository weather;
  final servers = FakeServerRepository(current: testServer());

  setUp(() => weather = FakeWeatherRepository());

  WeatherViewModel create(Map<String, Object?> config) => WeatherViewModel(
    config: WeatherConfig.fromJson(config),
    serverRepository: servers,
    weatherRepository: weather,
  );

  test('loads the place of the widget and keeps its number of days', () async {
    final viewModel = create({'lat': 52.52, 'lon': 13.41, 'days': 2});
    await viewModel.load.execute();

    expect(weather.calls.single, (52.52, 13.41));
    expect((viewModel.load.result! as Ok<Weather>).value.days, hasLength(2));
    viewModel.dispose();
  });

  test('needs a place', () async {
    final viewModel = create({});
    await viewModel.load.execute();

    expect(
      (viewModel.load.result! as Error<Weather>).error,
      isA<NoPlaceException>(),
    );
    expect(weather.calls, isEmpty);
    viewModel.dispose();
  });

  test('reads the configuration leniently', () {
    final config = WeatherConfig.fromJson({'days': 9, 'label': ' Berlin '});
    expect(config.days, 5);
    expect(config.label, 'Berlin');
    expect(config.lat, isNull);
  });

  Future<void> pump(WidgetTester tester, Map<String, Object?> config) async {
    await tester.pumpScreen(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ServerRepository>.value(value: servers),
          Provider<WeatherRepository>.value(value: weather),
        ],
        child: WeatherWidget(
          widget: WidgetPlacement(id: 'w', kind: 'weather', config: config),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows now and the next days', (tester) async {
    await pump(tester, {'lat': 1.0, 'lon': 2.0, 'days': 3, 'label': 'Berlin'});

    expect(find.text('Berlin'), findsOneWidget);
    expect(find.text('14 °C'), findsOneWidget);
    expect(find.text(l10nEn.weatherPartlyCloudy), findsOneWidget);
    expect(find.text(l10nEn.weatherFeelsLike(13)), findsOneWidget);
    expect(find.text('Thu'), findsOneWidget);
    expect(find.text('8° / 16°'), findsOneWidget);
    expect(find.text(l10nEn.weatherPrecipitation(80)), findsOneWidget);
  });

  testWidgets('explains a missing place', (tester) async {
    await pump(tester, {});

    expect(find.text(l10nEn.weatherNoPlace), findsOneWidget);
  });

  testWidgets('shows errors inside the card', (tester) async {
    weather.result = const Result.error(ApiException(ApiFailure.unreachable));
    await pump(tester, {'lat': 1.0, 'lon': 2.0});

    expect(find.text(l10nEn.errorUnreachable), findsOneWidget);
  });

  test('every condition has words and an icon', () {
    for (final condition in WeatherCondition.values) {
      expect(labelOf(l10nEn, condition), isNotEmpty);
      expect(iconOf(condition), isA<IconData>());
    }
  });
}
