import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'package:waylight_mobile/data/repositories/habits/habits_repository.dart';
import 'package:waylight_mobile/data/repositories/habits/habits_repository_remote.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/data/repositories/shopping/shopping_repository.dart';
import 'package:waylight_mobile/data/repositories/shopping/shopping_repository_remote.dart';
import 'package:waylight_mobile/data/repositories/widget_data/widget_data_repository.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/ui/core/widget_size_scope.dart';
import 'package:waylight_mobile/ui/core/widgets/tile_rows.dart';
import 'package:waylight_mobile/ui/widgets/birthdays/birthdays_widget.dart';
import 'package:waylight_mobile/ui/widgets/countdown/countdown_widget.dart';
import 'package:waylight_mobile/ui/widgets/habits/habits_widget.dart';
import 'package:waylight_mobile/ui/widgets/shopping/shopping_widget.dart';

import '../../../testing/fakes/fake_habits_repository.dart';
import '../../../testing/fakes/fake_server_repository.dart';
import '../../../testing/fakes/fake_shopping_repository.dart';
import '../../../testing/fakes/fake_widget_data_repository.dart';
import '../../../testing/pump_app.dart';
import '../../../testing/tile_harness.dart';

void main() {
  setUpAll(initializeDateFormatting);

  // Recorded from https://demo.getwaylight.app.
  Object? fixture(String name) =>
      jsonDecode(File('test/fixtures/${name}_demo.json').readAsStringSync());

  group('TileRows', () {
    Widget rows(int count) => TileRows<int>(
      items: [for (var i = 0; i < count; i++) i],
      rowHeight: TileRows.lineRowHeight,
      rowBuilder: (context, i) => SizedBox(height: 32, child: Text('row $i')),
    );

    testWidgets('shows every row outside the grid', (tester) async {
      await tester.pumpScreen(SingleChildScrollView(child: rows(20)));
      expect(find.textContaining('row '), findsNWidgets(20));
      expect(find.textContaining('more'), findsNothing);
    });

    for (final size in tiles.keys) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('cuts to the ${size.name} tile at ${scale}x text', (
          tester,
        ) async {
          await pumpTile(
            tester,
            size: size,
            scale: scale,
            child: Card(child: rows(20)),
          );

          final shown = find.textContaining('row ').evaluate().length;
          expect(shown, inInclusiveRange(1, 19));
          if (scale == 1) expect(find.textContaining('more'), findsOneWidget);
          expectFits(tester, size, scale);
        });
      }
    }

    testWidgets('a large tile shows more rows than a medium one', (
      tester,
    ) async {
      Future<int> count(WidgetSize size) async {
        await pumpTile(tester, size: size, scale: 1, child: rows(20));
        return find.textContaining('row ').evaluate().length;
      }

      expect(
        await count(WidgetSize.large),
        greaterThan(await count(WidgetSize.medium)),
      );
    });
  });

  group('everyday kinds fill medium and large tiles', () {
    late FakeWidgetDataRepository data;
    late FakeShoppingRepository shopping;
    late FakeHabitsRepository habits;

    setUp(() {
      data = FakeWidgetDataRepository()
        ..json['/api/countdowns'] = fixture('countdowns')
        ..json['/api/birthdays'] = fixture('birthdays');
      shopping = FakeShoppingRepository()
        ..itemList = parseShoppingItems(fixture('shopping_items'))!;
      habits = FakeHabitsRepository()
        ..habitList = parseHabits(fixture('habits'))!;
    });

    final kinds = <String, Widget Function()>{
      'countdown': () => CountdownWidget(
        widget: const WidgetPlacement(id: 'c', kind: 'countdown'),
        now: () => DateTime(2026, 11, 19, 12),
      ),
      'birthdays': () => const BirthdaysWidget(
        widget: WidgetPlacement(id: 'b', kind: 'birthdays'),
      ),
      'shopping': () => const ShoppingWidget(
        widget: WidgetPlacement(id: 's', kind: 'shopping'),
      ),
      'habits': () => const HabitsWidget(
        widget: WidgetPlacement(id: 'h', kind: 'habits'),
      ),
    };

    for (final MapEntry(key: kind, value: build) in kinds.entries) {
      for (final size in tiles.keys) {
        for (final scale in [1.0, 2.0]) {
          testWidgets(
            '$kind fits a ${size.name} tile at ${scale}x text (#211)',
            (tester) async {
              await pumpTile(
                tester,
                size: size,
                scale: scale,
                providers: [
                  Provider<WidgetDataRepository>.value(value: data),
                  Provider<ShoppingRepository>.value(value: shopping),
                  Provider<HabitsRepository>.value(value: habits),
                ],
                child: build(),
              );
              // An overflow would have failed the test with an exception.
              expectFits(tester, size, scale);
            },
          );
        }
      }
    }
  });
}
