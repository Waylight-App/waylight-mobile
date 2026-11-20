import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/ui/core/widget_size_scope.dart';
import 'package:waylight_mobile/ui/widgets/clock/clock_view_model.dart';
import 'package:waylight_mobile/ui/widgets/clock/clock_widget.dart';

import '../../../testing/pump_app.dart';

void main() {
  setUpAll(initializeDateFormatting);

  // 13:05:09 UTC on a Thursday.
  final instant = DateTime.utc(2026, 11, 19, 13, 5, 9);

  ClockViewModel clock(Map<String, Object?> config, {String locale = 'en'}) =>
      ClockViewModel(
        config: ClockConfig.fromJson(config),
        locale: locale,
        now: () => instant,
      );

  test('shows the time in the configured time zone', () {
    final viewModel = clock({'timeZone': 'Europe/Berlin'});

    expect(viewModel.time, '14:05');
    expect(viewModel.zone, 'Europe/Berlin');
    viewModel.dispose();
  });

  test('shows seconds and a 12-hour clock on request', () {
    final viewModel = clock({
      'timeZone': 'UTC',
      'showSeconds': true,
      'hour12': true,
    });

    expect(viewModel.time, '1:05:09 PM');
    viewModel.dispose();
  });

  test('falls back to the phone for unknown time zones', () {
    final viewModel = clock({'timeZone': 'Mars/Olympus'});

    expect(viewModel.zone, isEmpty);
    viewModel.dispose();
  });

  test('writes the date in the language of the app', () {
    final viewModel = clock({'timeZone': 'Europe/Berlin'}, locale: 'de');

    expect(viewModel.date, 'Donnerstag, 19. November 2026');
    viewModel.dispose();
  });

  test('ticks while it is shown', () async {
    var ticks = 0;
    final viewModel = ClockViewModel(
      config: const ClockConfig(),
      locale: 'en',
      tick: const Duration(milliseconds: 10),
    )..addListener(() => ticks++);

    await Future<void>.delayed(const Duration(milliseconds: 55));
    viewModel.dispose();

    expect(ticks, greaterThan(2));
  });

  testWidgets('shows title, time and date', (tester) async {
    await tester.pumpScreen(
      const ClockWidget(
        widget: WidgetPlacement(
          id: 'w',
          kind: 'clock',
          config: {'timeZone': 'Europe/Berlin'},
        ),
      ),
    );

    expect(find.text('Clock'), findsOneWidget);
    expect(find.text('Europe/Berlin'), findsOneWidget);
    // Removing the widget stops its timer.
    await tester.pumpWidget(const SizedBox());
  });

  for (final (size, pixels) in [
    (WidgetSize.small, const Size(150, 150)),
    (WidgetSize.strip, const Size(328, 70)),
  ]) {
    testWidgets('fits a ${size.name} tile (#211)', (tester) async {
      await tester.pumpScreen(
        Align(
          alignment: Alignment.topLeft,
          child: SizedBox.fromSize(
            size: pixels,
            child: WidgetSizeScope(
              size: size,
              child: const ClockWidget(
                widget: WidgetPlacement(
                  id: 'w',
                  kind: 'clock',
                  config: {'timeZone': 'Europe/Berlin', 'showSeconds': true},
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Clock'), findsOneWidget);
      expect(find.text('Europe/Berlin'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
