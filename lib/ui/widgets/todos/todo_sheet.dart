import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/todo.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/widgets/todos/todos_view_model.dart';

/// Opens the sheet to edit or delete [todo].
Future<void> editTodo(
  BuildContext context,
  TodosViewModel viewModel,
  Todo todo,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (context) => TodoSheet(viewModel: viewModel, todo: todo),
);

/// Title, due date and delete for one to-do (#20).
class TodoSheet extends StatefulWidget {
  /// Creates the sheet.
  const TodoSheet({required this.viewModel, required this.todo, super.key});

  /// Stores the changes.
  final TodosViewModel viewModel;

  /// The to-do as it was opened.
  final Todo todo;

  @override
  State<TodoSheet> createState() => _TodoSheetState();
}

class _TodoSheetState extends State<TodoSheet> {
  late final _title = TextEditingController(text: widget.todo.title);
  late DateTime? _due = widget.todo.due;
  String? _titleError;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _due ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) setState(() => _due = picked);
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      setState(() => _titleError = context.l10n.todosTitleRequired);
      return;
    }
    setState(() => _saving = true);
    final changed = widget.todo.copyWith(
      title: _title.text.trim(),
      due: _due,
      clearDue: _due == null,
    );
    final error = await widget.viewModel.save(changed, previous: widget.todo);
    if (!mounted) return;
    if (error case ApiException(failure: ApiFailure.invalid, :final message?)) {
      setState(() {
        _saving = false;
        _titleError = message;
      });
      return;
    }
    Navigator.of(context).pop();
  }

  void _delete() {
    widget.viewModel.delete(widget.todo).ignore();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final due = _due;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Dimens.gap,
        0,
        Dimens.gap,
        Dimens.gap + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const ValueKey('todo.title'),
            controller: _title,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n.todosTitleLabel,
              errorText: _titleError,
            ),
          ),
          const SizedBox(height: Dimens.gapSmall),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.event),
                  label: Text(
                    due == null
                        ? l10n.todosNoDueDate
                        : DateFormat.yMMMd(locale).format(due),
                  ),
                ),
              ),
              if (due != null)
                IconButton(
                  tooltip: l10n.todosRemoveDueDate,
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _due = null),
                ),
            ],
          ),
          const SizedBox(height: Dimens.gap),
          Row(
            children: [
              TextButton.icon(
                key: const ValueKey('todo.delete'),
                onPressed: _saving ? null : _delete,
                icon: const Icon(Icons.delete_outline),
                label: Text(l10n.todosDelete),
              ),
              const Spacer(),
              FilledButton(
                key: const ValueKey('todo.save'),
                onPressed: _saving ? null : _save,
                child: Text(l10n.todosSave),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
