import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/ui/core/refresh.dart';
import 'package:waylight_mobile/ui/core/widgets/widget_frame.dart';
import 'package:waylight_mobile/utils/command.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../testing/pump_app.dart';

void main() {
  late int calls;
  late bool fail;
  late DateTime now;
  late RefreshController refresh;
  late Command0<String> load;

  setUp(() {
    calls = 0;
    fail = false;
    now = DateTime(2026, 11, 19, 12);
    refresh = RefreshController(now: () => now);
    load = Command0<String>(() async {
      calls++;
      return fail
          ? const Result.error(ApiException(ApiFailure.unreachable))
          : Result.ok('data $calls');
    });
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpScreen(
      RefreshHost(
        controller: refresh,
        child: WidgetFrame(
          title: 'Weather',
          load: load,
          interval: const Duration(minutes: 1),
          builder: (_, v) => Text(v),
        ),
      ),
    );
  }

  testWidgets('shows progress, then the content', (tester) async {
    await pump(tester);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await load.execute();
    await tester.pump();

    expect(find.text('data 1'), findsOneWidget);
  });

  testWidgets('shows the error inside the card and retries', (tester) async {
    fail = true;
    await pump(tester);
    await load.execute();
    await tester.pump();
    expect(find.text(l10nEn.errorUnreachable), findsOneWidget);

    fail = false;
    await tester.tap(find.text(l10nEn.dashboardRetry));
    await tester.pump();

    expect(find.text('data 2'), findsOneWidget);
  });

  testWidgets('reloads on its interval only in the foreground', (tester) async {
    await pump(tester);
    await load.execute();

    await tester.pump(const Duration(minutes: 1));
    expect(calls, 2);

    refresh.active = false;
    await tester.pump(const Duration(minutes: 3));
    expect(calls, 2);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('keeps the data when a reload fails and says so', (tester) async {
    await pump(tester);
    await load.execute();
    await tester.pump();

    fail = true;
    now = now.add(const Duration(minutes: 7));
    await refresh.refresh();
    await tester.pump();

    expect(find.text('data 1'), findsOneWidget);
    expect(
      find.text(l10nEn.freshnessFailed(l10nEn.freshnessMinutesAgo(7))),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('marks data older than two intervals as outdated', (
    tester,
  ) async {
    await pump(tester);
    await load.execute();
    refresh.active = false; // no interval reload in between
    now = now.add(const Duration(minutes: 3));
    await tester.pump();
    // A rebuild shows the age.
    await refresh.refresh();
    now = now.add(const Duration(minutes: 3));
    await tester.pump(const Duration(seconds: 1));

    expect(find.textContaining('outdated'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('pull to refresh and the return of the app reload', (
    tester,
  ) async {
    await pump(tester);
    await load.execute();

    await refresh.refresh();
    expect(calls, 2);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    expect(refresh.active, isFalse);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(refresh.active, isTrue);
    expect(calls, 3);
    await tester.pumpWidget(const SizedBox());
  });
}
