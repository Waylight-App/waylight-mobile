import 'package:flutter_test/flutter_test.dart';

import 'package:waylight_mobile/domain/models/compact_derived.dart';
import 'package:waylight_mobile/domain/models/compact_state.dart';
import 'package:waylight_mobile/domain/models/departure.dart';
import 'package:waylight_mobile/domain/models/waste_collection.dart';

import '../../testing/fakes/fake_weather_repository.dart';

/// Compact states derived in the app (#242).
void main() {
  final now = DateTime(2026, 11, 19, 10);

  group('weather', () {
    test('shows the temperature and today\'s forecast', () {
      final state = compactWeather(sampleWeather(), now);
      expect(state.title.key, DerivedCompactKey.weather);
      expect(state.title.text, '14 °C, feels like 13 °C');
      expect(state.title.params, {'temp': '14', 'feels': '13'});
      expect(state.detail?.text, '8 to 16 °C, 10% rain');
      expect(state.level, CompactLevel.none);
    });

    test('has no detail when the forecast lacks today', () {
      final state = compactWeather(sampleWeather(), DateTime(2026, 12, 5));
      expect(state.detail, isNull);
    });
  });

  group('departures', () {
    Departure departure({int delay = 0, bool cancelled = false}) => Departure(
      line: 'S1',
      headsign: 'Airport',
      mode: TransitMode.suburban,
      planned: now.add(const Duration(minutes: 4)),
      expected: now.add(Duration(minutes: 4 + delay)),
      delayMinutes: delay,
      cancelled: cancelled,
    );

    test('names the next departure on time', () {
      final state = compactDepartures([departure(), departure()], now);
      expect(state.title.text, 'S1 to Airport in 4 min');
      expect(state.detail, isNull);
      expect(state.level, CompactLevel.ok);
      expect(state.count, 2);
    });

    test('a delay asks for attention', () {
      final state = compactDepartures([departure(delay: 3)], now);
      expect(state.title.text, 'S1 to Airport in 7 min');
      expect(state.detail?.text, '3 min late');
      expect(state.level, CompactLevel.attention);
    });

    test('a cancelled departure is a problem', () {
      final state = compactDepartures([departure(cancelled: true)], now);
      expect(state.title.key, DerivedCompactKey.departureCancelled);
      expect(state.level, CompactLevel.problem);
    });

    test('says when nothing leaves', () {
      final state = compactDepartures(const [], now);
      expect(state.title.key, DerivedCompactKey.noDepartures);
      expect(state.count, 0);
    });
  });

  group('waste', () {
    WasteCollection bin(String label, int days) =>
        WasteCollection(label: label, dates: const [], daysUntil: days);

    test('joins the bins of the next collection day', () {
      final state = compactWaste([
        bin('Paper', 3),
        bin('Bio', 1),
        bin('Plastic', 1),
      ], now);
      expect(state.title.text, 'Bio, Plastic tomorrow');
      expect(state.level, CompactLevel.attention);
      expect(state.count, 3);
    });

    test('later collections stay quiet', () {
      final state = compactWaste([bin('Paper', 4)], now);
      expect(state.title.text, 'Paper in 4 days');
      expect(state.level, CompactLevel.none);
    });

    test('today asks for attention, nothing ahead says so', () {
      expect(compactWaste([bin('Bio', 0)], now).title.text, 'Bio today');
      expect(
        compactWaste(const [], now).title.key,
        DerivedCompactKey.noCollections,
      );
    });
  });
}
