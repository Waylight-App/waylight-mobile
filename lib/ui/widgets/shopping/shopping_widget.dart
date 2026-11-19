import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/routing/routes.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/core/widgets/view_model_host.dart';
import 'package:waylight_mobile/ui/core/widgets/widget_frame.dart';
import 'package:waylight_mobile/ui/widgets/common/error_snack_listener.dart';
import 'package:waylight_mobile/ui/widgets/shopping/shopping_view_model.dart';

/// The native view of the shopping list widget (#145): tick off and add
/// items of the current list.
class ShoppingWidget extends StatelessWidget {
  /// Creates the view for [widget].
  const ShoppingWidget({required this.widget, super.key});

  /// The placement of the widget.
  final WidgetPlacement widget;

  /// The builder for the widget registry.
  static Widget forPlacement(BuildContext context, WidgetPlacement widget) =>
      ShoppingWidget(widget: widget, key: ValueKey(widget.id));

  @override
  Widget build(BuildContext context) => ViewModelHost(
    create: (context) => ShoppingViewModel(
      serverRepository: context.read(),
      shoppingRepository: context.read(),
    ),
    builder: (context, viewModel) => WidgetFrame<void>(
      title: widget.title.isNotEmpty
          ? widget.title
          : context.l10n.shoppingTitle,
      load: viewModel.load,
      interval: const Duration(minutes: 1),
      errorText: (error) =>
          isNotConfigured(error) ? context.l10n.shoppingNotConfigured : null,
      builder: (context, _) => _ShoppingList(viewModel: viewModel),
    ),
  );
}

class _ShoppingList extends StatefulWidget {
  const _ShoppingList({required this.viewModel});

  final ShoppingViewModel viewModel;

  @override
  State<_ShoppingList> createState() => _ShoppingListState();
}

class _ShoppingListState extends State<_ShoppingList> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final text = _input.text;
    _input.clear();
    await widget.viewModel.add(text);
  }

  @override
  Widget build(BuildContext context) => ErrorSnackListener(
    listenable: widget.viewModel,
    takeError: widget.viewModel.takeLastError,
    child: ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final l10n = context.l10n;
        final vm = widget.viewModel;
        final list = vm.list;
        if (list == null) return Text(l10n.shoppingNotConfigured);
        final items = vm.items;
        final done = items.where((i) => i.done).length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(list.name, style: Theme.of(context).textTheme.labelLarge),
            for (final item in items)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
                value: item.done,
                onChanged: (_) => vm.toggle(item),
                title: Text(
                  item.summary,
                  style: item.done
                      ? const TextStyle(decoration: TextDecoration.lineThrough)
                      : null,
                ),
              ),
            if (items.isEmpty) Text(l10n.shoppingEmpty),
            const SizedBox(height: Dimens.gapTiny),
            TextField(
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
            Wrap(
              alignment: WrapAlignment.end,
              children: [
                if (done > 0)
                  TextButton(
                    onPressed: vm.clearCompleted,
                    child: Text(l10n.shoppingClear(done)),
                  ),
                TextButton(
                  onPressed: () => context.push(Routes.shopping),
                  child: Text(l10n.shoppingOpen),
                ),
              ],
            ),
          ],
        );
      },
    ),
  );
}
