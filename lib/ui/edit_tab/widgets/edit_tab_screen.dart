import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/ui/core/error_messages.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/core/widgets/form_page.dart';
import 'package:waylight_mobile/ui/core/widgets/message_banner.dart';
import 'package:waylight_mobile/ui/edit_tab/view_models/edit_tab_view_model.dart';
import 'package:waylight_mobile/utils/command.dart';
import 'package:waylight_mobile/utils/result.dart';

/// Edits the phone layout of a tab (#53). Widgets move by dragging or, for
/// screen readers and keyboards, with the up and down buttons.
class EditTabScreen extends StatelessWidget {
  /// Creates the screen for [viewModel].
  const EditTabScreen({required this.viewModel, super.key});

  /// The state and actions of this screen.
  final EditTabViewModel viewModel;

  Future<void> _run(BuildContext context, Command0<void> command) async {
    await command.execute();
    if (!context.mounted) return;
    switch (command.result) {
      case Ok():
        context.pop(true);
      case Error(:final error):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorMessage(error))),
        );
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListenableBuilder(
      listenable: Listenable.merge([viewModel, viewModel.load]),
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: Text(
            viewModel.name.isEmpty ? l10n.editTabTitle : viewModel.name,
          ),
          actions: [
            TextButton(
              key: const ValueKey('editTab.reset'),
              onPressed: () => _run(context, viewModel.reset),
              child: Text(l10n.editTabReset),
            ),
            TextButton(
              key: const ValueKey('editTab.save'),
              onPressed: () => _run(context, viewModel.save),
              child: Text(l10n.todosSave),
            ),
          ],
        ),
        body: switch (viewModel.load.result) {
          Error(:final error) => FormPage(
            children: [
              MessageBanner(
                kind: MessageKind.error,
                message: error is TabNotEditable
                    ? l10n.editTabNotEditable
                    : l10n.errorMessage(error),
              ),
            ],
          ),
          null => const Center(child: CircularProgressIndicator()),
          Ok() => ReorderableListView.builder(
            padding: const EdgeInsets.all(Dimens.gap),
            buildDefaultDragHandles: false,
            itemCount: viewModel.items.length,
            onReorderItem: viewModel.move,
            itemBuilder: (context, i) {
              final item = viewModel.items[i];
              return ListTile(
                key: ValueKey(item.widget.id),
                minTileHeight: Dimens.tapTarget,
                leading: ReorderableDragStartListener(
                  index: i,
                  child: const Icon(Icons.drag_handle),
                ),
                title: Text(item.widget.displayTitle),
                subtitle: item.hidden ? Text(l10n.editTabHidden) : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: l10n.editTabUp,
                      icon: const Icon(Icons.arrow_upward),
                      onPressed: i == 0 ? null : () => viewModel.move(i, i - 1),
                    ),
                    IconButton(
                      tooltip: l10n.editTabDown,
                      icon: const Icon(Icons.arrow_downward),
                      onPressed: i == viewModel.items.length - 1
                          ? null
                          : () => viewModel.move(i, i + 1),
                    ),
                    Switch(
                      value: !item.hidden,
                      onChanged: (_) => viewModel.toggleHidden(i),
                    ),
                  ],
                ),
              );
            },
          ),
        },
      ),
    );
  }
}
