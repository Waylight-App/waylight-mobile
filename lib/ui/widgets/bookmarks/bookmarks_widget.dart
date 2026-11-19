import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:waylight_mobile/domain/models/bookmark.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/ui/core/link_opener.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/core/widgets/view_model_host.dart';
import 'package:waylight_mobile/ui/core/widgets/widget_frame.dart';
import 'package:waylight_mobile/ui/widgets/bookmarks/bookmarks_view_model.dart';

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
        builder: (context, groups) => groups.isEmpty
            ? Text(l10n.bookmarksEmpty)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final group in groups) ...[
                    if (group.name.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: Dimens.gapSmall),
                        child: Text(
                          group.name,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                    for (final link in group.links) _LinkTile(link: link),
                  ],
                ],
              ),
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({required this.link});

  final Bookmark link;

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
    );
  }
}
