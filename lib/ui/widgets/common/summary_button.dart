import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:waylight_mobile/data/repositories/actions/summary_repository.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/ui/core/error_messages.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/utils/result.dart';

/// "Summarise" for a note or an article (#155): shown only when the server
/// has a local Ollama set up; the summary opens in a sheet.
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
    final server = context.read<ServerRepository>().current;
    _available ??= server == null
        ? Future.value(false)
        : context.read<SummaryRepository>().available(server);
  }

  Future<void> _summarise() async {
    final server = context.read<ServerRepository>().current;
    if (server == null) return;
    final repo = context.read<SummaryRepository>();
    final summary = repo.summarise(
      server,
      language: Localizations.localeOf(context).languageCode,
      text: widget.text?.call() ?? '',
      url: widget.url,
    );
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Dimens.gap),
          child: FutureBuilder(
            future: summary,
            builder: (context, snapshot) => switch (snapshot.data) {
              Ok(:final value) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.summaryTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: Dimens.gapSmall),
                  SelectableText(value),
                  const SizedBox(height: Dimens.gapSmall),
                  Text(
                    context.l10n.summaryByAi,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              Error(:final error) => Text(context.l10n.errorMessage(error)),
              null => const Center(child: CircularProgressIndicator()),
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _available,
    builder: (context, snapshot) => snapshot.data == true
        ? IconButton(
            tooltip: context.l10n.summaryAction,
            icon: const Icon(Icons.auto_awesome),
            onPressed: _summarise,
          )
        : const SizedBox.shrink(),
  );
}
