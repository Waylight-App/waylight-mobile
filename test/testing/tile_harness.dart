import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/ui/core/widget_size_scope.dart';

import 'fakes/fake_server_repository.dart';
import 'pump_app.dart';

/// The tiles of a phone 360 logical pixels wide: the grid leaves 328 for
/// them, and a cell is 70 high (#211).
const tiles = {
  WidgetSize.medium: Size(328, 148),
  WidgetSize.large: Size(328, 304),
};

/// Shows [child] in a tile of [size] at text scale [scale], laid out at its
/// natural height as the grid's tile does.
Future<void> pumpTile(
  WidgetTester tester, {
  required WidgetSize size,
  required double scale,
  required Widget child,
  List<SingleChildWidget> providers = const [],
}) async {
  final pixels = tiles[size]!;
  await tester.pumpScreen(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ServerRepository>.value(
          value: FakeServerRepository(current: testServer()),
        ),
        ...providers,
      ],
      child: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: pixels.width,
              child: SingleChildScrollView(
                child: WidgetSizeScope(
                  size: size,
                  height: pixels.height,
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Expects the card in the tile to be no higher than the tile. At 200 % a
/// medium tile has no room for more than one row, which stays.
void expectFits(WidgetTester tester, WidgetSize size, double scale) {
  if (size == WidgetSize.medium && scale > 1.5) return;
  expect(
    tester.getSize(find.byType(Card).first).height,
    lessThanOrEqualTo(tiles[size]!.height),
  );
}
