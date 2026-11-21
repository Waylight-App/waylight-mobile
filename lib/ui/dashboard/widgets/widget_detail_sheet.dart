import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/ui/core/refresh.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';

/// The full view of a widget in a sheet over the dashboard, opened from a
/// small or strip tile (#226). It can be dragged higher, and swiping down
/// or back closes it.
class WidgetDetailSheet extends StatelessWidget {
  const WidgetDetailSheet._({
    required this.placement,
    required this.child,
    required this.scrollController,
  });

  /// The widget shown.
  final WidgetPlacement placement;

  /// The widget's full view, with its actions.
  final Widget child;

  /// Lets the list scroll and the sheet follow the drag.
  final ScrollController scrollController;

  /// How much of the screen the sheet takes when it opens.
  static const initialSize = 0.6;

  /// Shows [child] for [placement] in a sheet.
  static Future<void> show(
    BuildContext context, {
    required WidgetPlacement placement,
    required Widget child,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: initialSize,
      maxChildSize: 1,
      builder: (context, controller) => WidgetDetailSheet._(
        placement: placement,
        scrollController: controller,
        child: child,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Its own refresh host: the widget reloads while the sheet is open,
    // and pull to refresh reloads it.
    return RefreshHost(
      child: Builder(
        builder: (context) => RefreshIndicator(
          onRefresh: () =>
              RefreshHost.maybeOf(context)?.refresh() ?? Future.value(),
          child: ListView(
            key: const ValueKey('widgetDetailSheet'),
            controller: scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              Dimens.gap,
              0,
              Dimens.gap,
              Dimens.gap,
            ),
            children: [
              Semantics(
                header: true,
                child: Text(
                  placement.displayTitle,
                  style: theme.textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: Dimens.gapSmall),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
