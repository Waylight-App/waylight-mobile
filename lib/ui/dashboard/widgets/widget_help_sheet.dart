import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/help.dart';
import 'package:waylight_mobile/ui/core/compact_texts.dart';
import 'package:waylight_mobile/ui/core/link_opener.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/utils/result.dart';

/// Loads the help of a widget kind; `null` when the server has none.
typedef HelpLoader = Future<Result<WidgetHelp?>> Function(String kind);

/// What a widget shows and how to set it up, in a sheet (#289). The texts
/// are the server's, so the web interface and the app say the same.
class WidgetHelpSheet extends StatefulWidget {
  const WidgetHelpSheet._({required this.placement, required this.load});

  /// The widget the help is for.
  final WidgetPlacement placement;

  /// Reads the help.
  final HelpLoader load;

  /// Shows the help of [placement] in a sheet.
  static Future<void> show(
    BuildContext context, {
    required WidgetPlacement placement,
    required HelpLoader load,
  }) {
    // The sheet lives in the navigator, outside the scope of the screen.
    final opener = LinkOpener.of(context);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) => LinkOpenerScope(
        opener: opener,
        child: WidgetHelpSheet._(placement: placement, load: load),
      ),
    );
  }

  @override
  State<WidgetHelpSheet> createState() => _WidgetHelpSheetState();
}

class _WidgetHelpSheetState extends State<WidgetHelpSheet> {
  late final Future<Result<WidgetHelp?>> _help = widget.load(
    widget.placement.kind,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        Dimens.gap,
        0,
        Dimens.gap,
        Dimens.gapLarge,
      ),
      child: FutureBuilder<Result<WidgetHelp?>>(
        future: _help,
        builder: (context, snapshot) {
          final result = snapshot.data;
          final help = switch (result) {
            Ok(:final value) => value,
            _ => null,
          };
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  l10n.widgetHelpTitle(widget.placement.displayTitle),
                  style: theme.textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: Dimens.gap),
              if (result == null)
                const Center(child: CircularProgressIndicator())
              else if (help == null)
                Text(l10n.widgetHelpUnavailable)
              else ...[
                _Section(
                  heading: l10n.widgetHelpShows,
                  text: compactTextOf(l10n, help.shows),
                ),
                _Section(
                  heading: l10n.widgetHelpSetUp,
                  text: compactTextOf(l10n, help.setUp),
                ),
              ],
              if (result != null)
                TextButton.icon(
                  onPressed: () => openLink(
                    context,
                    help?.docsUrl ?? documentationUrl,
                    l10n.linkOpenFailed,
                  ),
                  icon: const Icon(Icons.open_in_new),
                  label: Text(l10n.widgetHelpDocs),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.heading, required this.text});

  final String heading;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimens.gap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(heading, style: theme.textTheme.titleSmall),
          ),
          const SizedBox(height: Dimens.gapTiny),
          Text(text, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
