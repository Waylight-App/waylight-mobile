import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/todo.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/core/widgets/view_model_host.dart';
import 'package:waylight_mobile/ui/core/widgets/widget_frame.dart';
import 'package:waylight_mobile/ui/widgets/todos/todos_view_model.dart';

/// The native view of the to-do widget (#64).
class TodosWidget extends StatelessWidget {
  /// Creates the view for [widget].
  const TodosWidget({required this.widget, super.key});

  /// The placement with the widget's configuration.
  final WidgetPlacement widget;

  /// The builder for the widget registry.
  static Widget forPlacement(BuildContext context, WidgetPlacement widget) =>
      TodosWidget(widget: widget, key: ValueKey(widget.id));

  @override
  Widget build(BuildContext context) {
    return ViewModelHost(
      create: (context) => TodosViewModel(
        config: TodosConfig.fromJson(widget.config),
        serverRepository: context.read(),
        todosRepository: context.read(),
      ),
      builder: (context, viewModel) => WidgetFrame(
        title: widget.title.isNotEmpty ? widget.title : context.l10n.todosTitle,
        load: viewModel.load,
        builder: (context, todos) => todos.isEmpty
            ? Text(context.l10n.todosEmpty)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final todo in todos)
                    _TodoRow(todo: todo, today: viewModel.today),
                ],
              ),
      ),
    );
  }
}

class _TodoRow extends StatelessWidget {
  const _TodoRow({required this.todo, required this.today});

  final Todo todo;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final due = dueLabel(context, todo, today);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimens.gapTiny),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            todo.done ? Icons.check_box : Icons.check_box_outline_blank,
            size: Dimens.iconSmall,
            color: theme.colorScheme.onSurfaceVariant,
            semanticLabel: todo.done ? context.l10n.todosDone : null,
          ),
          const SizedBox(width: Dimens.gapSmall),
          Expanded(
            child: Text(
              todo.title,
              style: todo.done
                  ? TextStyle(
                      decoration: TextDecoration.lineThrough,
                      color: theme.colorScheme.onSurfaceVariant,
                    )
                  : null,
            ),
          ),
          if (due != null) ...[
            const SizedBox(width: Dimens.gapSmall),
            Text(
              due,
              style: theme.textTheme.bodySmall?.copyWith(
                color: todo.overdue && !todo.done
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
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
