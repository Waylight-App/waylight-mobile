import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:waylight_mobile/data/repositories/presence/presence_repository.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/presence.dart';
import 'package:waylight_mobile/ui/widgets/presence/presence_widget.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../../testing/fakes/fake_presence_repository.dart';
import '../../../testing/fakes/fake_server_repository.dart';
import '../../../testing/pump_app.dart';

/// The presence widget (#200).
void main() {
  final fixture = jsonDecode(
    File('test/fixtures/presence_demo.json').readAsStringSync(),
  ) as Map<String, Object?>;
  late FakePresenceRepository presence;

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpScreen(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ServerRepository>.value(
            value: FakeServerRepository(current: testServer()),
          ),
          Provider<PresenceRepository>.value(value: presence),
        ],
        child: const SingleChildScrollView(
          child: PresenceWidget(
            widget: WidgetPlacement(id: 'p', kind: 'presence'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder segment(String label) => find.descendant(
    of: find.byKey(const ValueKey('presence.mine')),
    matching: find.text(label),
  );

  setUp(
    () =>
        presence = FakePresenceRepository()
          ..result = Result.ok(parsePresence(fixture)!),
  );

  testWidgets('shows the board and sets or clears my status', (tester) async {
    await pump(tester);
    expect(find.text('Anna'), findsOneWidget);
    expect(find.text(l10nEn.presenceFromAbsence), findsOneWidget);
    expect(find.text(l10nEn.presenceCounts(1, 0, 1, 1)), findsOneWidget);

    await tester.tap(segment(l10nEn.presenceHome));
    await tester.pumpAndSettle();
    expect(presence.set.last.$1, PresenceStatus.home);

    // The active status again clears it.
    await tester.tap(segment(l10nEn.presenceOffice));
    await tester.pumpAndSettle();
    expect(presence.set.last.$1, PresenceStatus.none);
  });

  testWidgets('guests and kiosk displays only read', (tester) async {
    presence.result = Result.ok(parsePresence({...fixture, 'mine': null})!);
    await pump(tester);
    expect(find.byKey(const ValueKey('presence.mine')), findsNothing);
    expect(find.text('Anna'), findsOneWidget);
  });

  testWidgets('says so when presence is switched off', (tester) async {
    presence.result = const Result.error(ApiException(ApiFailure.notFound));
    await pump(tester);
    expect(find.text(l10nEn.presenceOff), findsOneWidget);
  });
}
