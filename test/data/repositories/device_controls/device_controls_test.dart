import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:waylight_mobile/data/repositories/device_controls/device_controls_repository.dart';
import 'package:waylight_mobile/domain/models/actions.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/device_control.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/home_widgets/background_refresh.dart';
import 'package:waylight_mobile/ui/home_widgets/device_control_texts.dart';

import '../../../testing/fakes/fake_action_repositories.dart';
import '../../../testing/fakes/fake_device_controls_store.dart';
import '../../../testing/fakes/fake_preferences_repository.dart';
import '../../../testing/fakes/fake_server_repository.dart';
import '../../../testing/fakes/fake_session_repository.dart';

/// Android's device controls (#194).
void main() {
  late FakeSmartHomeRepository smartHome;
  late FakeDeviceControlsStore store;
  late DeviceControlsRepository repo;
  final format = DeviceControlTexts(lookupAppLocalizations(const Locale('en')));

  setUp(() {
    smartHome = FakeSmartHomeRepository()
      ..list = const [
        SmartEntity(
          id: 'light.desk',
          name: 'Desk',
          state: 'on',
          action: EntityAction.toggle,
        ),
        SmartEntity(
          id: 'scene.evening',
          name: 'Evening',
          state: 'scening',
          action: EntityAction.press,
        ),
        SmartEntity(
          id: 'sensor.temp',
          name: 'Kitchen',
          state: '21.4',
          unit: '°C',
        ),
      ];
    store = FakeDeviceControlsStore();
    repo = DeviceControlsRepository(smartHome: smartHome, store: store);
  });

  test('offers what the server allows, the rest read-only', () async {
    await repo.refresh(testServer(), format: format);

    final snapshot = store.saved.single;
    expect(snapshot.available, isTrue);
    expect(snapshot.controls.map((c) => (c.id, c.type, c.device, c.status)), [
      ('light.desk', DeviceControlType.toggle, DeviceControlDevice.light, 'On'),
      (
        'scene.evening',
        DeviceControlType.button,
        DeviceControlDevice.routine,
        'Run',
      ),
      (
        'sensor.temp',
        DeviceControlType.readOnly,
        DeviceControlDevice.sensor,
        '21.4 °C',
      ),
    ]);
    expect(snapshot.controls.first.toJson(), {
      'id': 'light.desk',
      'name': 'Desk',
      'type': 'toggle',
      'device': 'light',
      'on': true,
      'status': 'On',
    });
  });

  test('an unreachable server shows the controls as unavailable', () async {
    smartHome.readFail = const ApiException(ApiFailure.unreachable);
    await repo.refresh(testServer(), format: format);

    final snapshot = store.saved.single;
    expect(snapshot.available, isFalse);
    expect(snapshot.controls, isEmpty);
    expect(snapshot.reason, 'Not reachable');
  });

  test('switches through the server and shows the new state', () async {
    await repo.act(testServer(), 'light.desk', format: format);

    expect(smartHome.calls, ['act:light.desk']);
    expect(store.saved.single.available, isTrue);
  });

  group('in the background', () {
    Future<void> run(List<String> args, {bool signedIn = true}) =>
        runDeviceControlsInBackground(
          server: FakeServerRepository(current: testServer()),
          session: FakeSessionRepository(signedIn: signedIn),
          preferences: FakePreferencesRepository(),
          deviceControls: repo,
          args: args,
          systemLocale: const Locale('de'),
        );

    test('refreshes in the app language and reports the end', () async {
      await run(['refresh']);
      expect(store.saved.single.controls.first.status, 'An');
      expect(store.finishes, 1);
    });

    test('acts on the entity it was given', () async {
      await run(['act', 'scene.evening']);
      expect(smartHome.calls, ['act:scene.evening']);
    });

    test('signed out, it asks to open the app and never acts', () async {
      await run(['act', 'light.desk'], signedIn: false);
      expect(smartHome.calls, isEmpty);
      expect(store.saved.single.available, isFalse);
      expect(store.saved.single.reason, 'Waylight öffnen und anmelden');
      expect(store.finishes, 1);
    });
  });
}
