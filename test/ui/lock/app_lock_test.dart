import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:waylight_mobile/data/repositories/lock/app_lock_repository.dart';
import 'package:waylight_mobile/routing/router.dart';
import 'package:waylight_mobile/routing/routes.dart';
import 'package:waylight_mobile/ui/lock/view_models/lock_view_model.dart';
import 'package:waylight_mobile/ui/lock/widgets/lock_screen.dart';
import 'package:waylight_mobile/ui/settings/view_models/settings_area.dart';
import 'package:waylight_mobile/ui/settings/view_models/settings_view_model.dart';
import 'package:waylight_mobile/ui/settings/widgets/settings_area_screen.dart';

import '../../testing/fakes/fake_device_auth.dart';
import '../../testing/fakes/fake_preferences_repository.dart';
import '../../testing/fakes/fake_server_repository.dart';
import '../../testing/fakes/fake_session_repository.dart';
import '../../testing/fakes/in_memory_key_value_store.dart';
import '../../testing/pump_app.dart';

void main() {
  late FakeDeviceAuth auth;
  late InMemoryKeyValueStore store;
  late DateTime now;

  AppLockRepository create() =>
      AppLockRepository(auth: auth, store: store, now: () => now);

  setUp(() {
    auth = FakeDeviceAuth();
    store = InMemoryKeyValueStore();
    now = DateTime(2026, 11, 19, 12);
  });

  group('repository', () {
    test(
      'turning on needs one confirmation and locks at the next start',
      () async {
        final lock = create();
        auth.succeeds = false;
        expect(await lock.setEnabled(true, reason: 'r'), isFalse);
        expect(lock.enabled, isFalse);

        auth.succeeds = true;
        expect(await lock.setEnabled(true, reason: 'r'), isTrue);

        final next = create();
        await next.restore();
        expect(next.locked, isTrue);
      },
    );

    test('locks after the timeout in the background, not before', () async {
      final lock = create();
      await lock.setEnabled(true, reason: 'r');
      await lock.setTimeout(const Duration(minutes: 5));

      lock.onHidden();
      now = now.add(const Duration(minutes: 4));
      lock.onResumed();
      expect(lock.locked, isFalse);

      lock.onHidden();
      now = now.add(const Duration(minutes: 5));
      lock.onResumed();
      expect(lock.locked, isTrue);

      auth.succeeds = false;
      expect(await lock.unlock('r'), isFalse);
      expect(lock.locked, isTrue);
      auth.succeeds = true;
      expect(await lock.unlock('r'), isTrue);
      expect(lock.locked, isFalse);
    });

    test('stays open while it is off', () async {
      final lock = create();
      await lock.restore();
      lock.onHidden();
      now = now.add(const Duration(hours: 1));
      lock.onResumed();
      expect(lock.locked, isFalse);
    });
  });

  test('the router covers everything while locked', () {
    String? at(String link, {bool locked = true}) => redirectFor(
      uri: Uri.parse(link),
      connected: true,
      signedIn: true,
      locked: locked,
    );

    expect(at(Routes.home), Routes.locked);
    expect(at(Routes.settings), '/locked?from=%2Fsettings');
    expect(at(Routes.locked), isNull);
    expect(at('/locked?from=%2Fsettings', locked: false), Routes.settings);
    expect(at(Routes.locked, locked: false), Routes.home);
  });

  testWidgets('the lock screen asks at once', (tester) async {
    final lock = create();
    await lock.setEnabled(true, reason: 'r');
    auth.asked = 0;
    await tester.pumpScreen(LockScreen(viewModel: LockViewModel(lock: lock)));
    await tester.pumpAndSettle();

    expect(auth.asked, 1);
    expect(find.byKey(const ValueKey('lock.unlock')), findsOneWidget);
  });

  testWidgets('settings offer the lock where the phone has one', (
    tester,
  ) async {
    Future<void> pump() async {
      tester.view.physicalSize = const Size(800, 2600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpScreen(
        SettingsAreaScreen(
          area: SettingsArea.phone,
          viewModel: SettingsViewModel(
            serverRepository: FakeServerRepository(current: testServer()),
            sessionRepository: FakeSessionRepository(signedIn: true),
            preferencesRepository: FakePreferencesRepository(),
            lockRepository: create(),
            appVersion: () async => '1',
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    auth.isAvailable = false;
    await pump();
    expect(find.byKey(const ValueKey('settings.lock')), findsNothing);

    auth.isAvailable = true;
    await pump();
    await tester.tap(find.byKey(const ValueKey('settings.lock')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('settings.lockAfter')), findsOneWidget);
  });
}
