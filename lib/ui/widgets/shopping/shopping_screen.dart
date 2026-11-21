import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:waylight_mobile/domain/models/tag_action.dart';
import 'package:waylight_mobile/ui/core/error_messages.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/widgets/common/error_snack_listener.dart';
import 'package:waylight_mobile/ui/widgets/common/tag_writer.dart';
import 'package:waylight_mobile/ui/widgets/shopping/shopping_view_model.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The shopping list in full (#103): large rows for one hand in the shop,
/// the lists to switch between and an always visible field to add items.
class ShoppingScreen extends StatefulWidget {
  /// Creates the screen for [viewModel].
  const ShoppingScreen({required this.viewModel, super.key});

  /// The state and actions of this screen.
  final ShoppingViewModel viewModel;

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  /// Asks for the item and writes a tag that adds it (#195).
  Future<void> _writeTag() async {
    final text = await showDialog<String>(
      context: context,
      builder: (context) => const _TagItemDialog(),
    );
    if (text == null || text.trim().isEmpty || !mounted) return;
    await showWriteTagSheet(
      context,
      ShoppingTag(text.trim()),
      subject: text.trim(),
    );
  }

  Future<void> _add() async {
    final text = _input.text;
    _input.clear();
    await widget.viewModel.add(text);
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
    final l10n = context.l10n;
    return ErrorSnackListener(
      listenable: vm,
      takeError: vm.takeLastError,
      child: ListenableBuilder(
        listenable: Listenable.merge([vm, vm.load]),
        builder: (context, _) {
          final list = vm.list;
          final done = vm.items.where((i) => i.done).length;
          return Scaffold(
            appBar: AppBar(
              title: vm.lists.length > 1
                  ? DropdownButton<String>(
                      value: list?.id,
                      underline: const SizedBox.shrink(),
                      items: [
                        for (final l in vm.lists)
                          DropdownMenuItem(value: l.id, child: Text(l.name)),
                      ],
                      onChanged: (id) =>
                          vm.select(vm.lists.firstWhere((l) => l.id == id)),
                    )
                  : Text(list?.name ?? l10n.shoppingTitle),
              actions: [
                if (defaultTargetPlatform == TargetPlatform.android)
                  IconButton(
                    key: const ValueKey('shopping.tag'),
                    tooltip: l10n.tagShopping,
                    icon: const Icon(Icons.nfc),
                    onPressed: () => _writeTag().ignore(),
                  ),
                if (done > 0)
                  IconButton(
                    tooltip: l10n.shoppingClear(done),
                    icon: const Icon(Icons.remove_done),
                    onPressed: vm.clearCompleted,
                  ),
              ],
            ),
            body: switch ((vm.load.result, list)) {
              (Error(:final error), null) => Padding(
                padding: const EdgeInsets.all(Dimens.gap),
                child: Text(
                  isNotConfigured(error)
                      ? l10n.shoppingNotConfigured
                      : l10n.errorMessage(error),
                ),
              ),
              (_, null) when !vm.load.running => Padding(
                padding: const EdgeInsets.all(Dimens.gap),
                child: Text(l10n.shoppingNotConfigured),
              ),
              (_, null) => const Center(child: CircularProgressIndicator()),
              _ => RefreshIndicator(
                onRefresh: vm.load.execute,
                child: ListView(
                  children: [
                    for (final item in vm.items)
                      CheckboxListTile(
                        controlAffinity: ListTileControlAffinity.leading,
                        value: item.done,
                        onChanged: (_) => vm.toggle(item),
                        title: Text(
                          item.summary,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                decoration: item.done
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                        ),
                      ),
                    if (vm.items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(Dimens.gap),
                        child: Text(l10n.shoppingEmpty),
                      ),
                  ],
                ),
              ),
            },
            bottomNavigationBar: list == null
                ? null
                : SafeArea(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        Dimens.gap,
                        Dimens.gapSmall,
                        Dimens.gap,
                        MediaQuery.viewInsetsOf(context).bottom +
                            Dimens.gapSmall,
                      ),
                      child: TextField(
                        controller: _input,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _add(),
                        decoration: InputDecoration(
                          hintText: l10n.shoppingAdd,
                          suffixIcon: IconButton(
                            tooltip: l10n.shoppingAdd,
                            icon: const Icon(Icons.add),
                            onPressed: _add,
                          ),
                        ),
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }
}

/// Asks for the item an NFC tag adds to the shopping list.
class _TagItemDialog extends StatefulWidget {
  const _TagItemDialog();

  @override
  State<_TagItemDialog> createState() => _TagItemDialogState();
}

class _TagItemDialogState extends State<_TagItemDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final m = MaterialLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.tagShopping),
      content: TextField(
        key: const ValueKey('shopping.tagItem'),
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(labelText: l10n.tagShoppingItem),
        onSubmitted: (text) => Navigator.pop(context, text),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(m.cancelButtonLabel),
        ),
        FilledButton(
          key: const ValueKey('shopping.tagNext'),
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(m.continueButtonLabel),
        ),
      ],
    );
  }
}
