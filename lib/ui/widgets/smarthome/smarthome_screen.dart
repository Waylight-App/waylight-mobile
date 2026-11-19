import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:waylight_mobile/data/repositories/actions/smarthome_repository.dart';
import 'package:waylight_mobile/domain/models/actions.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/widgets/common/error_snack_listener.dart';
import 'package:waylight_mobile/ui/widgets/common/items_view_model.dart';
import 'package:waylight_mobile/ui/widgets/smarthome/smart_entity_tile.dart';

/// Every entity the owner chose for Waylight (#107), grouped by domain
/// (lights, switches, sensors …), with the same switches as the widget.
class SmartHomeScreen extends StatelessWidget {
  /// Creates the screen for [viewModel].
  const SmartHomeScreen({required this.viewModel, super.key});

  /// Loads the entities and switches them.
  final ItemsViewModel<SmartEntity> viewModel;

  @override
  Widget build(BuildContext context) {
    final home = context.read<SmartHomeRepository>();
    final vm = viewModel;
    return ErrorSnackListener(
      listenable: vm,
      takeError: vm.takeLastError,
      child: ListenableBuilder(
        listenable: Listenable.merge([vm, vm.load]),
        builder: (context, _) {
          final groups = <String, List<SmartEntity>>{};
          for (final e in vm.items) {
            groups.putIfAbsent(e.id.split('.').first, () => []).add(e);
          }
          return Scaffold(
            appBar: AppBar(title: Text(context.l10n.smartHomeTitle)),
            body: RefreshIndicator(
              onRefresh: vm.load.execute,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: Dimens.gap),
                children: [
                  if (vm.items.isEmpty && !vm.load.running)
                    Text(context.l10n.smartHomeEmpty),
                  for (final MapEntry(key: domain, value: entities)
                      in groups.entries) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: Dimens.gap),
                      child: Text(
                        domain.replaceAll('_', ' '),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    for (final e in entities)
                      SmartEntityTile(
                        entity: e,
                        canAct: vm.canEdit,
                        onAct: (e, {on}) => vm.change(
                          e,
                          on == null ? e : e.withState(on ? 'on' : 'off'),
                          (server) => home.act(server, e.id),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
