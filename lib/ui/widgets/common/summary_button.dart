import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:waylight_mobile/data/repositories/actions/summary_repository.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/ui/core/error_messages.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/utils/result.dart';

/// Whether the server has summaries set up (#155); `false` without a
/// server.
Future<bool> summariesAvailable(BuildContext context) {
  final server = context.read<ServerRepository>().current;
  return server == null
      ? Future.value(false)
      : context.read<SummaryRepository>().available(server);
}

/// Shows the AI summary of [text], or of the page behind [url], with a field
/// to ask a question about it (#155).
Future<void> showSummarySheet(
  BuildContext context, {
  String text = '',
  Uri? url,
}) async {
  final server = context.read<ServerRepository>().current;
  if (server == null) return;
  final repo = context.read<SummaryRepository>();
  final language = Localizations.localeOf(context).languageCode;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _SummarySheet(
      summary: repo.summarise(server, language: language, text: text, url: url),
      ask: (question, summary) => repo.ask(
        server,
        question: question,
        // The note's text when there is one; for a page the summary.
        context: text.isNotEmpty ? text : summary,
        language: language,
      ),
    ),
  );
}

class _SummarySheet extends StatefulWidget {
  const _SummarySheet({required this.summary, required this.ask});

  final Future<Result<String>> summary;
  final Future<Result<String>> Function(String question, String summary) ask;

  @override
  State<_SummarySheet> createState() => _SummarySheetState();
}

class _SummarySheetState extends State<_SummarySheet> {
  final _question = TextEditingController();
  Future<Result<String>>? _answer;

  @override
  void dispose() {
    _question.dispose();
    super.dispose();
  }

  void _ask(String summary) {
    final q = _question.text.trim();
    if (q.isEmpty) return;
    final answer = widget.ask(q, summary);
    setState(() {
      _answer = answer;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: Dimens.gap,
          right: Dimens.gap,
          top: Dimens.gap,
          // Keeps the question field above the keyboard.
          bottom: Dimens.gap + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: FutureBuilder(
          future: widget.summary,
          builder: (context, snapshot) => switch (snapshot.data) {
            Ok(:final value) => SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.summaryTitle, style: theme.textTheme.titleMedium),
                  const SizedBox(height: Dimens.gapSmall),
                  SelectableText(value),
                  const SizedBox(height: Dimens.gapSmall),
                  Text(l10n.summaryByAi, style: theme.textTheme.bodySmall),
                  const SizedBox(height: Dimens.gap),
                  TextField(
                    controller: _question,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _ask(value),
                    decoration: InputDecoration(
                      labelText: l10n.summaryAsk,
                      suffixIcon: IconButton(
                        tooltip: l10n.summaryAsk,
                        icon: const Icon(Icons.send),
                        onPressed: () => _ask(value),
                      ),
                    ),
                  ),
                  if (_answer case final answer?)
                    FutureBuilder(
                      future: answer,
                      builder: (context, a) => Padding(
                        padding: const EdgeInsets.only(top: Dimens.gapSmall),
                        child: switch (a.data) {
                          Ok(:final value) => SelectableText(value),
                          Error(:final error) => Text(l10n.errorMessage(error)),
                          null => const LinearProgressIndicator(),
                        },
                      ),
                    ),
                ],
              ),
            ),
            Error(:final error) => Text(l10n.errorMessage(error)),
            null => const Center(child: CircularProgressIndicator()),
          },
        ),
      ),
    );
  }
}

/// "Summarise" for a note or an article (#155): shown only when the server
/// has a local Ollama set up.
class SummaryButton extends StatefulWidget {
  /// Creates the button for [text] or the page behind [url].
  const SummaryButton({this.text, this.url, super.key});

  /// The text to summarise, read when tapped.
  final String Function()? text;

  /// The page to summarise.
  final Uri? url;

  @override
  State<SummaryButton> createState() => _SummaryButtonState();
}

class _SummaryButtonState extends State<SummaryButton> {
  Future<bool>? _available;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _available ??= summariesAvailable(context);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _available,
    builder: (context, snapshot) => snapshot.data == true
        ? IconButton(
            tooltip: context.l10n.summaryAction,
            icon: const Icon(Icons.auto_awesome),
            onPressed: () => showSummarySheet(
              context,
              text: widget.text?.call() ?? '',
              url: widget.url,
            ),
          )
        : const SizedBox.shrink(),
  );
}
