import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:waylight_mobile/data/repositories/todos/todos_repository_outbox.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/todo.dart';
import 'package:waylight_mobile/ui/core/error_messages.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/core/widgets/message_banner.dart';
import 'package:waylight_mobile/ui/core/widgets/rows.dart';
import 'package:waylight_mobile/ui/core/widgets/view_model_host.dart';
import 'package:waylight_mobile/ui/core/widgets/widget_frame.dart';
import 'package:waylight_mobile/ui/core/widgets/widget_preview.dart';
import 'package:waylight_mobile/ui/widgets/common/compact_state_widget.dart';
import 'package:waylight_mobile/ui/widgets/todos/conflicts_sheet.dart';
import 'package:waylight_mobile/ui/widgets/todos/todo_sheet.dart';
import 'package:waylight_mobile/ui/widgets/todos/todos_example.dart';
import 'package:waylight_mobile/ui/widgets/todos/todos_view_model.dart';

/// The native view of the to-do widget (#64, #20): add, tick off, edit and
/// delete, unless the account is read-only.
class TodosWidget extends StatelessWidget {
  /// Creates the view for [widget].
  const TodosWidget({required this.widget, super.key});

  /// The placement with the widget's configuration.
  final WidgetPlacement widget;

  /// The builder for the widget registry.
  /// Small and strip tiles show the server's compact state (#228).
  static Widget forPlacement(BuildContext context, WidgetPlacement widget) =>
      CompactStateWidget.orFull(
        context,
        widget,
        title: widget.title.isNotEmpty ? widget.title : context.l10n.todosTitle,
        full: () => TodosWidget(widget: widget, key: ValueKey(widget.id)),
      );

  /// The gallery preview from example data (#251): the open to-dos as a
  /// list, read-only, and the count with the next one in small tiles.
  static Widget preview(BuildContext context, String title, WidgetSize size) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todos = exampleTodos(today);
    return WidgetPreview(
      title: title,
      size: size,
      compact: (context) => _TodosCompact(open: todos, size: size),
      full: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final todo in todos) _TodoRow(todo: todo, today: today),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ViewModelHost(
      create: (context) => TodosViewModel(
        config: TodosConfig.fromJson(widget.config),
        serverRepository: context.read(),
        todosRepository: context.read(),
        outbox: context.read<TodoOutbox?>(),
      ),
      builder: (context, viewModel) => WidgetFrame(
        title: widget.title.isNotEmpty ? widget.title : context.l10n.todosTitle,
        load: viewModel.load,
        compact: (context, _, size) => ListenableBuilder(
          listenable: viewModel,
          builder: (context, _) => _TodosCompact(
            open: [
              for (final t in viewModel.todos)
                if (!t.done) t,
            ],
            size: size,
          ),
        ),
        builder: (context, _) => _TodoList(viewModel: viewModel),
      ),
    );
  }
}

/// The open to-dos in a small or strip tile: how many, and the next one.
class _TodosCompact extends StatelessWidget {
  const _TodosCompact({required this.open, required this.size});

  final List<Todo> open;
  final WidgetSize size;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (open.isEmpty) return Text(l10n.todosEmpty);
    final count = l10n.todosCompactOpen(open.length);
    final next = l10n.todosCompactNext(open.first.title);
    if (size == WidgetSize.strip) return Text('$count · $next');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(count, style: Theme.of(context).textTheme.titleLarge),
        Text(next, maxLines: 3, overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

class _TodoList extends StatefulWidget {
  const _TodoList({required this.viewModel});

  final TodosViewModel viewModel;

  @override
  State<_TodoList> createState() => _TodoListState();
}

class _TodoListState extends State<_TodoList> {
  final _title = TextEditingController();
  String? _titleError;

  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_showRefusal);
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_showRefusal);
    _title.dispose();
    super.dispose();
  }

  // A refused change was undone; say why.
  void _showRefusal() {
    final error = widget.viewModel.takeLastError();
    if (error == null || !mounted) return;
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(SnackBar(content: Text(context.l10n.errorMessage(error))));
  }

  Future<void> _add() async {
    final text = _title.text;
    if (text.trim().isEmpty) return;
    _title.clear();
    final error = await widget.viewModel.add(text);
    if (!mounted) return;
    setState(() {
      _titleError = switch (error) {
        ApiException(failure: ApiFailure.invalid, :final message?) => message,
        _ => null,
      };
      if (_titleError != null) _title.text = text;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final viewModel = widget.viewModel;
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (viewModel.conflicts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: Dimens.gapSmall),
              child: MessageBanner(
                key: const ValueKey('todos.conflicts'),
                kind: MessageKind.warning,
                message: l10n.todosConflicts(viewModel.conflicts.length),
                action: TextButton(
                  onPressed: () => showConflicts(context, viewModel),
                  child: Text(l10n.todosConflictsDecide),
                ),
              ),
            ),
          if (viewModel.todos.isEmpty) Text(l10n.todosEmpty),
          for (final todo in viewModel.todos)
            _TodoRow(
              todo: todo,
              today: viewModel.today,
              pending: viewModel.isPending(todo),
              onToggle: viewModel.canEdit
                  ? () => viewModel.toggle(todo).ignore()
                  : null,
              onEdit: viewModel.canEdit
                  ? () => editTodo(context, viewModel, todo)
                  : null,
            ),
          if (viewModel.canEdit) ...[
            const SizedBox(height: Dimens.gapSmall),
            TextField(
              key: const ValueKey('todos.new'),
              controller: _title,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _add(),
              decoration: InputDecoration(
                labelText: l10n.todosAddLabel,
                errorText: _titleError,
                suffixIcon: IconButton(
                  tooltip: l10n.todosAdd,
                  icon: const Icon(Icons.add),
                  onPressed: _add,
                ),
              ),
            ),
            if (viewModel.hasCompleted)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: () => viewModel.clearCompleted().ignore(),
                  child: Text(l10n.todosClearCompleted),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _TodoRow extends StatelessWidget {
  const _TodoRow({
    required this.todo,
    required this.today,
    this.pending = false,
    this.onToggle,
    this.onEdit,
  });

  final Todo todo;
  final DateTime today;
  final bool pending;
  final VoidCallback? onToggle;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final due = dueLabel(context, todo, today);
    return MergeSemantics(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        minTileHeight: Dimens.tapTarget,
        leading: Checkbox(
          value: todo.done,
          onChanged: onToggle == null ? null : (_) => onToggle!(),
        ),
        title: Text(
          todo.title,
          style: todo.done
              ? TextStyle(
                  decoration: TextDecoration.lineThrough,
                  color: theme.colorScheme.onSurfaceVariant,
                )
              : null,
        ),
        // A change made offline that the server does not have yet (#24).
        subtitle: pending
            ? Row(
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: Dimens.iconSmall,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: Dimens.gapTiny),
                  Text(
                    context.l10n.todosPending,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              )
            : null,
        trailing: due == null
            ? null
            : Text(
                due,
                style: theme.textTheme.bodySmall?.copyWith(
                  // Overdue is attention, not a failure: amber, not red.
                  color: todo.overdue && !todo.done
                      ? toneColor(context, Tone.warning)
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
        onTap: onEdit,
      ),
    );
  }
}

/// The due date in words: "Overdue", "Today", "Tomorrow" or the date.
@visibleForTesting
String? dueLabel(BuildContext context, Todo todo, DateTime today) {
  final due = todo.due;
  if (due == null) return null;
  final l10n = context.l10n;
  if (todo.overdue && !todo.done) return l10n.todosOverdue;
  final days = DateTime(due.year, due.month, due.day).difference(today).inDays;
  return switch (days) {
    0 => l10n.todosToday,
    1 => l10n.todosTomorrow,
    _ => DateFormat.MMMd(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(due),
  };
}
