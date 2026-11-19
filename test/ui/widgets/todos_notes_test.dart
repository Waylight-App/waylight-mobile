import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:waylight_mobile/data/repositories/notes/notes_repository.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/data/repositories/todos/todos_repository.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/note.dart';
import 'package:waylight_mobile/domain/models/todo.dart';
import 'package:waylight_mobile/ui/widgets/notes/notes_view_model.dart';
import 'package:waylight_mobile/ui/widgets/notes/notes_widget.dart';
import 'package:waylight_mobile/ui/widgets/todos/todos_view_model.dart';
import 'package:waylight_mobile/ui/widgets/todos/todos_widget.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../testing/fakes/fake_notes_repository.dart';
import '../../testing/fakes/fake_server_repository.dart';
import '../../testing/fakes/fake_todos_repository.dart';
import '../../testing/pump_app.dart';

void main() {
  setUpAll(initializeDateFormatting);

  final servers = FakeServerRepository(current: testServer());
  late FakeTodosRepository todos;
  late FakeNotesRepository notes;

  setUp(() {
    todos = FakeTodosRepository();
    notes = FakeNotesRepository();
  });

  Future<void> pump(WidgetTester tester, Widget widget) async {
    await tester.pumpScreen(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ServerRepository>.value(value: servers),
          Provider<TodosRepository>.value(value: todos),
          Provider<NotesRepository>.value(value: notes),
        ],
        child: widget,
      ),
    );
    await tester.pumpAndSettle();
  }

  group('to-dos', () {
    test('reads the configuration like the web interface', () {
      expect(TodosConfig.fromJson({}).source, '');
      expect(TodosConfig.fromJson({'source': 'local'}).source, '');
      expect(TodosConfig.fromJson({'source': '../x'}).source, '');
      expect(
        TodosConfig.fromJson({'source': 'nc', 'showDone': true}).showDone,
        isTrue,
      );
    });

    test('loads open to-dos unless done ones are shown', () async {
      final viewModel = TodosViewModel(
        config: const TodosConfig(showDone: true, source: 'nc'),
        serverRepository: servers,
        todosRepository: todos,
      );
      await viewModel.load.execute();

      expect(todos.calls.single, (openOnly: false, source: 'nc'));
      viewModel.dispose();
    });

    testWidgets('lists to-dos with their due dates', (tester) async {
      final today = DateTime.now();
      todos.result = Result.ok([
        Todo(
          id: '1',
          title: 'Pay the bill',
          due: today.subtract(const Duration(days: 2)),
          overdue: true,
        ),
        Todo(id: '2', title: 'Call Anna', due: today),
        Todo(
          id: '3',
          title: 'Book a table',
          due: today.add(const Duration(days: 1)),
        ),
        const Todo(id: '4', title: 'Someday'),
      ]);
      await pump(
        tester,
        const TodosWidget(
          widget: WidgetPlacement(id: 'w', kind: 'todos'),
        ),
      );

      expect(find.text(l10nEn.todosTitle), findsOneWidget);
      expect(find.text(l10nEn.todosOverdue), findsOneWidget);
      expect(find.text(l10nEn.todosToday), findsOneWidget);
      expect(find.text(l10nEn.todosTomorrow), findsOneWidget);
      expect(find.text('Someday'), findsOneWidget);
    });

    testWidgets('says when there is nothing to do', (tester) async {
      await pump(
        tester,
        const TodosWidget(
          widget: WidgetPlacement(id: 'w', kind: 'todos'),
        ),
      );

      expect(find.text(l10nEn.todosEmpty), findsOneWidget);
    });
  });

  group('notes', () {
    test('shows pinned notes by default', () async {
      final viewModel = NotesViewModel(
        scope: NotesScope.fromJson({}),
        serverRepository: servers,
        notesRepository: notes,
      );
      await viewModel.load.execute();

      expect(notes.calls.single, isTrue);
      expect(NotesScope.fromJson({'scope': 'all'}), NotesScope.all);
      viewModel.dispose();
    });

    testWidgets('lists titles with a preview', (tester) async {
      notes.result = const Result.ok([
        Note(
          id: '1',
          title: 'House notes',
          body: '# House\n\nWi-Fi: guest',
          pinned: true,
        ),
      ]);
      await pump(
        tester,
        const NotesWidget(
          widget: WidgetPlacement(id: 'w', kind: 'notes'),
        ),
      );

      expect(find.text('House notes'), findsOneWidget);
      expect(find.text('Wi-Fi: guest'), findsOneWidget);
    });

    testWidgets('says when no note is pinned', (tester) async {
      await pump(
        tester,
        const NotesWidget(
          widget: WidgetPlacement(id: 'w', kind: 'notes'),
        ),
      );

      expect(find.text(l10nEn.notesNonePinned), findsOneWidget);
    });
  });
}
