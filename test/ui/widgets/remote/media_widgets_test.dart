import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:waylight_mobile/data/repositories/actions/drop_repository.dart';
import 'package:waylight_mobile/data/repositories/actions/focus_repository.dart';
import 'package:waylight_mobile/data/repositories/focus/focus_timer_repository.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/data/repositories/widget_data/queries/media.dart';
import 'package:waylight_mobile/data/repositories/widget_data/widget_data_repository.dart';
import 'package:waylight_mobile/data/services/focus/focus_timer_service.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/ui/core/link_opener.dart';
import 'package:waylight_mobile/ui/widgets/media/media_widgets.dart';
import 'package:waylight_mobile/ui/widgets/registry.dart';

import '../../../testing/fakes/fake_action_repositories.dart';
import '../../../testing/fakes/fake_link_opener.dart';
import '../../../testing/fakes/fake_server_repository.dart';
import '../../../testing/fakes/fake_widget_data_repository.dart';
import '../../../testing/fakes/in_memory_key_value_store.dart';
import '../../../testing/pump_app.dart';

// A 1×1 transparent PNG.
final _png = Uint8List.fromList(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
  ),
);

void main() {
  setUpAll(initializeDateFormatting);

  // Recorded from https://demo.getwaylight.app.
  Object? fixture(String name) =>
      jsonDecode(File('test/fixtures/$name.json').readAsStringSync());

  late FakeWidgetDataRepository data;
  late FakeFocusRepository focus;

  setUp(() {
    data = FakeWidgetDataRepository()
      ..json['/api/photos'] = fixture('photos_demo')
      ..json['/api/space/apod'] = fixture('space_apod_demo')
      ..json['/api/space/launches'] = fixture('space_launches_demo')
      ..json['/api/apiwidget/endpoints/e1/values'] = fixture(
        'apiwidget_values_demo',
      )
      ..json['/api/drop'] = fixture('drop_demo')
      ..json['/api/focus/stats'] = fixture('focus_stats_demo')
      ..json['/api/mail/inbox'] = fixture('mail_inbox_example')
      ..images['/api/weather/radar'] = _png
      ..images['/api/space/apod/image'] = _png;
    for (final id in parsePhotoIds(fixture('photos_demo'))!) {
      data.images[photoPath(id)] = _png;
    }
    focus = FakeFocusRepository();
  });

  Future<void> pump(
    WidgetTester tester,
    String kind, [
    Map<String, Object?> config = const {},
  ]) async {
    final placement = WidgetPlacement(id: kind, kind: kind, config: config);
    await tester.pumpScreen(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ServerRepository>.value(
            value: FakeServerRepository(current: testServer()),
          ),
          Provider<WidgetDataRepository>.value(value: data),
          Provider<FocusRepository>.value(value: focus),
          Provider<DropRepository>.value(
            value: FakeDropRepository()
              ..list = parseDrops(fixture('drop_demo'))!,
          ),
        ],
        child: LinkOpenerScope(
          opener: FakeLinkOpener(),
          child: SingleChildScrollView(
            child: Builder(
              builder: (context) =>
                  nativeWidgets.builderFor(kind)!(context, placement),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  test('parses the demo', () {
    expect(parsePhotoIds(fixture('photos_demo')), hasLength(3));
    final apod = parseApod(fixture('space_apod_demo'))!;
    expect(apod.imagePath, startsWith('/api/space/apod/image'));
    expect(
      parseApiValues(fixture('apiwidget_values_demo'))!.values.first.label,
      'Power now',
    );
    expect(parseDrops(fixture('drop_demo'))!.single.isFile, isFalse);
    expect(parseFocus(fixture('focus_stats_demo')), hasLength(7));
    final inbox = parseInbox(fixture('mail_inbox_example'))!;
    expect(inbox.unread, 2);
    expect(inbox.webmail?.host, 'mail.example.org');
  });

  testWidgets('photo frame and radar show images of the server', (
    tester,
  ) async {
    await pump(tester, 'photo-frame');
    expect(find.byType(Image), findsOneWidget);
    await tester.pump(const Duration(seconds: 31));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(Image), findsWidgets);

    await pump(tester, 'radar', {
      'lat': 53.1,
      'lon': 8.2,
      'label': 'Oldenburg',
    });
    expect(find.text('Oldenburg'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    // On a dark background with the credit, as in the web widget (#176).
    expect(find.text('Oldenburg · © Deutscher Wetterdienst'), findsOneWidget);

    await pump(tester, 'radar');
    expect(find.text(l10nEn.radarNoPlace), findsOneWidget);
  });

  testWidgets('space shows launches and the picture of the day', (
    tester,
  ) async {
    await pump(tester, 'space');
    expect(find.text('Starlink Group 12-7'), findsOneWidget);
    expect(find.text('Aurora over the Wadden Sea'), findsOneWidget);
  });

  testWidgets('JSON values, mail and drop render', (tester) async {
    await pump(tester, 'apiwidget', {'endpointId': 'e1'});
    expect(find.text('Power now'), findsOneWidget);

    await pump(tester, 'apiwidget');
    expect(find.text(l10nEn.apiWidgetNoEndpoint), findsOneWidget);

    await pump(tester, 'mail');
    expect(find.text(l10nEn.mailUnread(2)), findsOneWidget);
    expect(find.text('Dinner on Friday?'), findsOneWidget);

    await pump(tester, 'drop');
    expect(find.byType(SelectableText), findsOneWidget);
  });

  testWidgets('the focus timer runs, pauses and records a finished phase', (
    tester,
  ) async {
    var now = DateTime(2026, 11, 19, 10);
    final timer = FocusTimerRepository(
      timer: InAppFocusTimer(now: () => now),
      sessions: focus,
      store: InMemoryKeyValueStore(),
    );
    await tester.pumpScreen(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ServerRepository>.value(
            value: FakeServerRepository(current: testServer()),
          ),
          ChangeNotifierProvider<FocusTimerRepository>.value(value: timer),
        ],
        child: FocusTimer(now: () => now),
      ),
    );
    await tester.tap(find.text(l10nEn.focusStart));
    await tester.pump();
    now = now.add(const Duration(minutes: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('24:00'), findsOneWidget);

    await tester.tap(find.text(l10nEn.focusPause));
    await tester.pump();
    now = now.add(const Duration(minutes: 10));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('24:00'), findsOneWidget, reason: 'paused');

    await tester.tap(find.text(l10nEn.focusResume));
    await tester.pump();
    now = now.add(const Duration(minutes: 25));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(focus.calls, ['save:25']);
    expect(find.text(l10nEn.focusStart), findsOneWidget);
  });
}
