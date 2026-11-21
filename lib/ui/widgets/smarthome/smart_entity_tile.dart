import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/domain/models/actions.dart';
import 'package:waylight_mobile/domain/models/tag_action.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/widgets/common/tag_writer.dart';
import 'package:waylight_mobile/ui/widgets/common/widget_rows.dart';

/// One Home Assistant entity: a switch, a button or its state, as the
/// owner allowed and the account may (#146, #107).
class SmartEntityTile extends StatelessWidget {
  /// Creates the tile.
  const SmartEntityTile({
    required this.entity,
    required this.canAct,
    required this.onAct,
    super.key,
  });

  /// The entity.
  final SmartEntity entity;

  /// Whether the account may use switches and buttons.
  final bool canAct;

  /// Runs the entity's action; for a switch with the wanted state.
  final void Function(SmartEntity entity, {bool? on}) onAct;

  @override
  Widget build(BuildContext context) {
    final e = entity;
    final row = switch (canAct ? e.action : EntityAction.none) {
      EntityAction.toggle => SwitchListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        title: Text(e.name),
        value: e.isOn,
        onChanged: (on) => onAct(e, on: on),
      ),
      EntityAction.press => InfoRow(
        title: e.name,
        trailing: context.l10n.smartHomeRun,
        onTap: () => onAct(e),
      ),
      EntityAction.none => InfoRow(
        title: e.name,
        trailing: e.unit.isEmpty ? e.state : '${e.state} ${e.unit}',
      ),
    };
    // Only what the account may change can go onto an NFC tag (#195).
    if (!canAct || e.action == EntityAction.none) return row;
    return TagWritable(action: SmartHomeTag(e.id), subject: e.name, child: row);
  }
}
