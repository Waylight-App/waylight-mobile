import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/ui/core/link_opener.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/widgets/section_card.dart';

/// The card for widget kinds without a native view in the app (#18): the
/// title, a short note and one button that opens the widget's tab in the
/// web interface.
class WidgetCard extends StatelessWidget {
  /// Creates the card for [widget]; [webUrl] opens its tab, `null` hides
  /// the button.
  const WidgetCard({required this.widget, this.webUrl, super.key});

  /// The widget to show.
  final WidgetPlacement widget;

  /// The tab of the widget in the web interface.
  final Uri? webUrl;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final url = webUrl;
    return SectionCard(
      title: widget.displayTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.dashboardWidgetNotYet,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (url != null)
            TextButton.icon(
              onPressed: () => openLink(context, url, l10n.linkOpenFailed),
              icon: const Icon(Icons.open_in_new),
              label: Text(l10n.dashboardOpenInWaylight),
            ),
        ],
      ),
    );
  }
}
