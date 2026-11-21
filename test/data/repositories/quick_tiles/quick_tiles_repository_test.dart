import 'package:flutter_test/flutter_test.dart';
import 'package:waylight_mobile/data/repositories/quick_tiles/quick_tiles_repository.dart';
import 'package:waylight_mobile/domain/models/actions.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/presence.dart';
import 'package:waylight_mobile/domain/models/quick_tile.dart';
import 'package:waylight_mobile/l10n/generated/app_localizations_en.dart';
import 'package:waylight_mobile/ui/home_widgets/quick_tile_texts.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../../testing/fakes/fake_action_repositories.dart';
import '../../../testing/fakes/fake_presence_repository.dart';
import '../../../testing/fakes/fake_quick_tile_store.dart';
import '../../../testing/fakes/fake_server_repository.dart';

/// The Quick Settings tiles (#192).
void main() {
  final texts = QuickTileTexts(AppLocalizationsEn());
  late FakeSmartHomeRepository home;
  late FakePresenceRepository presence;
  late FakeQuickTileStore store;
  late QuickTilesRepository repo;

  const lamp = SmartEntity(
    id: 'light.desk',
    name: 'Desk lamp',
    state: 'off',
    action: EntityAction.toggle,
  );
  const sensor = SmartEntity(
    id: 'sensor.temp',
    name: 'Temperature',
    state: '21',
  );

  PresenceBoard board(PresenceStatus mine) => PresenceBoard(
    people: const [],
    counts: const {},
    mine: PresencePerson(accountId: 'a', name: 'Anna', status: mine),
  );

  setUp(() {
    home = FakeSmartHomeRepository()..list = [lamp, sensor];
    presence = FakePresenceRepository()
      ..result = Result.ok(board(PresenceStatus.none));
    store = FakeQuickTileStore();
    repo = QuickTilesRepository(
      smartHome: home,
      presence: presence,
      store: store,
    );
  });

  test('the status tile is offered only with presence and cycles', () async {
    await repo.refresh(testServer(), format: texts);
    expect(store.offered[QuickTileKind.status], isTrue);
    expect(store.states[QuickTileKind.status]?.subtitle, 'Not set');

    await repo.run(testServer(), QuickTileKind.status, format: texts);
    expect(presence.set.last.$1, PresenceStatus.office);
    expect(store.states[QuickTileKind.status]?.subtitle, 'Office');

    presence.result = const Result.error(ApiException(ApiFailure.notFound));
    await repo.refresh(testServer(), format: texts);
    expect(store.offered[QuickTileKind.status], isFalse);
  });

  test('the smart home tile offers only switchable devices and switches the chosen one', () async {
    final choices = await repo.choices(testServer());
    expect((choices as Ok<List<SmartEntity>>).value.map((e) => e.id), [
      'light.desk',
    ]);
    expect(
      await repo.run(testServer(), QuickTileKind.smartHome, format: texts),
      isA<Error<void>>(),
      reason: 'nothing chosen yet',
    );

    await repo.choose(lamp, texts);
    expect(store.states[QuickTileKind.smartHome]?.label, 'Desk lamp');
    await repo.run(testServer(), QuickTileKind.smartHome, format: texts);
    expect(home.calls, ['act:light.desk']);

    home.fail = const ApiException(ApiFailure.unreachable);
    await repo.run(testServer(), QuickTileKind.smartHome, format: texts);
    expect(
      store.states[QuickTileKind.smartHome]?.subtitle,
      texts.unreachable(QuickTileKind.smartHome, 'Desk lamp').subtitle,
    );
  });

  test('signing out clears the tiles and hides the status tile', () async {
    await repo.choose(lamp, texts);
    await repo.clear();
    expect(store.chosen, isNull);
    expect(store.states, isEmpty);
    expect(store.offered[QuickTileKind.status], isFalse);
  });

  test('next status cycles office, home, away', () {
    expect(nextStatus(PresenceStatus.none), PresenceStatus.office);
    expect(nextStatus(PresenceStatus.office), PresenceStatus.home);
    expect(nextStatus(PresenceStatus.home), PresenceStatus.away);
    expect(nextStatus(PresenceStatus.away), PresenceStatus.office);
  });
}
