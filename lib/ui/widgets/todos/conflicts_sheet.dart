import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/domain/models/outbox.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/widgets/todos/todos_view_model.dart';

/// Lists the to-do changes the server refused and lets the user decide
/// about each (#24); nothing is overwritten silently.
Future<void> showConflicts(BuildContext context, TodosViewModel viewModel) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) {
          final l10n = context.l10n;
          return ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(Dimens.gap),
            children: [
              for (final c in viewModel.conflicts)
                Padding(
                  padding: const EdgeInsets.only(bottom: Dimens.gap),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.change.todo.title.isEmpty
                            ? l10n.todosDeletedTodo
                            : c.change.todo.title,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        c.kind == ConflictKind.changed
                            ? l10n.todosConflictChanged
                            : l10n.todosConflictRejected(c.message),
                      ),
                      Row(
                        children: [
                          if (c.kind == ConflictKind.changed)
                            TextButton(
                              onPressed: () => viewModel.keepMine(c).ignore(),
                              child: Text(l10n.todosKeepMine),
                            ),
                          TextButton(
                            onPressed: () => viewModel.keepServer(c).ignore(),
                            child: Text(
                              c.kind == ConflictKind.changed
                                  ? l10n.todosKeepServer
                                  : l10n.todosDiscard,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
