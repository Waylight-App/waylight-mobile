import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:waylight_mobile/domain/models/bookmark.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/ui/core/error_messages.dart';
import 'package:waylight_mobile/ui/core/link_opener.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/core/widgets/view_model_host.dart';
import 'package:waylight_mobile/ui/core/widgets/widget_frame.dart';
import 'package:waylight_mobile/ui/widgets/bookmarks/bookmark_dialog.dart';
import 'package:waylight_mobile/ui/widgets/bookmarks/bookmarks_view_model.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The native view of the bookmarks widget (#66); links open in the
/// browser.
class BookmarksWidget extends StatelessWidget {
  /// Creates the view for [widget].
  const BookmarksWidget({required this.widget, super.key});

  /// The placement with the widget's configuration.
  final WidgetPlacement widget;

  /// The builder for the widget registry.
  static Widget forPlacement(BuildContext context, WidgetPlacement widget) =>
      BookmarksWidget(widget: widget, key: ValueKey(widget.id));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ViewModelHost(
      create: (context) => BookmarksViewModel(
        config: BookmarksConfig.fromJson(widget.config),
        serverRepository: context.read(),
        bookmarksRepository: context.read(),
      ),
      builder: (context, viewModel) => WidgetFrame(
        title: widget.title.isNotEmpty ? widget.title : l10n.bookmarksTitle,
        load: viewModel.load,
        interval: const Duration(minutes: 30),
        builder: (context, groups) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (groups.isEmpty) Text(l10n.bookmarksEmpty),
            for (final group in groups) ...[
              if (group.name.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: Dimens.gapSmall),
                  child: Text(
                    group.name,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              for (final link in group.links)
                _LinkTile(
                  link: link,
                  onEdit: () => _edit(context, viewModel, link),
                ),
            ],
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.add),
                label: Text(l10n.bookmarkAdd),
                onPressed: () => _edit(context, viewModel, null),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Adds a bookmark, or edits or deletes [link] (#102).
Future<void> _edit(
  BuildContext context,
  BookmarksViewModel viewModel,
  Bookmark? link,
) async {
  final l10n = context.l10n;
  if (link != null) {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(l10n.bookmarkEdit),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(l10n.noteDelete),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted || choice == null) return;
    if (choice == 'delete') {
      final result = await viewModel.delete(link);
      if (context.mounted) _report(context, result);
      return;
    }
  }
  if (!context.mounted) return;
  final draft = await showDialog<BookmarkDraft>(
    context: context,
    builder: (_) => BookmarkDialog(folders: viewModel.folders, bookmark: link),
  );
  if (draft == null || !context.mounted) return;
  final result = await viewModel.save(draft, id: link?.id ?? '');
  if (context.mounted) _report(context, result);
}

void _report(BuildContext context, Result<void> result) {
  if (result case Error(:final error)) {
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(SnackBar(content: Text(context.l10n.errorMessage(error))));
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({required this.link, required this.onEdit});

  final Bookmark link;

  /// Opens the edit choices; on a long press, so a tap still opens the link.
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      minTileHeight: Dimens.tapTarget,
      leading: const Icon(Icons.link, size: Dimens.iconSmall),
      title: Text(link.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        link.url.host,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      onTap: () => openLink(context, link.url, context.l10n.linkOpenFailed),
      onLongPress: onEdit,
    );
  }
}
