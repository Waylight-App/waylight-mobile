import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/data/repositories/widget_data/queries/weather.dart';
import 'package:waylight_mobile/data/repositories/widget_data/widget_data_repository.dart';
import 'package:waylight_mobile/ui/widgets/weather/weather_extras.dart';

import '../../../testing/fakes/fake_server_repository.dart';
import '../../../testing/fakes/fake_widget_data_repository.dart';
import '../../../testing/pump_app.dart';

void main() {
  // Recorded from https://demo.getwaylight.app.
  final warnings = jsonDecode(
    File('test/fixtures/weather_warnings_demo.json').readAsStringSync(),
  );
  const health = {
    'pollen': {
      'region': {'id': 10, 'name': 'Niedersachsen'},
      'days': [
        {
          'type': 'Hasel',
          'today': '1-2',
          'tomorrow': '2',
          'todayBurden': 'low',
          'tomorrowBurden': 'moderate',
        },
      ],
    },
    'uv': {
      'city': 'Berlin',
      'today': 2,
      'tomorrow': 3,
      'todayLevel': 'low',
      'tomorrowLevel': 'moderate',
    },
  };

  late FakeWidgetDataRepository data;

  setUp(() {
    data = FakeWidgetDataRepository()
      ..json['/api/weather/warnings'] = warnings
      ..json['/api/weather/health'] = health;
  });

  Future<void> pump(WidgetTester tester, Map<String, Object?> config) async {
    await tester.pumpScreen(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ServerRepository>.value(
            value: FakeServerRepository(current: testServer()),
          ),
          Provider<WidgetDataRepository>.value(value: data),
        ],
        child: WeatherExtras(config: config),
      ),
    );
    await tester.pumpAndSettle();
  }

  test('parses warnings and health', () {
    expect(parseWarnings(warnings)!.single.severity, 'minor');
    final h = parseHealth(health)!;
    expect(h.pollen.single, ('Hasel', '1-2'));
    expect(h.uvToday, 2);
  });

  testWidgets('shows warnings, UV and pollen as configured', (tester) async {
    await pump(tester, {
      'lat': 52.52,
      'lon': 13.41,
      'pollenRegion': 10,
      'uvCity': 'Berlin',
    });
    expect(find.text('Amtliche WARNUNG vor STARKEN WINDBÖEN'), findsOneWidget);
    expect(find.text(l10nEn.weatherUv), findsOneWidget);
    expect(find.text('Hasel'), findsOneWidget);
    expect(data.asked.last.query, {'region': '10', 'city': 'Berlin'});
  });

  testWidgets('asks for nothing the settings turn off', (tester) async {
    await pump(tester, {'lat': 52.52, 'lon': 13.41, 'warnings': false});
    expect(find.byType(Text), findsNothing);
    expect(data.asked, isEmpty);
  });
}
