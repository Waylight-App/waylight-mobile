import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:waylight_mobile/data/repositories/nfc/nfc_repository.dart';
import 'package:waylight_mobile/domain/models/actions.dart';
import 'package:waylight_mobile/domain/models/habit.dart';
import 'package:waylight_mobile/domain/models/tag_action.dart';
import 'package:waylight_mobile/routing/router.dart';
import 'package:waylight_mobile/routing/routes.dart';
import 'package:waylight_mobile/ui/tag/view_models/tag_action_view_model.dart';
import 'package:waylight_mobile/ui/tag/widgets/tag_action_screen.dart';
import 'package:waylight_mobile/ui/widgets/common/tag_writer.dart';

import '../../testing/fakes/fake_action_repositories.dart';
import '../../testing/fakes/fake_habits_repository.dart';
import '../../testing/fakes/fake_nfc_writer.dart';
import '../../testing/fakes/fake_server_repository.dart';
import '../../testing/fakes/fake_shopping_repository.dart';
import '../../testing/pump_app.dart';

/// NFC tags that run a Waylight action (#195).
void main() {
  group('TagAction', () {
    test('round-trips through its link and carries no secret', () {
      for (final action in const [
        HabitTag('h1'),
        SmartHomeTag('light.hall'),
        SmartHomeTag('light.hall', ask: false),
        ShoppingTag('Coffee'),
      ]) {
        final link = action.link;
        expect(link.scheme, 'waylight');
        expect(link.host, 'tag');
        final parsed = TagAction.parse(link.queryParameters);
        expect(parsed?.query, action.query);
      }
      expect(
        const SmartHomeTag('light.hall', ask: false).link.toString(),
        'waylight://tag?do=smart&id=light.hall&ask=0',
      );
    });

    test('ignores links it does not know', () {
      expect(TagAction.parse({'do': 'habit'}), isNull);
      expect(TagAction.parse({'do': 'shop', 'text': '  '}), isNull);
      expect(TagAction.parse({'do': 'rm', 'id': 'x'}), isNull);
    });
  });

  group('running a tag', () {
    late FakeHabitsRepository habits;
    late FakeSmartHomeRepository smartHome;
    late FakeShoppingRepository shopping;

    TagActionViewModel create(TagAction action) => TagActionViewModel(
      query: action.query,
      serverRepository: FakeServerRepository(current: testServer()),
      habitsRepository: habits,
      smartHomeRepository: smartHome,
      shoppingRepository: shopping,
    );

    setUp(() {
      habits = FakeHabitsRepository()
        ..habitList = [
          const Habit(id: 'h1', name: 'Vitamins', doneToday: false),
          const Habit(id: 'h2', name: 'Walk', doneToday: true),
        ];
      smartHome = FakeSmartHomeRepository()
        ..list = const [
          SmartEntity(
            id: 'light.hall',
            name: 'Hall',
            state: 'off',
            action: EntityAction.toggle,
          ),
        ];
      shopping = FakeShoppingRepository();
    });

    test('ticks a habit off once, never back on', () async {
      final ticked = create(const HabitTag('h1'));
      await pumpEventQueue();
      expect(ticked.outcome, TagOutcome.ticked);
      final again = create(const HabitTag('h2'));
      await pumpEventQueue();
      expect(again.outcome, TagOutcome.alreadyDone);
      expect(habits.toggled, ['h1']);
    });

    test('adds the item to the current shopping list', () async {
      final vm = create(const ShoppingTag('Coffee'));
      await pumpEventQueue();
      expect(vm.outcome, TagOutcome.added);
      expect(shopping.calls, ['add:Coffee']);
    });

    testWidgets('asks before switching a device, unless told not to', (
      tester,
    ) async {
      await tester.pumpScreen(
        TagActionScreen(viewModel: create(const SmartHomeTag('light.hall'))),
      );
      await tester.pumpAndSettle();
      expect(find.text(l10nEn.tagConfirm('Hall')), findsOneWidget);
      expect(smartHome.calls, isEmpty);

      await tester.tap(find.byKey(const ValueKey('tag.confirm')));
      await tester.pumpAndSettle();
      expect(smartHome.calls, ['act:light.hall']);
      expect(find.text(l10nEn.tagSwitched('Hall')), findsOneWidget);

      final silent = create(const SmartHomeTag('light.hall', ask: false));
      await tester.pumpAndSettle();
      expect(silent.outcome, TagOutcome.switched);
    });

    test('a device the server does not let change fails', () async {
      smartHome.list = const [
        SmartEntity(id: 'sensor.t', name: 'Temp', state: '20'),
      ];
      final vm = create(const SmartHomeTag('sensor.t', ask: false));
      await pumpEventQueue();
      expect(vm.state, TagRunState.failed);
      expect(smartHome.calls, isEmpty);
    });
  });

  test('a tag opens only after the sign-in and the app lock', () {
    final link = Uri.parse('waylight://tag?do=habit&id=h1');
    expect(
      redirectFor(uri: link, connected: true, signedIn: false),
      '/sign-in?from=%2Ftag%3Fdo%3Dhabit%26id%3Dh1',
    );
    expect(
      redirectFor(uri: link, connected: true, signedIn: true, locked: true),
      '/locked?from=%2Ftag%3Fdo%3Dhabit%26id%3Dh1',
    );
    expect(
      redirectFor(uri: link, connected: true, signedIn: true),
      '${Routes.tag}?do=habit&id=h1',
    );
  });

  group('writing a tag', () {
    late FakeNfcWriter writer;

    Future<void> pumpSheet(WidgetTester tester, TagAction action) async {
      await tester.pumpScreen(
        Provider<NfcRepository>.value(
          value: NfcRepository(writer: writer),
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  showWriteTagSheet(context, action, subject: 'Hall'),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    setUp(() => writer = FakeNfcWriter());

    testWidgets('writes the link with the choice to ask', (tester) async {
      await pumpSheet(tester, const SmartHomeTag('light.hall'));
      await tester.tap(find.byKey(const ValueKey('tag.ask')));
      await tester.tap(find.byKey(const ValueKey('tag.write')));
      await tester.pumpAndSettle();

      expect(writer.written.single.queryParameters['ask'], '0');
      expect(find.text(l10nEn.tagWritten), findsOneWidget);
    });

    testWidgets('explains a tag that is too small', (tester) async {
      writer.outcome = TagWriteOutcome.tooSmall;
      await pumpSheet(tester, const HabitTag('h1'));
      await tester.tap(find.byKey(const ValueKey('tag.write')));
      await tester.pumpAndSettle();
      expect(find.text(l10nEn.tagTooSmall), findsOneWidget);
    });

    testWidgets('says when NFC is off', (tester) async {
      writer.nfc = NfcState.off;
      await pumpSheet(tester, const HabitTag('h1'));
      expect(find.text(l10nEn.tagNfcOff), findsOneWidget);
      expect(find.byKey(const ValueKey('tag.write')), findsNothing);
    });
  });
}
