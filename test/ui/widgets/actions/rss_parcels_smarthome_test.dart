import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:waylight_mobile/data/repositories/actions/parcels_repository.dart';
import 'package:waylight_mobile/data/repositories/actions/rss_repository.dart';
import 'package:waylight_mobile/data/repositories/actions/smarthome_repository.dart';
import 'package:waylight_mobile/data/repositories/scanner/scanner_repository.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/domain/models/actions.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/server_status.dart';
import 'package:waylight_mobile/ui/core/link_opener.dart';
import 'package:waylight_mobile/ui/widgets/parcels/parcels_widget.dart';
import 'package:waylight_mobile/ui/widgets/rss/rss_widget.dart';
import 'package:waylight_mobile/ui/widgets/smarthome/smarthome_widget.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../../testing/fakes/fake_action_repositories.dart';
import '../../../testing/fakes/fake_barcode_scanner.dart';
import '../../../testing/fakes/fake_link_opener.dart';
import '../../../testing/fakes/fake_server_repository.dart';
import '../../../testing/pump_app.dart';

void main() {
  setUpAll(initializeDateFormatting);

  // Recorded from https://demo.getwaylight.app.
  Object? fixture(String name) =>
      jsonDecode(File('test/fixtures/${name}_demo.json').readAsStringSync());

  late FakeRssRepository rss;
  late FakeParcelsRepository parcels;
  late FakeSmartHomeRepository home;
  late FakeServerRepository servers;
  late FakeLinkOpener links;

  setUp(() {
    rss = FakeRssRepository()
      ..articles = parseFeedArticles(fixture('rss_items'))!;
    parcels = FakeParcelsRepository()..list = parseParcels(fixture('parcels'))!;
    home = FakeSmartHomeRepository()
      ..list = [
        const SmartEntity(
          id: 'light.desk_lamp',
          name: 'Desk lamp',
          state: 'on',
          action: EntityAction.toggle,
        ),
        ...parseEntities(fixture('smarthome_entities'))!
            .where((e) => e.id != 'light.desk_lamp'),
      ];
    servers = FakeServerRepository(current: testServer());
    links = FakeLinkOpener();
  });

  Future<void> pump(
    WidgetTester tester,
    Widget widget, {
    FakeBarcodeScanner? scanner,
  }) async {
    await tester.pumpScreen(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ServerRepository>.value(value: servers),
          if (scanner != null)
            Provider<ScannerRepository>.value(
              value: ScannerRepository(scanner: scanner),
            ),
          Provider<RssRepository>.value(value: rss),
          Provider<ParcelsRepository>.value(value: parcels),
          Provider<SmartHomeRepository>.value(value: home),
        ],
        child: LinkOpenerScope(
          opener: links,
          child: SingleChildScrollView(child: widget),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  WidgetPlacement placement(String kind) =>
      WidgetPlacement(id: kind, kind: kind);

  test('parses the demo', () {
    expect(rss.articles.first.title, 'Welcome to the Waylight demo');
    expect(parcels.list.map((p) => p.status), contains(ParcelStatus.delivered));
    final entities = parseEntities(fixture('smarthome_entities'))!;
    expect(
      entities.firstWhere((e) => e.id == 'sensor.balcony_solar_power').unit,
      'W',
    );
    expect(entities.every((e) => e.action == EntityAction.none), isTrue);
  });

  testWidgets('opening a feed item marks it read', (tester) async {
    await pump(tester, RssWidget(widget: placement('rss')));
    final first = rss.articles.first;
    await tester.tap(find.text(first.title));
    await tester.pumpAndSettle();
    expect(rss.calls, ['read:${first.id}']);
    expect(links.opened.single, first.link);
  });

  testWidgets('adds a parcel and deletes one', (tester) async {
    await pump(tester, ParcelsWidget(widget: placement('parcels')));

    await tester.tap(find.text(l10nEn.parcelsAdd));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '00340434');
    await tester.tap(find.widgetWithText(FilledButton, l10nEn.parcelsAdd));
    await tester.pumpAndSettle();
    expect(parcels.calls, ['add:00340434']);
    expect(find.text('00340434'), findsOneWidget);

    await tester.tap(find.text('00340434'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10nEn.parcelsDelete));
    await tester.pumpAndSettle();
    expect(parcels.calls.last, 'remove:new');
    expect(find.text('00340434'), findsNothing);
  });

  testWidgets('scans a shipping label into the number field (#196)', (
    tester,
  ) async {
    final scanner = FakeBarcodeScanner(
      next: 'https://www.dhl.de/verfolgen?piececode=00340434161094042557',
    );
    await pump(
      tester,
      ParcelsWidget(widget: placement('parcels')),
      scanner: scanner,
    );
    await tester.tap(find.text(l10nEn.parcelsAdd));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('parcels.scan')));
    await tester.pumpAndSettle();
    expect(find.text('00340434161094042557'), findsOneWidget);
    expect(parcels.calls, isEmpty, reason: 'the person confirms first');

    scanner.next = 'hello';
    await tester.tap(find.byKey(const ValueKey('parcels.scan')));
    await tester.pumpAndSettle();
    expect(find.text(l10nEn.parcelsScanNoNumber), findsOneWidget);
  });

  testWidgets('no scan button without a scanner', (tester) async {
    await pump(tester, ParcelsWidget(widget: placement('parcels')));
    await tester.tap(find.text(l10nEn.parcelsAdd));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('parcels.scan')), findsNothing);
  });

  testWidgets('guests see parcels without actions', (tester) async {
    servers.statusResult = const Result.ok(
      ServerStatus(setupRequired: false, role: 'guest'),
    );
    await pump(tester, ParcelsWidget(widget: placement('parcels')));
    expect(find.text(l10nEn.parcelsAdd), findsNothing);
  });

  testWidgets('switches an allowed entity and undoes a refused switch', (
    tester,
  ) async {
    await pump(tester, SmartHomeWidget(widget: placement('smarthome')));
    expect(find.text('412 W'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(home.calls, ['act:light.desk_lamp']);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);

    home.fail = const ApiException(ApiFailure.forbidden);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    expect(find.byType(SnackBar), findsOneWidget);
  });
}
