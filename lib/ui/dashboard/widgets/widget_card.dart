import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/ui/core/link_opener.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/widget_size_scope.dart';
import 'package:waylight_mobile/ui/core/widgets/compact_card.dart';
import 'package:waylight_mobile/ui/core/widgets/section_card.dart';
import 'package:waylight_mobile/ui/core/widgets/set_up_prompt.dart';

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

/// A widget that misses a setting, as the server's attention list says
/// (#230): what is missing and *Set up*, which opens the widget's tab in
/// the web interface, in every tile size.
class SetUpCard extends StatelessWidget {
  /// Creates the card for [widget]; [webUrl] opens its tab.
  const SetUpCard({
    required this.widget,
    required this.message,
    this.webUrl,
    super.key,
  });

  /// The widget to set up.
  final WidgetPlacement widget;

  /// What is missing, as the server words it; empty for a general hint.
  final String message;

  /// The tab of the widget in the web interface.
  final Uri? webUrl;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final url = webUrl;
    final need = (
      message: message.isEmpty ? l10n.setUpMissing : message,
      onSetUp: url == null
          ? () {}
          : () => openLink(context, url, l10n.linkOpenFailed).ignore(),
    );
    final size = WidgetSizeScope.maybeOf(context);
    if (size != null && isCompact(size)) {
      return CompactCard(
        title: widget.displayTitle,
        size: size,
        child: SetUpPrompt(need: need, compact: true),
      );
    }
    return SectionCard(
      title: widget.displayTitle,
      child: SetUpPrompt(need: need),
    );
  }
}
