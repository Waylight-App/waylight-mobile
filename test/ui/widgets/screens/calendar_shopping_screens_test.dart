import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:waylight_mobile/data/repositories/calendar/calendar_repository.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/data/repositories/shopping/shopping_repository.dart';
import 'package:waylight_mobile/data/repositories/shopping/shopping_repository_remote.dart';
import 'package:waylight_mobile/data/repositories/widget_data/queries/information.dart';
import 'package:waylight_mobile/domain/models/information.dart';
import 'package:waylight_mobile/domain/models/shopping.dart';
import 'package:waylight_mobile/ui/widgets/calendar/calendar_screen.dart';
import 'package:waylight_mobile/ui/widgets/calendar/calendar_view_model.dart';
import 'package:waylight_mobile/ui/widgets/shopping/shopping_screen.dart';
import 'package:waylight_mobile/ui/widgets/shopping/shopping_view_model.dart';

import '../../../testing/fakes/fake_action_repositories.dart';
import '../../../testing/fakes/fake_server_repository.dart';
import '../../../testing/fakes/fake_shopping_repository.dart';
import '../../../testing/pump_app.dart';

void main() {
  setUpAll(initializeDateFormatting);

  // Recorded from https://demo.getwaylight.app.
  Object? fixture(String name) =>
      jsonDecode(File('test/fixtures/${name}_demo.json').readAsStringSync());

  final servers = FakeServerRepository(current: testServer());

  test('a new event is sent as instants or dates', () {
    final timed = newEventJson(
      NewEvent(
        calendarId: 'c1',
        summary: 'Dentist',
        start: DateTime.utc(2026, 11, 20, 9),
        end: DateTime.utc(2026, 11, 20, 10),
      ),
    );
    expect(timed['start'], '2026-11-20T09:00:00.000Z');
    expect(timed['calendarUrl'], 'c1');
    final allDay = newEventJson(
      NewEvent(
        calendarId: 'c1',
        summary: 'Trip',
        start: DateTime(2026, 12, 2),
        end: DateTime(2026, 12, 3),
        allDay: true,
      ),
    );
    expect((allDay['start'], allDay['end']), ('2026-12-02', '2026-12-03'));
  });

  testWidgets('the agenda lists events and adds a new one', (tester) async {
    final calendar = FakeCalendarRepository()
      ..events = parseCalendar(fixture('calendar_events'))!;
    final vm = CalendarViewModel(
      serverRepository: servers,
      calendarRepository: calendar,
    );
    addTearDown(vm.dispose);
    await tester.pumpScreen(CalendarScreen(viewModel: vm));
    await tester.pumpAndSettle();
    expect(find.text('Team call'), findsOneWidget);

    await tester.tap(find.text(l10nEn.calendarNewEvent));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Dentist');
    await tester.tap(find.text(l10nEn.calendarSave));
    await tester.pumpAndSettle();
    expect(calendar.created.single.summary, 'Dentist');
    expect(calendar.created.single.calendarId, 'c1');
    expect(find.text(l10nEn.calendarEventAdded('Dentist')), findsOneWidget);
  });

  testWidgets('read-only calendars offer no new event', (tester) async {
    final calendar = FakeCalendarRepository()..calendars = const [];
    final vm = CalendarViewModel(
      serverRepository: servers,
      calendarRepository: calendar,
    );
    addTearDown(vm.dispose);
    await tester.pumpScreen(CalendarScreen(viewModel: vm));
    await tester.pumpAndSettle();
    expect(find.text(l10nEn.calendarNewEvent), findsNothing);
    expect(find.text(l10nEn.calendarEmpty), findsOneWidget);
  });

  testWidgets('the shopping screen switches lists and adds items', (
    tester,
  ) async {
    final shopping = FakeShoppingRepository()
      ..lists = const [
        ShoppingList(id: 'l1', name: 'Weekly shop'),
        ShoppingList(id: 'l2', name: 'Hardware store'),
      ]
      ..itemList = parseShoppingItems(fixture('shopping_items'))!;
    final vm = ShoppingViewModel(
      serverRepository: servers,
      shoppingRepository: shopping,
    );
    addTearDown(vm.dispose);
    await tester.pumpScreen(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ServerRepository>.value(value: servers),
          Provider<ShoppingRepository>.value(value: shopping),
          Provider<CalendarRepository>.value(value: FakeCalendarRepository()),
        ],
        child: ShoppingScreen(viewModel: vm),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Oat milk'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Screws');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(shopping.calls, ['add:Screws']);

    await tester.tap(find.text('Weekly shop'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hardware store').last);
    await tester.pumpAndSettle();
    expect(vm.list?.id, 'l2');
  });
}
