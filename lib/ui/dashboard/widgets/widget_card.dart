import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/widgets/section_card.dart';

/// Shows one widget of a tab.
///
/// Every kind gets this card until it has a native renderer (#17); the
/// renderers then plug in by kind (docs/architecture.md, widget registry).
class WidgetCard extends StatelessWidget {
  /// Creates the card for [widget].
  const WidgetCard({required this.widget, super.key});

  /// The widget to show.
  final WidgetPlacement widget;

  /// The title of [widget]: the one the user gave it, else its kind in
  /// words, e.g. `status-overview` → "Status overview".
  static String titleOf(WidgetPlacement widget) {
    if (widget.title.isNotEmpty) return widget.title;
    final words = widget.kind.replaceAll(RegExp('[-_]+'), ' ').trim();
    if (words.isEmpty) return widget.kind;
    return words[0].toUpperCase() + words.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      title: titleOf(widget),
      child: Text(
        context.l10n.dashboardWidgetNotYet,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
