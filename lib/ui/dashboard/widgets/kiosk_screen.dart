import 'package:material_ui/material_ui.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/core/widget_registry.dart';
import 'package:waylight_mobile/ui/dashboard/view_models/kiosk_view_model.dart';
import 'package:waylight_mobile/ui/dashboard/widgets/dashboard_screen.dart';

/// The wall display (#193): full screen, the screen kept on, the kiosk's
/// tabs read-only. Leaving needs the device credential.
class KioskScreen extends StatelessWidget {
  /// Creates the screen for [viewModel].
  const KioskScreen({
    required this.viewModel,
    required this.registry,
    super.key,
  });

  /// The state and actions of this screen.
  final KioskViewModel viewModel;

  /// The native views by widget kind.
  final WidgetRegistry registry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final vm = viewModel;
    return Scaffold(
      body: ListenableBuilder(
        listenable: Listenable.merge([vm, vm.load]),
        builder: (context, _) {
          final tabs = vm.tabs;
          final content = tabs.isEmpty
              ? Center(
                  child: vm.load.running
                      ? const CircularProgressIndicator()
                      : Text(l10n.kioskNoTabs),
                )
              : AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: TabPage(
                    key: ValueKey(tabs[vm.index].id),
                    tab: tabs[vm.index],
                    registry: registry,
                    readOnly: true,
                  ),
                );
          return Stack(
            children: [
              Positioned.fill(child: SafeArea(child: content)),
              // Night dimming: a dark veil the screen shows through.
              if (vm.night)
                Positioned.fill(
                  child: IgnorePointer(
                    child: ColoredBox(
                      color: Theme.of(context).colorScheme.scrim
                          .withValues(alpha: 0.85),
                    ),
                  ),
                ),
              Positioned(
                top: Dimens.gapSmall,
                right: Dimens.gapSmall,
                child: SafeArea(
                  child: Opacity(
                    opacity: 0.4,
                    child: Tooltip(
                      message: l10n.kioskLeave,
                      child: Semantics(
                        button: true,
                        label: l10n.kioskLeave,
                        onLongPressHint: l10n.kioskLeave,
                        // A long press, so a passing hand does not open it.
                        child: InkResponse(
                          key: const ValueKey('kiosk.leave'),
                          onLongPress: () =>
                              vm.leave(l10n.kioskLeaveReason).ignore(),
                          radius: Dimens.tapTarget / 2,
                          child: const SizedBox.square(
                            dimension: Dimens.tapTarget,
                            child: Icon(Icons.lock_open_outlined),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
