import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:waylight_mobile/data/repositories/actions/read_later_repository.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/media.dart';
import 'package:waylight_mobile/routing/routes.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/widgets/common/items_view_model.dart';
import 'package:waylight_mobile/ui/widgets/common/items_widget.dart';
import 'package:waylight_mobile/ui/widgets/common/widget_rows.dart';

/// The read later widget (#140): unread articles first; an article opens in
/// the reader (#104), and a link can be saved.
class ReadLaterWidget extends StatelessWidget {
  /// Creates the view for [widget].
  const ReadLaterWidget({required this.widget, super.key});

  /// The placement of the widget.
  final WidgetPlacement widget;

  /// How many articles the card shows.
  static const shown = 6;

  /// The builder for the widget registry.
  static Widget forPlacement(BuildContext context, WidgetPlacement widget) =>
      ReadLaterWidget(widget: widget, key: ValueKey(widget.id));

  @override
  Widget build(BuildContext context) => ItemsWidget<Article>(
    title: widget.title.isNotEmpty ? widget.title : context.l10n.readLaterTitle,
    interval: const Duration(minutes: 15),
    create: (context) {
      final repo = context.read<ReadLaterRepository>();
      return ItemsViewModel(
        serverRepository: context.read(),
        fetch: repo.articles,
        id: (a) => a.id,
      );
    },
    builder: (context, vm) {
      final l10n = context.l10n;
      final articles = [
        ...vm.items.where((a) => a.status == ArticleStatus.unread),
        ...vm.items.where((a) => a.status == ArticleStatus.read),
      ];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (articles.isEmpty) Text(l10n.listEmpty),
          for (final a in articles.take(shown))
            InfoRow(
              leading: a.status == ArticleStatus.unread
                  ? StatusDot(tone: Tone.neutral, label: l10n.readLaterUnread)
                  : null,
              title: a.title,
              subtitle: [
                if (a.site.isNotEmpty) a.site,
                if (a.readingMinutes > 0) '${a.readingMinutes} min',
              ].join(' · '),
              onTap: () async {
                await context.push(
                  Uri(
                    path: Routes.article,
                    queryParameters: {'id': a.id},
                  ).toString(),
                );
                await vm.load.execute();
              },
            ),
          if (vm.canEdit)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.add_link),
                label: Text(l10n.readLaterSave),
                onPressed: () => _save(context, vm),
              ),
            ),
        ],
      );
    },
  );

  static Future<void> _save(
    BuildContext context,
    ItemsViewModel<Article> vm,
  ) async {
    final repo = context.read<ReadLaterRepository>();
    final url = await showDialog<Uri>(
      context: context,
      builder: (context) => const _LinkDialog(),
    );
    if (url == null) return;
    await vm.add((server) => repo.save(server, url));
  }
}

/// Asks for a web address; returns it, or `null` when cancelled or invalid.
class _LinkDialog extends StatefulWidget {
  const _LinkDialog();

  @override
  State<_LinkDialog> createState() => _LinkDialogState();
}

class _LinkDialogState extends State<_LinkDialog> {
  final _url = TextEditingController();

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  void _submit() {
    final uri = Uri.tryParse(_url.text.trim());
    final ok =
        uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty;
    Navigator.pop(context, ok ? uri : null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.readLaterSave),
      content: TextField(
        controller: _url,
        autofocus: true,
        keyboardType: TextInputType.url,
        decoration: const InputDecoration(hintText: 'https://'),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.parcelsCancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.readLaterSave)),
      ],
    );
  }
}
