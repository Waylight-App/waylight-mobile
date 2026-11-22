import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:waylight_mobile/data/repositories/actions/smarthome_repository.dart';
import 'package:waylight_mobile/domain/models/actions.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/routing/routes.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/core/widget_size_scope.dart';
import 'package:waylight_mobile/ui/core/widgets/tile_rows.dart';
import 'package:waylight_mobile/ui/widgets/common/compact_state_widget.dart';
import 'package:waylight_mobile/ui/widgets/common/items_view_model.dart';
import 'package:waylight_mobile/ui/widgets/common/items_widget.dart';
import 'package:waylight_mobile/ui/widgets/smarthome/smart_entity_tile.dart';

/// The native view of the smart home widget (#146): the chosen entities
/// with their state; switches and buttons the owner allowed can be used,
/// but not by guests.
class SmartHomeWidget extends StatelessWidget {
  /// Creates the view for [widget].
  const SmartHomeWidget({required this.widget, super.key});

  /// The placement of the widget.
  final WidgetPlacement widget;

  /// The builder for the widget registry.
  /// Small and strip tiles show the server's compact state (#274).
  static Widget forPlacement(BuildContext context, WidgetPlacement widget) =>
      CompactStateWidget.orFull(
        context,
        widget,
        title: widget.title.isNotEmpty
            ? widget.title
            : context.l10n.smartHomeTitle,
        full: () => SmartHomeWidget(widget: widget, key: ValueKey(widget.id)),
      );

  @override
  Widget build(BuildContext context) {
    final ids = [
      if (widget.config['entities'] case final List<Object?> list)
        for (final e in list)
          if (e is String) e,
    ];
    return ItemsWidget<SmartEntity>(
      title: widget.title.isNotEmpty
          ? widget.title
          : context.l10n.smartHomeTitle,
      interval: const Duration(seconds: 30),
      // The first entity, with its switch as the tile's quick action (#226).
      compact: (context, vm, size) {
        final home = context.read<SmartHomeRepository>();
        final e = vm.items.firstOrNull;
        if (e == null) return Text(context.l10n.smartHomeEmpty, maxLines: 2);
        final toggle = vm.canEdit && e.action == EntityAction.toggle;
        return Row(
          children: [
            Expanded(
              child: Text(
                toggle || e.state.isEmpty ? e.name : '${e.name} · ${e.state}',
                maxLines: size == WidgetSize.strip ? 1 : 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (toggle)
              Switch(
                key: const ValueKey('smartHome.quick'),
                value: e.isOn,
                onChanged: (on) => vm.change(
                  e,
                  e.withState(on ? 'on' : 'off'),
                  (server) => home.act(server, e.id),
                ),
              ),
          ],
        );
      },
      create: (context) {
        final home = context.read<SmartHomeRepository>();
        return ItemsViewModel(
          serverRepository: context.read(),
          fetch: (server) => home.entities(server, ids: ids),
          id: (e) => e.id,
        );
      },
      builder: (context, vm) {
        final home = context.read<SmartHomeRepository>();
        if (vm.items.isEmpty) return Text(context.l10n.smartHomeEmpty);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TileRows(
              items: vm.items,
              rowHeight: Dimens.tapTarget + 8,
              rowBuilder: (context, e) => SmartEntityTile(
                entity: e,
                canAct: vm.canEdit,
                onAct: (e, {on}) => vm.change(
                  e,
                  on == null ? e : e.withState(on ? 'on' : 'off'),
                  (server) => home.act(server, e.id),
                ),
              ),
            ),
            if (!WidgetSizeScope.inGrid(context))
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push(Routes.smartHome),
                  child: Text(context.l10n.smartHomeAll),
                ),
              ),
          ],
        );
      },
    );
  }
}
