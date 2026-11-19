import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:waylight_mobile/data/repositories/habits/habits_repository.dart';
import 'package:waylight_mobile/data/repositories/habits/habits_repository_remote.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/data/repositories/shopping/shopping_repository.dart';
import 'package:waylight_mobile/data/repositories/shopping/shopping_repository_remote.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/habit.dart';
import 'package:waylight_mobile/domain/models/shopping.dart';
import 'package:waylight_mobile/ui/widgets/habits/habits_widget.dart';
import 'package:waylight_mobile/ui/widgets/shopping/shopping_widget.dart';

import '../../../testing/fakes/fake_habits_repository.dart';
import '../../../testing/fakes/fake_server_repository.dart';
import '../../../testing/fakes/fake_shopping_repository.dart';
import '../../../testing/pump_app.dart';

void main() {
  // Recorded from https://demo.getwaylight.app.
  Object? fixture(String name) =>
      jsonDecode(File('test/fixtures/${name}_demo.json').readAsStringSync());

  late FakeShoppingRepository shopping;
  late FakeHabitsRepository habits;

  setUp(() {
    shopping = FakeShoppingRepository()
      ..itemList = parseShoppingItems(fixture('shopping_items'))!;
    habits = FakeHabitsRepository()
      ..habitList = parseHabits(fixture('habits'))!;
  });

  Future<void> pump(WidgetTester tester, Widget widget) async {
    await tester.pumpScreen(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ServerRepository>.value(
            value: FakeServerRepository(current: testServer()),
          ),
          Provider<ShoppingRepository>.value(value: shopping),
          Provider<HabitsRepository>.value(value: habits),
        ],
        child: SingleChildScrollView(child: widget),
      ),
    );
    await tester.pumpAndSettle();
  }

  const shoppingPlacement = WidgetPlacement(id: 's', kind: 'shopping');
  const habitsPlacement = WidgetPlacement(id: 'h', kind: 'habits');

  test('parses lists, items and habits of the demo', () {
    final overview = parseShoppingOverview(fixture('shopping_lists'))!;
    expect(overview.lists.single.name, 'Weekly shop');
    expect(overview.current, overview.lists.single.id);
    expect(
      parseShoppingItems(fixture('shopping_items'))!.first.summary,
      'Oat milk',
    );
    final list = parseHabits(fixture('habits'))!;
    expect(list.first.name, 'Drink water');
    expect(list.first.best, greaterThanOrEqualTo(list.first.current));
  });

  test('toggling a habit moves the streak like the server', () {
    const h = Habit(
      id: 'h',
      name: 'Read',
      doneToday: false,
      current: 3,
      best: 5,
    );
    expect(h.toggled().doneToday, isTrue);
    expect(h.toggled().current, 4);
    expect(h.toggled().toggled().current, 3);
  });

  testWidgets('ticks off, adds and clears shopping items', (tester) async {
    await pump(tester, const ShoppingWidget(widget: shoppingPlacement));
    expect(find.text('Weekly shop'), findsOneWidget);

    await tester.tap(find.text('Oat milk'));
    await tester.pumpAndSettle();
    expect(shopping.calls, ['done:ad041bd7faff2c6cca5027912d5e4151']);

    await tester.enterText(find.byType(TextField), 'Apples');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('Apples'), findsOneWidget);

    final clear = find.textContaining(RegExp('Remove .* in the basket'));
    await tester.ensureVisible(clear);
    await tester.tap(clear);
    await tester.pumpAndSettle();
    expect(shopping.calls.last, 'clear');
  });

  testWidgets('a refused change is undone and reported', (tester) async {
    shopping.fail = const ApiException(ApiFailure.server);
    await pump(tester, const ShoppingWidget(widget: shoppingPlacement));

    await tester.tap(find.text('Oat milk'));
    await tester.pumpAndSettle();
    final box = tester.widget<CheckboxListTile>(
      find.widgetWithText(CheckboxListTile, 'Oat milk'),
    );
    expect(box.value, isFalse);
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('without a list the widget says where to make one', (
    tester,
  ) async {
    shopping.lists = const <ShoppingList>[];
    await pump(tester, const ShoppingWidget(widget: shoppingPlacement));
    expect(find.text(l10nEn.shoppingNotConfigured), findsOneWidget);
  });

  testWidgets('ticks off a habit for today', (tester) async {
    await pump(tester, const HabitsWidget(widget: habitsPlacement));
    final first = habits.habitList.firstWhere((h) => h.dueToday);
    await tester.tap(find.textContaining(first.name));
    await tester.pumpAndSettle();
    expect(habits.toggled, [first.id]);
    expect(
      find.text(l10nEn.habitsStreak(first.toggled().current, first.best)),
      findsOneWidget,
    );
  });
}
