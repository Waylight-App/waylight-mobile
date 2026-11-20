import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/domain/models/search.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/core/widgets/rows.dart';

/// One answer of the server's smart search (#82): the five kinds drawn with
/// the rows of the widgets. Actions are not offered in the app yet; their
/// text is shown.
class AnswerCard extends StatelessWidget {
  /// Creates the card for [answer].
  const AnswerCard({
    required this.answer,
    required this.onSuggestion,
    this.onOpenWidget,
    super.key,
  });

  /// The answer.
  final SearchAnswer answer;

  /// Puts a suggested name into the search.
  final ValueChanged<String> onSuggestion;

  /// Opens the widget with the details; `null` hides the button.
  final VoidCallback? onOpenWidget;

  static Tone _tone(AnswerState? s) => switch (s) {
    AnswerState.ok => Tone.ok,
    AnswerState.warning => Tone.warning,
    AnswerState.error => Tone.critical,
    AnswerState.off || null => Tone.neutral,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = answer;
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: Dimens.gap,
        vertical: Dimens.gapTiny,
      ),
      child: Padding(
        padding: const EdgeInsets.all(Dimens.gapCard),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(a.title, style: theme.textTheme.titleSmall),
            const SizedBox(height: Dimens.gapTiny),
            ...switch (a.kind) {
              AnswerKind.metric => [
                // The meter shows the percentage itself; the detail is its label.
                if (a.percent case final p?)
                  MeterRow(
                    label: a.detail.isEmpty ? a.title : a.detail,
                    percent: p,
                  )
                else ...[
                  Text(a.value, style: theme.textTheme.headlineSmall),
                  if (a.detail.isNotEmpty)
                    Text(a.detail, style: theme.textTheme.bodySmall),
                ],
              ],
              AnswerKind.status => [
                InfoRow(
                  leading: StatusDot(tone: _tone(a.state), label: a.text),
                  title: a.text,
                  subtitle: a.detail,
                ),
              ],
              AnswerKind.list => [
                if (a.items.isEmpty) Text(a.empty),
                for (final i in a.items)
                  if (i.percent case final p?)
                    MeterRow(label: i.label, percent: p, detail: i.value)
                  else
                    InfoRow(
                      leading: i.state == null
                          ? null
                          : StatusDot(tone: _tone(i.state), label: i.value),
                      title: i.label,
                      subtitle: i.value,
                    ),
              ],
              AnswerKind.text || AnswerKind.actions => [
                Text(a.text),
                if (a.suggestions.isNotEmpty) ...[
                  const SizedBox(height: Dimens.gapSmall),
                  Wrap(
                    spacing: Dimens.gapSmall,
                    children: [
                      for (final s in a.suggestions)
                        ActionChip(
                          label: Text(s),
                          onPressed: () => onSuggestion(s),
                        ),
                    ],
                  ),
                ],
              ],
            },
            if (onOpenWidget != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onOpenWidget,
                  child: Text(context.l10n.searchOpenWidget),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
