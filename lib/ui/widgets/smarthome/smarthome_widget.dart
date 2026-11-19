import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:waylight_mobile/data/repositories/actions/smarthome_repository.dart';
import 'package:waylight_mobile/domain/models/actions.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/widgets/common/items_view_model.dart';
import 'package:waylight_mobile/ui/widgets/common/items_widget.dart';
import 'package:waylight_mobile/ui/widgets/common/widget_rows.dart';

/// The native view of the smart home widget (#146): the chosen entities
/// with their state; switches and buttons the owner allowed can be used,
/// but not by guests.
class SmartHomeWidget extends StatelessWidget {
  /// Creates the view for [widget].
  const SmartHomeWidget({required this.widget, super.key});

  /// The placement of the widget.
  final WidgetPlacement widget;

  /// The builder for the widget registry.
  static Widget forPlacement(BuildContext context, WidgetPlacement widget) =>
      SmartHomeWidget(widget: widget, key: ValueKey(widget.id));

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
            for (final e in vm.items)
              switch (vm.canEdit ? e.action : EntityAction.none) {
                EntityAction.toggle => SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(e.name),
                  value: e.isOn,
                  onChanged: (on) => vm.change(
                    e,
                    e.withState(on ? 'on' : 'off'),
                    (server) => home.act(server, e.id),
                  ),
                ),
                EntityAction.press => InfoRow(
                  title: e.name,
                  trailing: context.l10n.smartHomeRun,
                  onTap: () =>
                      vm.change(e, e, (server) => home.act(server, e.id)),
                ),
                EntityAction.none => InfoRow(
                  title: e.name,
                  trailing: e.unit.isEmpty ? e.state : '${e.state} ${e.unit}',
                ),
              },
          ],
        );
      },
    );
  }
}
