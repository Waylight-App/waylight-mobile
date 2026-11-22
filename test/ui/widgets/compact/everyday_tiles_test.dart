import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/data/repositories/shopping/shopping_repository.dart';
import 'package:waylight_mobile/data/repositories/shopping/shopping_repository_remote.dart';
import 'package:waylight_mobile/data/repositories/widget_data/widget_data_repository.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/ui/core/widget_size_scope.dart';
import 'package:waylight_mobile/ui/widgets/birthdays/birthdays_widget.dart';
import 'package:waylight_mobile/ui/widgets/countdown/countdown_widget.dart';
import 'package:waylight_mobile/ui/widgets/registry.dart';
import 'package:waylight_mobile/ui/widgets/shopping/shopping_widget.dart';

import '../../../testing/fakes/fake_server_repository.dart';
import '../../../testing/fakes/fake_shopping_repository.dart';
import '../../../testing/fakes/fake_widget_data_repository.dart';
import '../../../testing/pump_app.dart';

void main() {
  setUpAll(initializeDateFormatting);

  // Recorded from https://demo.getwaylight.app.
  Object? fixture(String name) =>
      jsonDecode(File('test/fixtures/${name}_demo.json').readAsStringSync());

  late FakeWidgetDataRepository data;
  late FakeShoppingRepository shopping;

  setUp(() {
    data = FakeWidgetDataRepository()
      ..json['/api/countdowns'] = fixture('countdowns')
      ..json['/api/birthdays'] = fixture('birthdays');
    shopping = FakeShoppingRepository()
      ..itemList = parseShoppingItems(fixture('shopping_items'))!;
  });

  test('the clock offers no large tile; other kinds offer every size', () {
    expect(
      nativeWidgets.sizesFor('clock').supported,
      isNot(contains(WidgetSize.large)),
    );
    expect(nativeWidgets.sizesFor('clock').defaultSize, WidgetSize.small);
    expect(nativeWidgets.sizesFor('todos').supported, WidgetSize.values);
    expect(nativeWidgets.sizesFor('todos').defaultSize, WidgetSize.medium);
  });

  final tiles = <String, Widget Function()>{
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
  };
  const keyText = {
    'countdown': 'Car inspection',
    'birthdays': 'Grandma Hilde',
    'shopping': 'to buy',
  };

  for (final MapEntry(key: kind, value: build) in tiles.entries) {
    for (final (size, pixels) in [
      (WidgetSize.small, const Size(150, 150)),
      (WidgetSize.strip, const Size(328, 70)),
    ]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('$kind fits a ${size.name} tile at ${scale}x text (#211)', (
          tester,
        ) async {
          await tester.pumpScreen(
            MultiProvider(
              providers: [
                ChangeNotifierProvider<ServerRepository>.value(
                  value: FakeServerRepository(current: testServer()),
                ),
                Provider<WidgetDataRepository>.value(value: data),
                Provider<ShoppingRepository>.value(value: shopping),
              ],
              child: Builder(
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(scale)),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: SizedBox.fromSize(
                      size: pixels,
                      child: WidgetSizeScope(size: size, child: build()),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          // An overflow would have failed the test with an exception.
          expect(find.textContaining(keyText[kind]!), findsOneWidget);
        });
      }
    }
  }
}
