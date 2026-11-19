import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/data/repositories/todos/todos_repository.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/server_status.dart';
import 'package:waylight_mobile/domain/models/todo.dart';
import 'package:waylight_mobile/ui/widgets/todos/todos_view_model.dart';
import 'package:waylight_mobile/ui/widgets/todos/todos_widget.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../../testing/fakes/fake_server_repository.dart';
import '../../../testing/fakes/fake_todos_repository.dart';
import '../../../testing/pump_app.dart';

void main() {
  setUpAll(initializeDateFormatting);

  late FakeServerRepository servers;
  late FakeTodosRepository repo;

  ServerStatus role(String r) => ServerStatus(setupRequired: false, role: r);

  setUp(() {
    servers = FakeServerRepository(current: testServer())
      ..statusResult = Result.ok(role('owner'));
    repo = FakeTodosRepository()
      ..result = const Result.ok([
        Todo(id: '1', title: 'Milk', version: 3),
        Todo(id: '2', title: 'Bread', version: 1),
      ]);
  });

  Future<TodosViewModel> loaded({bool showDone = false}) async {
    final viewModel = TodosViewModel(
      config: TodosConfig(showDone: showDone),
      serverRepository: servers,
      todosRepository: repo,
    );
    while (viewModel.load.result == null) {
      await Future<void>.delayed(Duration.zero);
    }
    await Future<void>.delayed(Duration.zero);
    return viewModel;
  }

  group('view model', () {
    test('adds and replaces the placeholder with the stored to-do', () async {
      final viewModel = await loaded();

      final future = viewModel.add('  Eggs ');
      expect(viewModel.todos.last.title, 'Eggs'); // shown at once
      await future;

      expect(viewModel.todos.last.id, startsWith('srv-'));
      expect(repo.writes, ['create Eggs']);
    });

    test(
      'ticks off and removes the to-do when only open ones are shown',
      () async {
        final viewModel = await loaded();

        await viewModel.toggle(viewModel.todos.first);

        expect(viewModel.todos.map((t) => t.id), ['2']);
        expect(repo.writes, ['update 1']);
      },
    );

    test('keeps ticked-off to-dos when done ones are shown', () async {
      final viewModel = await loaded(showDone: true);

      await viewModel.toggle(viewModel.todos.first);

      expect(viewModel.todos.first.done, isTrue);
      expect(viewModel.todos.first.version, 4);
    });

    test('undoes a refused change and keeps the error for a message', () async {
      final viewModel = await loaded();
      repo.failWith = const ApiException(ApiFailure.unreachable);

      await viewModel.toggle(viewModel.todos.first);
      await viewModel.delete(viewModel.todos.last);

      expect(viewModel.todos.map((t) => t.id), ['1', '2']);
      expect(viewModel.todos.first.done, isFalse);
      expect(viewModel.takeLastError(), isA<ApiException>());
      expect(viewModel.takeLastError(), isNull);
    });

    test('loads again after a conflict', () async {
      final viewModel = await loaded();
      repo.failWith = const ApiException(ApiFailure.conflict);

      await viewModel.toggle(viewModel.todos.first);

      expect(repo.calls, hasLength(2));
    });

    test('guests and kiosks may not change to-dos', () async {
      servers.statusResult = Result.ok(role('guest'));
      expect((await loaded()).canEdit, isFalse);
      servers.statusResult = Result.ok(role('member'));
      expect((await loaded()).canEdit, isTrue);
    });

    test('clears ticked-off to-dos', () async {
      repo.result = const Result.ok([
        Todo(id: '1', title: 'Milk', done: true),
        Todo(id: '2', title: 'Bread'),
      ]);
      final viewModel = await loaded(showDone: true);

      expect(viewModel.hasCompleted, isTrue);
      await viewModel.clearCompleted();

      expect(viewModel.todos.map((t) => t.id), ['2']);
      expect(repo.writes, ['clear']);
    });
  });

  group('widget', () {
    Future<void> pump(WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpScreen(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ServerRepository>.value(value: servers),
            Provider<TodosRepository>.value(value: repo),
          ],
          child: const TodosWidget(
            widget: WidgetPlacement(id: 'w', kind: 'todos'),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('read-only accounts see no actions', (tester) async {
      servers.statusResult = Result.ok(role('guest'));
      await pump(tester);

      expect(find.text('Milk'), findsOneWidget);
      expect(find.byKey(const ValueKey('todos.new')), findsNothing);
      await tester.tap(find.byType(Checkbox).first);
      await tester.pump();
      expect(repo.writes, isEmpty);
    });

    testWidgets('adds with the field and ticks off with a tap', (tester) async {
      await pump(tester);

      await tester.enterText(find.byKey(const ValueKey('todos.new')), 'Eggs');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text('Eggs'), findsOneWidget);

      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();
      expect(find.text('Milk'), findsNothing);
    });

    testWidgets('edits the title in the sheet', (tester) async {
      await pump(tester);

      await tester.tap(find.text('Bread'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('todo.title')),
        'Rye bread',
      );
      await tester.tap(find.byKey(const ValueKey('todo.save')));
      await tester.pumpAndSettle();

      expect(find.text('Rye bread'), findsOneWidget);
      expect(repo.writes, ['update 2']);
    });

    testWidgets('deletes from the sheet', (tester) async {
      await pump(tester);

      await tester.tap(find.text('Bread'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('todo.delete')));
      await tester.pumpAndSettle();

      expect(find.text('Bread'), findsNothing);
      expect(repo.writes, ['delete 2']);
    });

    testWidgets('says why a change was undone', (tester) async {
      await pump(tester);
      repo.failWith = const ApiException(ApiFailure.unreachable);

      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();

      expect(find.text(l10nEn.errorUnreachable), findsOneWidget);
      expect(find.text('Milk'), findsOneWidget);
    });
  });
}
