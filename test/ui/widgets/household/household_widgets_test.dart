import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:waylight_mobile/data/repositories/household/household_repository.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/household.dart';
import 'package:waylight_mobile/domain/models/server_status.dart';
import 'package:waylight_mobile/ui/widgets/household/household_widgets.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../../testing/fakes/fake_household_repository.dart';
import '../../../testing/fakes/fake_server_repository.dart';
import '../../../testing/pump_app.dart';

/// The family and household widgets (Waylight-App/waylight#675, #676).
void main() {
  setUpAll(initializeDateFormatting);

  late FakeHouseholdRepository household;

  setUp(() => household = FakeHouseholdRepository());

  Future<void> pump(
    WidgetTester tester,
    Widget Function(BuildContext, WidgetPlacement) builder, {
    String role = 'admin',
    Map<String, Object?> config = const {},
  }) async {
    final servers = FakeServerRepository(current: testServer())
      ..statusResult = Result.ok(
        ServerStatus(setupRequired: false, username: 'anna', role: role),
      );
    await tester.pumpScreen(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ServerRepository>.value(value: servers),
          Provider<HouseholdRepository>.value(value: household),
        ],
        child: SingleChildScrollView(
          child: Builder(
            builder: (context) => builder(
              context,
              WidgetPlacement(id: 'w', kind: 'x', config: config),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('chores: ticks off a chore that is due', (tester) async {
    household.choreList = [
      Chore(
        id: 'c1',
        title: 'Bins',
        assignee: 'Anna',
        due: DateTime(2026, 11, 22),
        dueNow: true,
        overdue: true,
      ),
      Chore(id: 'c2', title: 'Windows', due: DateTime(2026, 12, 2)),
    ];
    await pump(tester, HouseholdWidgets.chores);

    expect(find.text('Anna · Overdue'), findsOneWidget);
    expect(find.byKey(const ValueKey('chores.done.c2')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('chores.done.c1')));
    await tester.pumpAndSettle();

    expect(household.done, ['c1']);
  });

  testWidgets('chores: a guest only looks', (tester) async {
    household.choreList = [const Chore(id: 'c1', title: 'Bins', dueNow: true)];
    await pump(tester, HouseholdWidgets.chores, role: 'guest');

    expect(find.text('Bins'), findsOneWidget);
    expect(find.byKey(const ValueKey('chores.done.c1')), findsNothing);
  });

  testWidgets('chores: says when there are none', (tester) async {
    await pump(tester, HouseholdWidgets.chores);

    expect(find.text(l10nEn.choresEmpty), findsOneWidget);
  });

  testWidgets('meters: adds a reading from the keyboard', (tester) async {
    household.meterList = [
      Meter(
        id: 'm1',
        name: 'Power',
        unit: 'kWh',
        lastDay: DateTime(2026, 11),
        lastValue: 1234.5,
      ),
    ];
    await pump(tester, HouseholdWidgets.meters);
    expect(find.textContaining('1,234.5 kWh'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('meters.add.m1')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('meterReading.value')),
      'abc',
    );
    await tester.tap(find.byKey(const ValueKey('meterReading.save')));
    await tester.pumpAndSettle();
    expect(find.text(l10nEn.meterReadingInvalid), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('meterReading.value')),
      '1250,5',
    );
    await tester.tap(find.byKey(const ValueKey('meterReading.save')));
    await tester.pumpAndSettle();

    expect(household.readings, ['m1:1250.5']);
  });

  testWidgets('gifts: marks an idea as bought and undoes a refusal', (
    tester,
  ) async {
    household.giftList = [
      const GiftIdea(id: 'g1', person: 'Ben', title: 'Book'),
    ];
    await pump(tester, HouseholdWidgets.gifts);

    await tester.tap(find.byKey(const ValueKey('gifts.g1')));
    await tester.pumpAndSettle();
    expect(household.marked, ['g1:true']);

    household.actionResult = failedAction;
    await tester.tap(find.byKey(const ValueKey('gifts.g1')));
    await tester.pumpAndSettle();
    expect(household.marked.last, 'g1:false');
    expect(
      tester
          .widget<CheckboxListTile>(find.byKey(const ValueKey('gifts.g1')))
          .value,
      isTrue, // the refused change is taken back
    );
  });

  testWidgets('meals, board, contracts and documents list their records', (
    tester,
  ) async {
    household
      ..mealList = [
        Meal(
          id: 'a',
          dish: 'Soup',
          date: DateTime(2026, 11, 23),
          meal: 'dinner',
        ),
      ]
      ..boardList = [const BoardNote(id: 'b', text: 'Milk', pinned: true)]
      ..contractList = [
        Contract(
          id: 'k',
          name: 'Internet',
          provider: 'Telco',
          monthlyCents: 3999,
          deadline: DateTime(2027, 1, 31),
          soon: true,
        ),
      ]
      ..documentList = [
        DocumentRecord(
          id: 'd',
          title: 'Washer',
          status: WarrantyStatus.ending,
          warrantyEnd: DateTime(2026, 12, 5),
        ),
      ];

    await pump(tester, HouseholdWidgets.meals);
    expect(find.text('Soup'), findsOneWidget);
    expect(find.textContaining('Dinner'), findsOneWidget);

    await pump(tester, HouseholdWidgets.board);
    expect(find.text('Milk'), findsOneWidget);

    await pump(
      tester,
      HouseholdWidgets.contracts,
      config: const {'currency': 'EUR'},
    );
    expect(find.text('Internet'), findsOneWidget);
    expect(find.textContaining('39.99'), findsOneWidget);
    expect(find.textContaining('Cancel by'), findsOneWidget);

    await pump(tester, HouseholdWidgets.documents);
    expect(find.text('Washer'), findsOneWidget);
    expect(find.textContaining('Warranty ends'), findsOneWidget);
  });
}
