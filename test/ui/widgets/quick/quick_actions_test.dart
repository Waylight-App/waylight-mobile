import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:waylight_mobile/data/repositories/actions/smarthome_repository.dart';
import 'package:waylight_mobile/data/repositories/compact/compact_state_repository.dart';
import 'package:waylight_mobile/data/repositories/focus/focus_timer_repository.dart';
import 'package:waylight_mobile/data/repositories/presence/presence_repository.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/data/services/focus/focus_timer_service.dart';
import 'package:waylight_mobile/domain/models/actions.dart';
import 'package:waylight_mobile/domain/models/compact_state.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/presence.dart';
import 'package:waylight_mobile/domain/models/server_status.dart';
import 'package:waylight_mobile/ui/core/widget_size_scope.dart';
import 'package:waylight_mobile/ui/widgets/media/media_widgets.dart';
import 'package:waylight_mobile/ui/widgets/presence/presence_widget.dart';
import 'package:waylight_mobile/ui/widgets/smarthome/smarthome_widget.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../../testing/fakes/fake_action_repositories.dart';
import '../../../testing/fakes/fake_compact_state_repository.dart';
import '../../../testing/fakes/fake_presence_repository.dart';
import '../../../testing/fakes/fake_server_repository.dart';
import '../../../testing/fakes/in_memory_key_value_store.dart';
import '../../../testing/pump_app.dart';

/// One action right on a small tile (#226).
void main() {
  final presenceFixture = jsonDecode(
    File('test/fixtures/presence_demo.json').readAsStringSync(),
  ) as Map<String, Object?>;
  late FakePresenceRepository presence;
  late FakeSmartHomeRepository home;
  late FocusTimerRepository timer;

  setUp(() {
    presence = FakePresenceRepository()
      ..result = Result.ok(parsePresence(presenceFixture)!);
    home = FakeSmartHomeRepository()
      ..list = [
        const SmartEntity(
          id: 'light.desk_lamp',
          name: 'Desk lamp',
          state: 'off',
          action: EntityAction.toggle,
        ),
      ];
    timer = FocusTimerRepository(
      timer: InAppFocusTimer(),
      sessions: FakeFocusRepository(),
      store: InMemoryKeyValueStore(),
    );
  });

  Future<void> pump(
    WidgetTester tester,
    Widget Function(BuildContext, WidgetPlacement) builder,
    String kind, {
    WidgetSize size = WidgetSize.small,
    String role = 'admin',
  }) async {
    await tester.pumpScreen(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ServerRepository>.value(
            value: FakeServerRepository(current: testServer())
              ..statusResult = Result.ok(
                ServerStatus(setupRequired: false, role: role),
              ),
          ),
          Provider<PresenceRepository>.value(value: presence),
          Provider<SmartHomeRepository>.value(value: home),
          ChangeNotifierProvider<FocusTimerRepository>.value(value: timer),
          Provider<CompactStateRepository?>.value(
            value: FakeCompactStateRepository(kinds: {'focus'})
              ..result = const Result.ok(
                CompactState(title: CompactText(text: '25 min focus today')),
              ),
          ),
        ],
        child: Center(
          child: SizedBox(
            width: 200,
            height: 200,
            child: WidgetSizeScope(
              size: size,
              child: Builder(
                builder: (context) =>
                    builder(context, WidgetPlacement(id: kind, kind: kind)),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('presence: sets my status from the tile', (tester) async {
    await pump(tester, PresenceWidget.forPlacement, 'presence');

    await tester.tap(find.byKey(const ValueKey('presence.quick.home')));
    await tester.pumpAndSettle();
    expect(presence.set.single.$1, PresenceStatus.home);
  });

  testWidgets('presence: guests see the counts, no buttons', (tester) async {
    presence.result = Result.ok(
      parsePresence({...presenceFixture, 'mine': null})!,
    );
    await pump(
      tester,
      PresenceWidget.forPlacement,
      'presence',
      size: WidgetSize.strip,
    );

    expect(find.byKey(const ValueKey('presence.quick.home')), findsNothing);
    expect(find.text(l10nEn.presenceCounts(1, 0, 1, 1)), findsOneWidget);
  });

  testWidgets('smart home: switches the first device', (tester) async {
    await pump(tester, SmartHomeWidget.forPlacement, 'smarthome');

    await tester.tap(find.byKey(const ValueKey('smartHome.quick')));
    await tester.pumpAndSettle();
    expect(home.calls, ['act:light.desk_lamp']);
  });

  testWidgets('smart home: guests get no switch', (tester) async {
    await pump(
      tester,
      SmartHomeWidget.forPlacement,
      'smarthome',
      role: 'guest',
    );

    expect(find.byKey(const ValueKey('smartHome.quick')), findsNothing);
    expect(find.text('Desk lamp · off'), findsOneWidget);
  });

  testWidgets('focus: starts and stops the timer from the tile', (
    tester,
  ) async {
    await pump(tester, FocusWidget.forPlacement, 'focus');
    expect(find.text('25 min focus today'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('focus.quick')));
    await tester.pump();
    expect(timer.state, isNotNull);

    await tester.tap(find.byKey(const ValueKey('focus.quick')));
    await tester.pump();
    expect(timer.state, isNull);
  });
}
