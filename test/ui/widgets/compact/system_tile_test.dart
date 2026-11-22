import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/data/repositories/widget_data/widget_data_repository.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/ui/core/widget_size_scope.dart';
import 'package:waylight_mobile/ui/widgets/system/system_widget.dart';

import '../../../testing/fakes/fake_server_repository.dart';
import '../../../testing/fakes/fake_widget_data_repository.dart';
import '../../../testing/pump_app.dart';

void main() {
  for (final (size, pixels) in [
    (WidgetSize.small, const Size(150, 150)),
    (WidgetSize.strip, const Size(328, 70)),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('system fits a ${size.name} tile at ${scale}x text (#211)', (
        tester,
      ) async {
        final data = FakeWidgetDataRepository()
          ..json['/api/system'] = jsonDecode(
            File('test/fixtures/system_demo.json').readAsStringSync(),
          );
        await tester.pumpScreen(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<ServerRepository>.value(
                value: FakeServerRepository(current: testServer()),
              ),
              Provider<WidgetDataRepository>.value(value: data),
            ],
            child: Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox.fromSize(
                    size: pixels,
                    child: WidgetSizeScope(
                      size: size,
                      child: const SystemWidget(
                        widget: WidgetPlacement(id: 's', kind: 'system'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('%'), findsWidgets);
      });
    }
  }
}
