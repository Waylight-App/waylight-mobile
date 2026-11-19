import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/data/repositories/transit/transit_repository.dart';
import 'package:waylight_mobile/data/repositories/waste/waste_repository.dart';
import 'package:waylight_mobile/data/services/api/transit_api.dart';
import 'package:waylight_mobile/data/services/api/waste_api.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/departure.dart';
import 'package:waylight_mobile/ui/widgets/transit/transit_view_model.dart';
import 'package:waylight_mobile/ui/widgets/transit/transit_widget.dart';
import 'package:waylight_mobile/ui/widgets/waste/waste_widget.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../../testing/fakes/fake_server_repository.dart';
import '../../../testing/fakes/fake_transit_repository.dart';
import '../../../testing/fakes/fake_waste_repository.dart';
import '../../../testing/pump_app.dart';

void main() {
  setUpAll(initializeDateFormatting);

  // Recorded from https://demo.getwaylight.app.
  Object? fixture(String name) =>
      jsonDecode(File('test/fixtures/$name').readAsStringSync());

  final servers = FakeServerRepository(current: testServer());
  late FakeTransitRepository transit;
  late FakeWasteRepository waste;

  setUp(() {
    transit = FakeTransitRepository();
    waste = FakeWasteRepository();
  });

  Future<void> pump(WidgetTester tester, Widget widget) async {
    await tester.pumpScreen(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ServerRepository>.value(value: servers),
          Provider<TransitRepository>.value(value: transit),
          Provider<WasteRepository>.value(value: waste),
        ],
        child: SingleChildScrollView(child: widget),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('departures', () {
    test('reads the departures of the demo', () {
      final list = parseDepartures(fixture('transit_demo.json'))!;

      expect(list, isNotEmpty);
      expect(list.first.line, '310');
      expect(list.first.mode, TransitMode.bus);
      expect(list[1].mode, TransitMode.regionalRail);
      expect(list.firstWhere((d) => d.delayMinutes > 0).delayMinutes, 3);
    });

    test('needs a stop and asks for the configured number', () async {
      final none = TransitViewModel(
        config: TransitConfig.fromJson({}),
        serverRepository: servers,
        transitRepository: transit,
      );
      await none.load.execute();
      expect(
        (none.load.result! as Error<List<Departure>>).error,
        isA<NoStopException>(),
      );
      none.dispose();

      final some = TransitViewModel(
        config: TransitConfig.fromJson({'stopId': 's1', 'count': 4}),
        serverRepository: servers,
        transitRepository: transit,
      );
      await some.load.execute();
      expect(transit.calls.single, ('s1', 4));
      some.dispose();
    });

    test('counts the minutes until a departure', () {
      final now = DateTime(2026, 11, 19, 14);
      final viewModel = TransitViewModel(
        config: const TransitConfig(),
        serverRepository: servers,
        transitRepository: transit,
        now: () => now,
      );
      Departure at(DateTime t) => Departure(
        line: '1',
        headsign: 'x',
        mode: TransitMode.bus,
        planned: t,
        expected: t,
      );

      expect(
        viewModel.minutesUntil(at(now.add(const Duration(minutes: 7)))),
        7,
      );
      expect(
        viewModel.minutesUntil(at(now.subtract(const Duration(minutes: 1)))),
        0,
      );
      viewModel.dispose();
    });

    testWidgets('shows lines, delays and cancellations', (tester) async {
      final soon = DateTime.now().add(const Duration(minutes: 10));
      transit.result = Result.ok([
        Departure(
          line: 'RE 18',
          headsign: 'Osnabrück Hbf',
          mode: TransitMode.regionalRail,
          planned: soon,
          expected: soon.add(const Duration(minutes: 3)),
          delayMinutes: 3,
          track: '3',
        ),
        Departure(
          line: '310',
          headsign: 'Lappan',
          mode: TransitMode.bus,
          planned: soon,
          expected: soon,
          cancelled: true,
        ),
      ]);
      await pump(
        tester,
        const TransitWidget(
          widget: WidgetPlacement(
            id: 'w',
            kind: 'transit',
            config: {'stopId': 's', 'stopName': 'Oldenburg Hbf'},
          ),
        ),
      );

      expect(find.text('Oldenburg Hbf'), findsOneWidget);
      expect(find.text('RE 18'), findsOneWidget);
      expect(find.text(l10nEn.transitDelay(3)), findsOneWidget);
      expect(find.text(l10nEn.transitCancelled), findsOneWidget);
    });

    testWidgets('explains a missing stop', (tester) async {
      await pump(
        tester,
        const TransitWidget(
          widget: WidgetPlacement(id: 'w', kind: 'transit'),
        ),
      );

      expect(find.text(l10nEn.transitNoStop), findsOneWidget);
    });

    test('every mode has an icon', () {
      for (final mode in TransitMode.values) {
        expect(iconOf(mode), isA<IconData>());
      }
      expect(TransitMode.fromName('gondola'), TransitMode.other);
    });
  });

  group('waste', () {
    test('reads the collections of the demo', () {
      final list = parseWaste(fixture('waste_demo.json'))!;

      expect(list.map((c) => c.label).first, 'Organic waste');
      expect(list.first.daysUntil, 0);
      expect(list.first.dates.first, DateTime(2026, 11, 19));
    });

    testWidgets('lists the next collections', (tester) async {
      waste.result = Result.ok(parseWaste(fixture('waste_demo.json'))!);
      await pump(
        tester,
        const WasteWidget(
          widget: WidgetPlacement(id: 'w', kind: 'waste'),
        ),
      );

      expect(find.text(l10nEn.wasteTitle), findsOneWidget);
      expect(find.text('Paper'), findsOneWidget);
      expect(find.text(l10nEn.todosToday), findsOneWidget);
      expect(find.text(l10nEn.wasteInDays(9)), findsOneWidget);
    });

    testWidgets('explains a missing calendar', (tester) async {
      waste.result = const Result.error(
        ApiException(ApiFailure.notFound, statusCode: 404),
      );
      await pump(
        tester,
        const WasteWidget(
          widget: WidgetPlacement(id: 'w', kind: 'waste'),
        ),
      );

      expect(find.text(l10nEn.wasteNotConfigured), findsOneWidget);
    });
  });
}
