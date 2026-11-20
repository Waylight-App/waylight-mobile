import 'dart:math';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';

import 'package:waylight_mobile/ui/core/error_messages.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/core/widget_registry.dart';
import 'package:waylight_mobile/ui/core/widget_size_scope.dart';
import 'package:waylight_mobile/ui/core/widgets/form_page.dart';
import 'package:waylight_mobile/ui/core/widgets/message_banner.dart';
import 'package:waylight_mobile/ui/core/widgets/section_card.dart';
import 'package:waylight_mobile/ui/core/widgets/sized_grid.dart';
import 'package:waylight_mobile/ui/edit_tab/view_models/edit_tab_view_model.dart';
import 'package:waylight_mobile/utils/command.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The edit mode of a tab (#209, docs/design: *Edit mode*): the widgets on
/// the grid of the dashboard, to move by holding and dragging, to resize
/// and to hide on phones. *Done* saves; leaving with changes asks first.
///
/// Without dragging — with a screen reader or a keyboard — widgets move
/// with *move earlier* and *move later* in the sheet of their size button.
class EditTabScreen extends StatelessWidget {
  /// Creates the screen for [viewModel].
  const EditTabScreen({
    required this.viewModel,
    required this.registry,
    super.key,
  });

  /// The state and actions of this screen.
  final EditTabViewModel viewModel;

  /// The native views by widget kind, for the previews in the tiles.
  final WidgetRegistry registry;

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

  Future<void> _leave(BuildContext context) async {
    final l10n = context.l10n;
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.editTabDiscardTitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.editTabKeep),
          ),
          TextButton(
            key: const ValueKey('editTab.discard'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.editTabDiscard),
          ),
        ],
      ),
    );
    if ((discard ?? false) && context.mounted) context.pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListenableBuilder(
      listenable: Listenable.merge([viewModel, viewModel.load]),
      builder: (context, _) => PopScope<bool>(
        canPop: !viewModel.changed,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _leave(context).ignore();
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              viewModel.name.isEmpty ? l10n.editTabTitle : viewModel.name,
            ),
            actions: [
              PopupMenuButton<void>(
                key: const ValueKey('editTab.more'),
                itemBuilder: (context) => [
                  PopupMenuItem<void>(
                    key: const ValueKey('editTab.reset'),
                    onTap: () => _run(context, viewModel.reset),
                    child: Text(l10n.editTabReset),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(end: Dimens.gapSmall),
                child: FilledButton(
                  key: const ValueKey('editTab.save'),
                  onPressed: viewModel.load.result is Ok<void>
                      ? () => _run(context, viewModel.save)
                      : null,
                  child: Text(l10n.editTabDone),
                ),
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
            Ok() => ListView(
              padding: const EdgeInsets.all(Dimens.gap),
              children: [
                MessageBanner(
                  kind: MessageKind.info,
                  message: l10n.editTabHint,
                ),
                const SizedBox(height: Dimens.gapLarge),
                _EditGrid(viewModel: viewModel, registry: registry),
                if (viewModel.hidden.isNotEmpty) ...[
                  const SizedBox(height: Dimens.gapLarge),
                  Text(
                    l10n.editTabHidden,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: Dimens.gapSmall),
                  Wrap(
                    spacing: Dimens.gapSmall,
                    runSpacing: Dimens.gapSmall,
                    children: [
                      for (final item in viewModel.hidden)
                        ActionChip(
                          key: ValueKey('editTab.show.${item.widget.id}'),
                          avatar: const Icon(Icons.add),
                          label: Text(item.widget.displayTitle),
                          tooltip: l10n.editTabShow(item.widget.displayTitle),
                          onPressed: () => viewModel.showAgain(item.widget.id),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          },
        ),
      ),
    );
  }
}

/// The size a widget takes in the edit grid: its own, or medium for widgets
/// without a size, which take the full width on the dashboard.
WidgetSize _shownSize(PhoneLayoutItem item) => item.size ?? WidgetSize.medium;

/// The name of a size; `null` is the full width.
String _sizeName(AppLocalizations l10n, WidgetSize? size) => switch (size) {
  null => l10n.widgetSizeFull,
  WidgetSize.small => l10n.widgetSizeSmall,
  WidgetSize.medium => l10n.widgetSizeMedium,
  WidgetSize.large => l10n.widgetSizeLarge,
  WidgetSize.strip => l10n.widgetSizeStrip,
};

/// The visible widgets on the grid, wiggling as on a phone's home screen
/// unless animations are reduced.
class _EditGrid extends StatefulWidget {
  const _EditGrid({required this.viewModel, required this.registry});

  final EditTabViewModel viewModel;
  final WidgetRegistry registry;

  @override
  State<_EditGrid> createState() => _EditGridState();
}

class _EditGridState extends State<_EditGrid>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wiggle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _wiggle.stop();
    } else if (!_wiggle.isAnimating) {
      _wiggle.repeat(reverse: true).ignore();
    }
  }

  @override
  void dispose() {
    _wiggle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visible = widget.viewModel.visible;
    final byId = {for (final item in visible) item.widget.id: item};
    final order = [for (final item in visible) item.widget.id];
    return SizedGrid(
      animate: true,
      items: [
        for (final item in visible)
          (id: item.widget.id, size: _shownSize(item)),
      ],
      columns: SizedGrid.columnsOf(context),
      tileBuilder: (context, place, size) {
        // Neighbours wiggle in opposite directions, as on a home screen.
        final sign = order.indexOf(place.id).isEven ? 1 : -1;
        return _EditTile(
          item: byId[place.id]!,
          size: size,
          viewModel: widget.viewModel,
          registry: widget.registry,
          wiggle: _wiggle,
          sign: sign,
        );
      },
    );
  }
}

/// One widget in the edit grid: a preview of its view with the controls of
/// the edit mode on top.
class _EditTile extends StatelessWidget {
  const _EditTile({
    required this.item,
    required this.size,
    required this.viewModel,
    required this.registry,
    required this.wiggle,
    required this.sign,
  });

  final PhoneLayoutItem item;
  final Size size;
  final EditTabViewModel viewModel;
  final WidgetRegistry registry;
  final Animation<double> wiggle;
  final int sign;

  String get _id => item.widget.id;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    final title = item.widget.displayTitle;
    final tile = Stack(
      children: [
        Positioned.fill(
          child: _Preview(item: item, registry: registry, height: size.height),
        ),
        PositionedDirectional(
          top: 0,
          start: 0,
          child: IconButton.filled(
            key: ValueKey('editTab.hide.$_id'),
            tooltip: l10n.editTabHide(title),
            style: IconButton.styleFrom(
              backgroundColor: colors.inverseSurface,
              foregroundColor: colors.onInverseSurface,
            ),
            icon: const Icon(Icons.remove),
            onPressed: () => viewModel.hide(_id),
          ),
        ),
        PositionedDirectional(
          bottom: Dimens.gapSmall,
          start: Dimens.gapSmall,
          child: FilledButton.tonalIcon(
            key: ValueKey('editTab.size.$_id'),
            icon: const Icon(Icons.open_in_full, size: Dimens.iconSmall),
            label: Text(_sizeName(l10n, item.size)),
            onPressed: () => _SizeSheet.show(
              context,
              viewModel: viewModel,
              registry: registry,
              id: _id,
            ),
          ),
        ),
      ],
    );
    return Semantics(
      container: true,
      label: '$title, ${l10n.editTabSize(_sizeName(l10n, item.size))}',
      child: DragTarget<String>(
        onWillAcceptWithDetails: (details) {
          if (details.data == _id) return false;
          viewModel.moveOnto(details.data, _id);
          return true;
        },
        builder: (context, _, _) => LongPressDraggable<String>(
          data: _id,
          feedback: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(Dimens.radiusCard),
            child: SizedBox.fromSize(
              size: size,
              child: _Preview(
                item: item,
                registry: registry,
                height: size.height,
              ),
            ),
          ),
          childWhenDragging: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Dimens.radiusCard),
              border: Border.all(color: colors.outline, width: 2),
            ),
          ),
          child: RotationTransition(
            turns: wiggle.drive(
              Tween(begin: -0.0015 * sign, end: 0.0015 * sign),
            ),
            child: tile,
          ),
        ),
      ),
    );
  }
}

/// A widget's view as a still picture: the edit mode shows what the widget
/// looks like, but taps go to the controls.
class _Preview extends StatelessWidget {
  const _Preview({
    required this.item,
    required this.registry,
    required this.height,
  });

  final PhoneLayoutItem item;
  final WidgetRegistry registry;
  final double height;

  @override
  Widget build(BuildContext context) {
    final widget = item.widget;
    final builder = registry.builderFor(widget.kind);
    final view = builder == null
        ? SectionCard(title: widget.displayTitle, child: const SizedBox())
        : builder(context, widget);
    // AbsorbPointer, not IgnorePointer: the tile itself stays touchable, so
    // holding it starts a drag, but nothing inside the preview reacts.
    return AbsorbPointer(
      child: ExcludeSemantics(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Dimens.radiusCard),
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            primary: false,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: height),
              child: WidgetSizeScope(size: _shownSize(item), child: view),
            ),
          ),
        ),
      ),
    );
  }
}

/// The options of one widget (docs/design: *Choose a size*): its size with
/// a preview, moving it without dragging, hiding it on phones.
class _SizeSheet extends StatelessWidget {
  const _SizeSheet({
    required this.viewModel,
    required this.registry,
    required this.id,
  });

  final EditTabViewModel viewModel;
  final WidgetRegistry registry;
  final String id;

  static Future<void> show(
    BuildContext context, {
    required EditTabViewModel viewModel,
    required WidgetRegistry registry,
    required String id,
  }) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) =>
        _SizeSheet(viewModel: viewModel, registry: registry, id: id),
  );

  static const _choices = <WidgetSize?>[
    WidgetSize.small,
    WidgetSize.medium,
    WidgetSize.large,
    WidgetSize.strip,
    null,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final item = viewModel.items.firstWhere((i) => i.widget.id == id);
        final shown = viewModel.visible;
        final place = shown.indexWhere((i) => i.widget.id == id);
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              Dimens.gap,
              0,
              Dimens.gap,
              Dimens.gap,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  item.widget.displayTitle,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: Dimens.gap),
                LayoutBuilder(
                  builder: (context, constraints) {
                    // The preview keeps the cell size of the dashboard, at
                    // most as high as a large widget on a phone.
                    final width = min(constraints.maxWidth, 400.0);
                    return Center(
                      child: SizedBox(
                        width: width,
                        child: SizedGrid(
                          items: [(id: id, size: _shownSize(item))],
                          columns: 4,
                          tileBuilder: (context, _, size) => _Preview(
                            item: item,
                            registry: registry,
                            height: size.height,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: Dimens.gap),
                Wrap(
                  spacing: Dimens.gapSmall,
                  runSpacing: Dimens.gapSmall,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final size in _choices)
                      ChoiceChip(
                        key: ValueKey('editTab.sizeChoice.${size?.name}'),
                        label: Text(_sizeName(l10n, size)),
                        selected: item.size == size,
                        onSelected: (_) => viewModel.setSize(id, size),
                      ),
                  ],
                ),
                const SizedBox(height: Dimens.gap),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        key: const ValueKey('editTab.earlier'),
                        icon: const Icon(Icons.arrow_back),
                        label: Text(l10n.editTabUp),
                        onPressed: place > 0
                            ? () => viewModel.moveBy(id, -1)
                            : null,
                      ),
                    ),
                    Expanded(
                      child: TextButton.icon(
                        key: const ValueKey('editTab.later'),
                        icon: const Icon(Icons.arrow_forward),
                        label: Text(l10n.editTabDown),
                        onPressed: place >= 0 && place < shown.length - 1
                            ? () => viewModel.moveBy(id, 1)
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Dimens.gapSmall),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          viewModel.hide(id);
                          Navigator.of(context).pop();
                        },
                        child: Text(l10n.editTabHideOnPhones),
                      ),
                    ),
                    const SizedBox(width: Dimens.gapSmall),
                    Expanded(
                      child: FilledButton(
                        key: const ValueKey('editTab.sizeDone'),
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(l10n.editTabDone),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
