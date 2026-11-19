import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/data/repositories/widget_data/widget_data_repository.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/ui/core/link_opener.dart';
import 'package:waylight_mobile/ui/widgets/backups/backups_widget.dart';
import 'package:waylight_mobile/ui/widgets/birthdays/birthdays_widget.dart';
import 'package:waylight_mobile/ui/widgets/countdown/countdown_widget.dart';
import 'package:waylight_mobile/ui/widgets/electricity/electricity_widget.dart';
import 'package:waylight_mobile/ui/widgets/registry.dart';
import 'package:waylight_mobile/ui/widgets/services/services_widget.dart';
import 'package:waylight_mobile/ui/widgets/system/system_widget.dart';

import '../../../testing/fakes/fake_link_opener.dart';
import '../../../testing/fakes/fake_server_repository.dart';
import '../../../testing/fakes/fake_widget_data_repository.dart';
import '../../../testing/pump_app.dart';

void main() {
  setUpAll(initializeDateFormatting);

  // Recorded from https://demo.getwaylight.app.
  Object? fixture(String name) =>
      jsonDecode(File('test/fixtures/${name}_demo.json').readAsStringSync());

  late FakeWidgetDataRepository data;
  late FakeLinkOpener links;

  setUp(() {
    data = FakeWidgetDataRepository()
      ..json['/api/system'] = fixture('system')
      ..json['/api/services'] = fixture('services')
      ..json['/api/backup-status/sources'] = fixture('backup_status_sources')
      ..json['/api/countdowns'] = fixture('countdowns')
      ..json['/api/birthdays'] = fixture('birthdays')
      ..json['/api/electricity/prices'] = fixture('electricity_prices');
    links = FakeLinkOpener();
  });

  WidgetPlacement placement(
    String kind, [
    Map<String, Object?> config = const {},
  ]) => WidgetPlacement(id: kind, kind: kind, config: config);

  Future<void> pump(WidgetTester tester, Widget widget) async {
    await tester.pumpScreen(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ServerRepository>.value(
            value: FakeServerRepository(current: testServer()),
          ),
          Provider<WidgetDataRepository>.value(value: data),
        ],
        child: LinkOpenerScope(
          opener: links,
          child: SingleChildScrollView(child: widget),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  test('the registry knows the new kinds', () {
    for (final kind in [
      'system',
      'services',
      'status-overview',
      'backup-status',
      'countdown',
      'birthdays',
      'electricity',
    ]) {
      expect(nativeWidgets.builderFor(kind), isNotNull, reason: kind);
    }
  });

  testWidgets('system shows the host, meters and disks', (tester) async {
    await pump(tester, SystemWidget(widget: placement('system')));

    expect(find.textContaining('homeserver'), findsOneWidget);
    expect(find.text(l10nEn.systemMemory), findsOneWidget);
    expect(find.text('Data'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsWidgets);
  });

  testWidgets('services open their address; the overview counts them', (
    tester,
  ) async {
    await pump(tester, ServicesWidget(widget: placement('services')));
    await tester.tap(find.text('OpenStreetMap'));
    await tester.pumpAndSettle();
    expect(find.text(l10nEn.serviceDetails), findsOneWidget);
    await tester.tap(find.text(l10nEn.servicesOpen));
    await tester.pumpAndSettle();
    expect(links.opened.single.host, contains('openstreetmap'));
  });

  testWidgets('the status overview counts the services by state', (
    tester,
  ) async {
    await pump(
      tester,
      StatusOverviewWidget(widget: placement('status-overview')),
    );
    expect(find.text('3'), findsOneWidget);
    expect(find.text(l10nEn.servicesOnline), findsOneWidget);
    expect(find.text('0'), findsNWidgets(2));
  });

  testWidgets('backups list problems first', (tester) async {
    await pump(tester, BackupsWidget(widget: placement('backup-status')));

    final failed = tester.getTopLeft(find.text('Offsite sync (rclone)')).dy;
    final ok = tester.getTopLeft(find.text('Certificate renewal')).dy;
    expect(failed, lessThan(ok));
    expect(find.text(l10nEn.backupsOverdue), findsOneWidget);
  });

  testWidgets('countdowns and birthdays count the days', (tester) async {
    await pump(
      tester,
      CountdownWidget(
        widget: placement('countdown'),
        now: () => DateTime(2026, 11, 19, 12),
      ),
    );
    expect(find.text('Car inspection'), findsOneWidget);
    expect(find.text(l10nEn.wasteInDays(4)), findsOneWidget);

    await pump(tester, BirthdaysWidget(widget: placement('birthdays')));
    expect(find.text('Grandma Hilde'), findsOneWidget);
    expect(find.textContaining(l10nEn.birthdaysTurns(80)), findsOneWidget);
  });

  testWidgets('electricity shows the current price and asks for the zone', (
    tester,
  ) async {
    await pump(
      tester,
      ElectricityWidget(
        widget: placement('electricity', {'zone': 'AT'}),
        now: () => DateTime.parse('2026-11-19T00:30:00+01:00').toLocal(),
      ),
    );

    expect(find.textContaining('7.8 ct/kWh'), findsOneWidget);
    expect(find.text(l10nEn.todosToday), findsOneWidget);
    expect(find.text(l10nEn.todosTomorrow), findsOneWidget);
    expect(data.asked.last.query, {'zone': 'AT'});
  });

  testWidgets('a widget without data says so in its card', (tester) async {
    data.json.remove('/api/system');
    await pump(tester, SystemWidget(widget: placement('system')));
    expect(find.text(l10nEn.systemTitle), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });
}
