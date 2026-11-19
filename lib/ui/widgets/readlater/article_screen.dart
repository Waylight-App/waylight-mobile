import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/data/repositories/actions/read_later_repository.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/domain/models/media.dart';
import 'package:waylight_mobile/ui/core/error_messages.dart';
import 'package:waylight_mobile/ui/core/link_opener.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/widgets/common/summary_button.dart';
import 'package:waylight_mobile/utils/command.dart';
import 'package:waylight_mobile/utils/html_text.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The state of the reader (#104): one article, marked read when opened.
class ArticleViewModel extends ChangeNotifier {
  /// Creates the view model and starts loading.
  ArticleViewModel({
    required this.articleId,
    required this._serverRepository,
    required this._readLater,
  }) {
    load = Command0(_load)..execute().ignore();
    setStatus = Command1(_setStatus);
    remove = Command0(_remove);
  }

  /// The article shown.
  final String articleId;
  final ServerRepository _serverRepository;
  final ReadLaterRepository _readLater;

  /// Loads the article.
  late final Command0<Article> load;

  /// Marks it read, unread or archived.
  late final Command1<void, ArticleStatus> setStatus;

  /// Deletes it.
  late final Command0<void> remove;

  Future<Result<Article>> _load() async {
    final server = _serverRepository.current;
    if (server == null) return const Result.error(NotConnectedException());
    final result = await _readLater.article(server, articleId);
    if (result case Ok(:final value)
        when value.status == ArticleStatus.unread) {
      // Opening counts as reading, like in the web interface.
      await _readLater.setStatus(server, articleId, ArticleStatus.read);
      return Result.ok(value.withStatus(ArticleStatus.read));
    }
    return result;
  }

  Future<Result<void>> _setStatus(ArticleStatus status) async {
    final server = _serverRepository.current;
    if (server == null) return const Result.error(NotConnectedException());
    return _readLater.setStatus(server, articleId, status);
  }

  Future<Result<void>> _remove() async {
    final server = _serverRepository.current;
    if (server == null) return const Result.error(NotConnectedException());
    return _readLater.remove(server, articleId);
  }

  @override
  void dispose() {
    load.dispose();
    setStatus.dispose();
    remove.dispose();
    super.dispose();
  }
}

/// Reads a saved article in the app's theme and text size (#104).
class ArticleScreen extends StatelessWidget {
  /// Creates the screen for [viewModel].
  const ArticleScreen({required this.viewModel, super.key});

  /// The state and actions of this screen.
  final ArticleViewModel viewModel;

  Future<void> _done(BuildContext context, Command<void> command) async {
    if (command.result case Error(:final error)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.errorMessage(error))));
      return;
    }
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: viewModel.load,
      builder: (context, _) {
        final result = viewModel.load.result;
        final article = result is Ok<Article> ? result.value : null;
        return Scaffold(
          appBar: AppBar(
            actions: [
              if (article != null) ...[
                SummaryButton(url: article.url),
                IconButton(
                  tooltip: l10n.readLaterOriginal,
                  icon: const Icon(Icons.open_in_new),
                  onPressed: () => LinkOpener.of(context).open(article.url),
                ),
                IconButton(
                  tooltip: l10n.readLaterArchive,
                  icon: const Icon(Icons.archive_outlined),
                  onPressed: () async {
                    await viewModel.setStatus.execute(ArticleStatus.archived);
                    if (context.mounted) {
                      await _done(context, viewModel.setStatus);
                    }
                  },
                ),
                IconButton(
                  tooltip: l10n.noteDelete,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    await viewModel.remove.execute();
                    if (context.mounted) await _done(context, viewModel.remove);
                  },
                ),
              ],
            ],
          ),
          body: switch (result) {
            Error(:final error) => Padding(
              padding: const EdgeInsets.all(Dimens.gap),
              child: Text(l10n.errorMessage(error)),
            ),
            null => const Center(child: CircularProgressIndicator()),
            Ok() => ListView(
              padding: const EdgeInsets.all(Dimens.gap),
              children: [
                Text(article!.title, style: theme.textTheme.headlineSmall),
                if (article.site.isNotEmpty)
                  Text(article.site, style: theme.textTheme.bodySmall),
                const SizedBox(height: Dimens.gap),
                if (article.content.isEmpty)
                  Text(l10n.readLaterNoCopy)
                else
                  for (final p in htmlParagraphs(article.content))
                    Padding(
                      padding: const EdgeInsets.only(bottom: Dimens.gapCard),
                      child: Text(p, style: theme.textTheme.bodyLarge),
                    ),
              ],
            ),
          },
        );
      },
    );
  }
}
