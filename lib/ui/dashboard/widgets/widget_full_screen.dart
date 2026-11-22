import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/refresh.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';

/// One widget of the dashboard in full, opened from its grid tile (#208):
/// the same view as in a list, at its natural height, with pull to
/// refresh.
class WidgetFullScreen extends StatelessWidget {
  /// Creates the screen for [placement], showing [child].
  const WidgetFullScreen({
    required this.placement,
    required this.child,
    this.onHelp,
    super.key,
  });

  /// The widget shown.
  final WidgetPlacement placement;

  /// The widget's view.
  final Widget child;

  /// Shows the help of the widget (#289); `null` hides the button.
  final VoidCallback? onHelp;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(placement.displayTitle),
        actions: [
          if (onHelp case final help?)
            IconButton(
              key: const ValueKey('widget.help'),
              tooltip: context.l10n.widgetHelpMenu,
              icon: const Icon(Icons.help_outline),
              onPressed: help,
            ),
        ],
      ),
      body: RefreshHost(
        child: Builder(
          builder: (context) => RefreshIndicator(
            onRefresh: () =>
                RefreshHost.maybeOf(context)?.refresh() ?? Future.value(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(Dimens.gap),
              children: [child],
            ),
          ),
        ),
      ),
    );
  }
}
