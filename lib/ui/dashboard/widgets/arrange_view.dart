import 'dart:math';

import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/ui/core/error_messages.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/core/widget_registry.dart';
import 'package:waylight_mobile/ui/core/widget_size_scope.dart';
import 'package:waylight_mobile/ui/core/widgets/message_banner.dart';
import 'package:waylight_mobile/ui/core/widgets/section_card.dart';
import 'package:waylight_mobile/ui/core/widgets/sized_grid.dart';
import 'package:waylight_mobile/ui/dashboard/view_models/arrange_view_model.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The edit mode of a tab, in place of its page on the dashboard (#209,
/// docs/design: *Edit mode*): the widgets wiggle on the same grid and move
/// by holding and dragging; each has **−** to hide it on phones and a size
/// button. Hidden widgets are listed below, to show them again.
///
/// Without dragging — with a screen reader or a keyboard — widgets move
/// with *move earlier* and *move later* in the sheet of their size button.
class ArrangeView extends StatelessWidget {
  /// Creates the view for [viewModel].
  const ArrangeView({
    required this.viewModel,
    required this.registry,
    super.key,
  });

  /// The state and actions of the edit mode.
  final ArrangeViewModel viewModel;

  /// The native views by widget kind, for the previews in the tiles.
  final WidgetRegistry registry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) => ListView(
        key: const ValueKey('arrange'),
        padding: const EdgeInsets.all(Dimens.gap),
        children: [
          MessageBanner(kind: MessageKind.info, message: l10n.editTabHint),
          const SizedBox(height: Dimens.gapLarge),
          _ArrangeGrid(viewModel: viewModel, registry: registry),
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
    );
  }
}

/// The size a widget takes in the edit grid: its own, or medium for widgets
/// without a size, which take the full width on the dashboard.
WidgetSize _shownSize(PhoneLayoutItem item) => item.size ?? WidgetSize.medium;

/// The name of a size; `null` is the full width.
String sizeName(AppLocalizations l10n, WidgetSize? size) => switch (size) {
  null => l10n.widgetSizeFull,
  WidgetSize.small => l10n.widgetSizeSmall,
  WidgetSize.medium => l10n.widgetSizeMedium,
  WidgetSize.large => l10n.widgetSizeLarge,
  WidgetSize.strip => l10n.widgetSizeStrip,
};

/// The visible widgets on the grid, wiggling as on a phone's home screen
/// unless animations are reduced.
class _ArrangeGrid extends StatefulWidget {
  const _ArrangeGrid({required this.viewModel, required this.registry});

  final ArrangeViewModel viewModel;
  final WidgetRegistry registry;

  @override
  State<_ArrangeGrid> createState() => _ArrangeGridState();
}

class _ArrangeGridState extends State<_ArrangeGrid>
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
      tileBuilder: (context, place, size) => _ArrangeTile(
        item: byId[place.id]!,
        size: size,
        viewModel: widget.viewModel,
        registry: widget.registry,
        wiggle: _wiggle,
        // Neighbours wiggle in opposite directions, as on a home screen.
        sign: order.indexOf(place.id).isEven ? 1 : -1,
      ),
    );
  }
}

/// One widget in the edit grid: a preview of its view with the controls of
/// the edit mode on top.
class _ArrangeTile extends StatelessWidget {
  const _ArrangeTile({
    required this.item,
    required this.size,
    required this.viewModel,
    required this.registry,
    required this.wiggle,
    required this.sign,
  });

  final PhoneLayoutItem item;
  final Size size;
  final ArrangeViewModel viewModel;
  final WidgetRegistry registry;
  final Animation<double> wiggle;
  final int sign;

  String get _id => item.widget.id;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    final title = item.widget.displayTitle;
    // Narrow tiles show only the icon of the size button.
    final narrow = size.width < 200 || size.height < 100;
    final tile = Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Dimens.radiusCard),
              border: Border.all(color: colors.outlineVariant, width: 2),
            ),
            child: _Preview(
              item: item,
              registry: registry,
              height: size.height,
            ),
          ),
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
          bottom: 0,
          end: 0,
          child: narrow
              ? IconButton.filledTonal(
                  key: ValueKey('editTab.size.$_id'),
                  tooltip: l10n.editTabSize(sizeName(l10n, item.size)),
                  icon: const Icon(Icons.open_in_full),
                  onPressed: () => _sheet(context),
                )
              : Padding(
                  padding: const EdgeInsets.all(Dimens.gapSmall),
                  child: FilledButton.tonalIcon(
                    key: ValueKey('editTab.size.$_id'),
                    icon: const Icon(
                      Icons.open_in_full,
                      size: Dimens.iconSmall,
                    ),
                    label: Text(sizeName(l10n, item.size)),
                    onPressed: () => _sheet(context),
                  ),
                ),
        ),
      ],
    );
    return Semantics(
      container: true,
      label: '$title, ${l10n.editTabSize(sizeName(l10n, item.size))}',
      child: DragTarget<String>(
        onWillAcceptWithDetails: (details) {
          if (details.data == _id) return false;
          viewModel.moveOnto(details.data, _id);
          return true;
        },
        builder: (context, _, _) => LongPressDraggable<String>(
          data: _id,
          // Short, so a hold starts a drag right away; a quick swipe still
          // scrolls the page.
          delay: const Duration(milliseconds: 150),
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

  void _sheet(BuildContext context) => SizeSheet.show(
    context,
    viewModel: viewModel,
    registry: registry,
    id: _id,
  ).ignore();
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
              child: WidgetSizeScope(
                size: _shownSize(item),
                child: builder == null
                    ? SectionCard(
                        title: widget.displayTitle,
                        child: const SizedBox(),
                      )
                    : Builder(builder: (context) => builder(context, widget)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The options of one widget (docs/design: *Choose a size*): its size with
/// a preview, moving it without dragging, hiding it on phones.
class SizeSheet extends StatelessWidget {
  const SizeSheet._({
    required this.viewModel,
    required this.registry,
    required this.id,
  });

  /// The edit mode the widget belongs to.
  final ArrangeViewModel viewModel;

  /// The native views, for the preview.
  final WidgetRegistry registry;

  /// The widget.
  final String id;

  /// Shows the sheet for widget [id].
  static Future<void> show(
    BuildContext context, {
    required ArrangeViewModel viewModel,
    required WidgetRegistry registry,
    required String id,
  }) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) =>
        SizeSheet._(viewModel: viewModel, registry: registry, id: id),
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
                  builder: (context, constraints) => Center(
                    child: SizedBox(
                      // The cell size of a phone, also on tablets.
                      width: min(constraints.maxWidth, 400),
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
                  ),
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
                        label: Text(sizeName(l10n, size)),
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

/// The widget kinds the server offers, to add one to the tab (#210,
/// docs/design: *Add a widget*).
class WidgetGallerySheet extends StatefulWidget {
  const WidgetGallerySheet._({required this.viewModel});

  /// The edit mode the widgets are added to.
  final ArrangeViewModel viewModel;

  /// Shows the gallery for the tab of [viewModel].
  static Future<void> show(
    BuildContext context, {
    required ArrangeViewModel viewModel,
  }) {
    if (viewModel.kinds.result is! Ok<List<String>>) {
      viewModel.kinds.execute().ignore();
    }
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => WidgetGallerySheet._(viewModel: viewModel),
    );
  }

  @override
  State<WidgetGallerySheet> createState() => _WidgetGallerySheetState();
}

class _WidgetGallerySheetState extends State<WidgetGallerySheet> {
  String _query = '';
  final Set<String> _added = {};

  Future<void> _add(String kind) async {
    final add = widget.viewModel.add;
    await add.execute(kind);
    if (!mounted) return;
    switch (add.result) {
      case Ok():
        setState(() => _added.add(kind));
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
    final theme = Theme.of(context);
    final viewModel = widget.viewModel;
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.8,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Dimens.gap),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.galleryTitle(viewModel.name),
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: Dimens.gap),
            TextField(
              key: const ValueKey('gallery.search'),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                labelText: l10n.gallerySearch,
              ),
              onChanged: (text) =>
                  setState(() => _query = text.trim().toLowerCase()),
            ),
            const SizedBox(height: Dimens.gapSmall),
            Expanded(
              child: ListenableBuilder(
                listenable: Listenable.merge([viewModel.kinds, viewModel.add]),
                builder: (context, _) => switch (viewModel.kinds.result) {
                  Ok(:final value) => _list(context, value),
                  Error(:final error) => MessageBanner(
                    kind: MessageKind.error,
                    message: l10n.errorMessage(error),
                  ),
                  null => const Center(child: CircularProgressIndicator()),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _list(BuildContext context, List<String> kinds) {
    final l10n = context.l10n;
    final shown = [
      for (final kind in kinds)
        if (_title(kind).toLowerCase().contains(_query)) kind,
    ];
    if (shown.isEmpty) return Text(l10n.galleryEmpty);
    final busy = widget.viewModel.add.running;
    return ListView.builder(
      itemCount: shown.length,
      itemBuilder: (context, i) {
        final kind = shown[i];
        final title = _title(kind);
        return ListTile(
          key: ValueKey('gallery.$kind'),
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(child: Text(title.characters.first)),
          title: Text(title),
          trailing: _added.contains(kind)
              ? Text(l10n.galleryAdded)
              : FilledButton.tonal(
                  key: ValueKey('gallery.add.$kind'),
                  onPressed: busy ? null : () => _add(kind).ignore(),
                  child: Text(l10n.galleryAdd),
                ),
        );
      },
    );
  }

  static String _title(String kind) =>
      WidgetPlacement(id: '', kind: kind).displayTitle;
}
