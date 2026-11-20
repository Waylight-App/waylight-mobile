import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/domain/models/dashboard.dart';
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
    super.key,
  });

  /// The widget shown.
  final WidgetPlacement placement;

  /// The widget's view.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(placement.displayTitle)),
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
