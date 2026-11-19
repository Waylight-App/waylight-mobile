import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/ui/core/widgets/widget_frame.dart';
import 'package:waylight_mobile/utils/command.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../testing/pump_app.dart';

void main() {
  testWidgets('shows progress, then the content', (tester) async {
    final load = Command0<String>(() async => const Result.ok('data'));
    await tester.pumpScreen(
      WidgetFrame(title: 'Weather', load: load, builder: (_, v) => Text(v)),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await load.execute();
    await tester.pump();

    expect(find.text('Weather'), findsOneWidget);
    expect(find.text('data'), findsOneWidget);
  });

  testWidgets('shows the error inside the card and retries', (tester) async {
    var calls = 0;
    final load = Command0<String>(() async {
      calls++;
      return calls == 1
          ? const Result.error(ApiException(ApiFailure.unreachable))
          : const Result.ok('data');
    });
    await tester.pumpScreen(
      WidgetFrame(title: 'Weather', load: load, builder: (_, v) => Text(v)),
    );
    await load.execute();
    await tester.pump();
    expect(find.text(l10nEn.errorUnreachable), findsOneWidget);

    await tester.tap(find.text(l10nEn.dashboardRetry));
    await tester.pumpAndSettle();

    expect(find.text('data'), findsOneWidget);
  });
}
