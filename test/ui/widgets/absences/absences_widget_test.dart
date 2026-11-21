import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:waylight_mobile/data/repositories/absences/absences_repository.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/server_status.dart';
import 'package:waylight_mobile/ui/widgets/absences/absences_view_model.dart';
import 'package:waylight_mobile/ui/widgets/absences/absences_widget.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../../testing/fakes/fake_absences_repository.dart';
import '../../../testing/fakes/fake_server_repository.dart';
import '../../../testing/pump_app.dart';

/// The absences widget (#201).
void main() {
  final list = parseAbsences(
    jsonDecode(File('test/fixtures/absences_demo.json').readAsStringSync()),
  )!;
  late FakeAbsencesRepository absences;
  late FakeServerRepository servers;

  setUp(() {
    absences = FakeAbsencesRepository()..result = Result.ok(list);
    servers = FakeServerRepository(current: testServer())
      ..statusResult = const Result.ok(
        ServerStatus(setupRequired: false, username: 'anna', role: 'member'),
      );
  });

  test('splits today and later this week', () async {
    final vm = AbsencesViewModel(
      serverRepository: servers,
      absencesRepository: absences,
      now: () => DateTime(2026, 11, 21, 9),
    );
    await vm.load.execute();
    expect(vm.today.map((a) => a.name), ['Anna', 'Ben']);
    expect(vm.laterThisWeek.map((a) => a.name), ['Cem']);
    expect(vm.weekEnd, DateTime(2026, 11, 22));
    vm.dispose();
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpScreen(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ServerRepository>.value(value: servers),
          Provider<AbsencesRepository>.value(value: absences),
        ],
        child: const SingleChildScrollView(
          child: AbsencesWidget(
            widget: WidgetPlacement(id: 'a', kind: 'absences'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('enters an absence and shows field errors', (tester) async {
    await pump(tester);
    expect(find.byTooltip(l10nEn.absenceEdit('Anna')), findsOneWidget);
    expect(find.byTooltip(l10nEn.absenceEdit('Ben')), findsNothing);

    absences.changeResult = const Result.error(
      ApiException(
        ApiFailure.invalid,
        field: 'note',
        message: 'The note can have at most 200 characters.',
      ),
    );
    await tester.tap(find.byKey(const ValueKey('absences.add')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('absence.save')));
    await tester.pumpAndSettle();
    expect(absences.calls, ['create:holiday']);
    expect(
      find.text('The note can have at most 200 characters.'),
      findsOneWidget,
    );

    absences.changeResult = const Result.ok(null);
    await tester.tap(find.byKey(const ValueKey('absence.save')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('absence.save')), findsNothing);
  });

  testWidgets('edits and deletes own absences', (tester) async {
    await pump(tester);
    await tester.tap(find.byTooltip(l10nEn.absenceEdit('Anna')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('absence.delete')));
    await tester.pumpAndSettle();
    expect(absences.calls, ['delete:a1']);
  });

  testWidgets('guests and kiosk displays only read', (tester) async {
    servers.statusResult = const Result.ok(
      ServerStatus(setupRequired: false, username: 'kiosk', role: 'kiosk'),
    );
    await pump(tester);
    expect(find.byKey(const ValueKey('absences.add')), findsNothing);
    expect(find.byTooltip(l10nEn.absenceEdit('Anna')), findsNothing);
  });

  testWidgets('says so when absences are not available', (tester) async {
    absences.result = const Result.error(ApiException(ApiFailure.notFound));
    await pump(tester);
    expect(find.text(l10nEn.absencesOff), findsOneWidget);
  });
}
