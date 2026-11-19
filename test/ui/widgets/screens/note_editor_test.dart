import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:waylight_mobile/data/repositories/actions/summary_repository.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/note.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/app_theme.dart';
import 'package:waylight_mobile/ui/widgets/notes/note_editor_screen.dart';
import 'package:waylight_mobile/ui/widgets/notes/note_editor_view_model.dart';

import '../../../testing/fakes/fake_action_repositories.dart';
import '../../../testing/fakes/fake_notes_repository.dart';
import '../../../testing/fakes/fake_server_repository.dart';
import '../../../testing/pump_app.dart';

void main() {
  late FakeNotesRepository notes;

  setUp(() {
    notes = FakeNotesRepository()
      ..byId['n1'] = const Note(
        id: 'n1',
        title: 'Router',
        body: 'Admin password is in the safe.',
        version: 3,
      );
  });

  /// Opens the editor for [id] from a start page, so saving can pop.
  Future<void> open(WidgetTester tester, String id) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: TextButton(
              onPressed: () => context.push('/note'),
              child: const Text('open'),
            ),
          ),
        ),
        GoRoute(
          path: '/note',
          builder: (context, state) => NoteEditorScreen(
            viewModel: NoteEditorViewModel(
              noteId: id,
              serverRepository: FakeServerRepository(current: testServer()),
              notesRepository: notes,
            ),
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ServerRepository>.value(
            value: FakeServerRepository(current: testServer()),
          ),
          Provider<SummaryRepository>.value(value: FakeSummaryRepository()),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light,
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('writes a new note', (tester) async {
    await open(tester, '');
    expect(find.text(l10nEn.noteNew), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Shopping ideas');
    await tester.tap(find.byTooltip(l10nEn.calendarSave));
    await tester.pumpAndSettle();
    expect(notes.changes, ['create:Shopping ideas']);
    expect(find.text('open'), findsOneWidget, reason: 'back on the start page');
  });

  testWidgets('a note without a title is not saved', (tester) async {
    await open(tester, '');
    await tester.tap(find.byTooltip(l10nEn.calendarSave));
    await tester.pumpAndSettle();
    expect(notes.changes, isEmpty);
    expect(find.text(l10nEn.noteTitleMissing), findsOneWidget);
  });

  testWidgets('edits a note and keeps it open on a conflict', (tester) async {
    await open(tester, 'n1');
    expect(find.text('Admin password is in the safe.'), findsOneWidget);

    notes.fail = const ApiException(ApiFailure.conflict);
    await tester.enterText(find.byType(TextField).last, 'Moved to the drawer.');
    await tester.tap(find.byTooltip(l10nEn.calendarSave));
    await tester.pumpAndSettle();
    expect(find.text(l10nEn.noteConflict), findsOneWidget);
    expect(find.text(l10nEn.noteEdit), findsOneWidget);

    notes.fail = null;
    await tester.tap(find.byTooltip(l10nEn.calendarSave));
    await tester.pumpAndSettle();
    expect(notes.byId['n1']!.body, 'Moved to the drawer.');
    expect(notes.byId['n1']!.version, 4);
  });

  testWidgets('deletes a note after asking', (tester) async {
    await open(tester, 'n1');
    await tester.tap(find.byTooltip(l10nEn.noteDelete));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, l10nEn.noteDelete));
    await tester.pumpAndSettle();
    expect(notes.changes, ['delete:n1']);
    expect(find.text('open'), findsOneWidget);
  });
}
