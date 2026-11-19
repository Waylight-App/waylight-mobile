import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/widgets/section_card.dart';

/// The card for widget kinds without a native view in the app; the
/// dashboard uses it for every kind the widget registry does not know.
class WidgetCard extends StatelessWidget {
  /// Creates the card for [widget].
  const WidgetCard({required this.widget, super.key});

  /// The widget to show.
  final WidgetPlacement widget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      title: widget.displayTitle,
      child: Text(
        context.l10n.dashboardWidgetNotYet,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
