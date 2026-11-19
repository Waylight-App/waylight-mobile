import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/domain/models/search.dart';
import 'package:waylight_mobile/routing/routes.dart';
import 'package:waylight_mobile/ui/core/error_messages.dart';
import 'package:waylight_mobile/ui/core/link_opener.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/search/view_models/search_view_model.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The search of the app (#22).
class SearchScreen extends StatelessWidget {
  /// Creates the screen for [viewModel].
  const SearchScreen({required this.viewModel, super.key});

  /// The state and actions of this screen.
  final SearchViewModel viewModel;

  Future<void> _run(BuildContext context, SearchResult result) async {
    final l10n = context.l10n;
    switch (result) {
      case OpenAddress(:final uri):
        await openLink(context, uri, l10n.linkOpenFailed);
      case OpenWidget(:final tab):
        context.go(
          Uri(path: Routes.home, queryParameters: {'tab': tab.id}).toString(),
        );
      case CaptureTodo(:final title):
        final messenger = ScaffoldMessenger.of(context);
        await viewModel.capture.execute(title);
        messenger.showSnackBar(
          SnackBar(
            content: Text(switch (viewModel.capture.result) {
              Error(:final error) => l10n.errorMessage(error),
              _ => l10n.searchTodoAdded(title),
            }),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          key: const ValueKey('search.field'),
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: viewModel.onQueryChanged,
          onSubmitted: (_) =>
              openLink(context, viewModel.webSearchUri, l10n.linkOpenFailed),
          decoration: InputDecoration(
            hintText: l10n.searchHint,
            border: InputBorder.none,
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) {
          if (viewModel.query.trim().isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(Dimens.gap),
              child: Text(l10n.searchIntro),
            );
          }
          return ListView(
            children: [
              for (final result in viewModel.results)
                ListTile(
                  minTileHeight: Dimens.tapTarget,
                  leading: Icon(switch (result) {
                    OpenAddress() => Icons.open_in_new,
                    OpenWidget() => Icons.dashboard_outlined,
                    CaptureTodo() => Icons.add_task,
                  }),
                  title: Text(switch (result) {
                    OpenAddress(:final label) => label,
                    OpenWidget(:final widget) => widget.displayTitle,
                    CaptureTodo(:final title) => l10n.searchAddTodo(title),
                  }),
                  subtitle: switch (result) {
                    OpenWidget(:final tab) => Text(l10n.searchOnTab(tab.name)),
                    _ => null,
                  },
                  onTap: () => _run(context, result),
                ),
              ListTile(
                key: const ValueKey('search.web'),
                minTileHeight: Dimens.tapTarget,
                leading: const Icon(Icons.travel_explore),
                title: Text(l10n.searchWeb(viewModel.query.trim())),
                onTap: () => openLink(
                  context,
                  viewModel.webSearchUri,
                  l10n.linkOpenFailed,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
