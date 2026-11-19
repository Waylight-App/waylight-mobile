import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/ui/core/error_messages.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/core/widgets/section_card.dart';
import 'package:waylight_mobile/utils/command.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The card around a dashboard widget that loads data: title, a progress
/// indicator while [load] runs for the first time, the error with *Try
/// again*, and otherwise the content from [builder].
///
/// Errors stay inside the card, so one failing widget never breaks the tab.
class WidgetFrame<T> extends StatelessWidget {
  /// Creates the frame.
  const WidgetFrame({
    required this.title,
    required this.load,
    required this.builder,
    super.key,
  });

  /// The title of the widget.
  final String title;

  /// Loads the widget's data; [WidgetFrame] runs it again on *Try again*.
  final Command0<T> load;

  /// Builds the content once data is there.
  final Widget Function(BuildContext context, T data) builder;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SectionCard(
      title: title,
      child: ListenableBuilder(
        listenable: load,
        builder: (context, _) => switch (load.result) {
          // A reload keeps showing the previous data.
          Ok(:final value) => builder(context, value),
          Error(:final error) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.errorMessage(error)),
              TextButton(
                onPressed: load.running ? null : () => load.execute().ignore(),
                child: Text(l10n.dashboardRetry),
              ),
            ],
          ),
          null => const Center(
            child: Padding(
              padding: EdgeInsets.all(Dimens.gapSmall),
              child: SizedBox.square(
                dimension: Dimens.inlineProgress,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        },
      ),
    );
  }
}
