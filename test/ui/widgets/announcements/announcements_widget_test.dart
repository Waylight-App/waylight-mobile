import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:waylight_mobile/data/repositories/announcements/announcements_repository.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/server_status.dart';
import 'package:waylight_mobile/ui/widgets/announcements/announcements_widget.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../../testing/fakes/fake_announcements_repository.dart';
import '../../../testing/fakes/fake_server_repository.dart';
import '../../../testing/pump_app.dart';

/// The announcements widget (#202).
void main() {
  final list = sortAnnouncements(
    parseAnnouncements(
      jsonDecode(
        File('test/fixtures/announcements_demo.json').readAsStringSync(),
      ),
    )!,
  );
  late FakeAnnouncementsRepository repo;
  late FakeServerRepository servers;

  setUp(() {
    repo = FakeAnnouncementsRepository()..result = Result.ok(list);
    servers = FakeServerRepository(current: testServer())
      ..statusResult = const Result.ok(
        ServerStatus(setupRequired: false, username: 'anna', role: 'member'),
      );
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpScreen(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ServerRepository>.value(value: servers),
          Provider<AnnouncementsRepository>.value(value: repo),
        ],
        child: const SingleChildScrollView(
          child: AnnouncementsWidget(
            widget: WidgetPlacement(id: 'n', kind: 'announcements'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('opening an announcement shows it and marks it read', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text(l10nEn.announcementWrite), findsNothing);
    await tester.tap(find.text('Office closed on Friday'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Keys at the front desk', findRichText: true),
      findsOneWidget,
    );
    expect(repo.calls, ['read:n2']);
    expect(find.byKey(const ValueKey('announcement.edit')), findsOneWidget);
  });

  testWidgets('writers publish with field errors shown', (tester) async {
    repo
      ..writer = true
      ..changeResult = const Result.error(
        ApiException(
          ApiFailure.invalid,
          field: 'title',
          message: 'The title is required.',
        ),
      );
    await pump(tester);
    await tester.tap(find.byKey(const ValueKey('announcements.add')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('announcement.save')));
    await tester.pumpAndSettle();
    expect(find.text('The title is required.'), findsOneWidget);
    repo.changeResult = const Result.ok(null);
    await tester.enterText(
      find.byKey(const ValueKey('announcement.title')),
      'Hello',
    );
    await tester.tap(find.byKey(const ValueKey('announcement.save')));
    await tester.pumpAndSettle();
    expect(repo.calls.last, 'create:Hello');
    expect(find.byKey(const ValueKey('announcement.save')), findsNothing);
  });

  testWidgets('guests and kiosk displays read without read marks', (
    tester,
  ) async {
    servers.statusResult = const Result.ok(
      ServerStatus(setupRequired: false, username: 'k', role: 'kiosk'),
    );
    await pump(tester);
    await tester.tap(find.text('Office closed on Friday'));
    await tester.pumpAndSettle();
    expect(repo.calls, isEmpty);
  });

  testWidgets('says so when announcements are not available', (tester) async {
    repo.result = const Result.error(ApiException(ApiFailure.notFound));
    await pump(tester);
    expect(find.text(l10nEn.announcementsOff), findsOneWidget);
  });
}
