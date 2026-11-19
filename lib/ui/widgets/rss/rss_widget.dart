import 'dart:async';

import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:waylight_mobile/data/repositories/actions/rss_repository.dart';
import 'package:waylight_mobile/domain/models/actions.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/ui/core/link_opener.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/widgets/common/items_view_model.dart';
import 'package:waylight_mobile/ui/widgets/common/items_widget.dart';

/// The native view of the feed widget (#142): the newest items; opening an
/// item marks it read, and it can be marked by hand.
class RssWidget extends StatelessWidget {
  /// Creates the view for [widget].
  const RssWidget({required this.widget, super.key});

  /// The placement of the widget.
  final WidgetPlacement widget;

  /// The builder for the widget registry.
  static Widget forPlacement(BuildContext context, WidgetPlacement widget) =>
      RssWidget(widget: widget, key: ValueKey(widget.id));

  @override
  Widget build(BuildContext context) {
    final config = widget.config;
    final feedId = config['feedId'] is String
        ? config['feedId']! as String
        : '';
    final unreadOnly = config['unreadOnly'] != false;
    final limit = switch (config['limit']) {
      final num n => n.round().clamp(5, 100),
      _ => 20,
    };
    return ItemsWidget<FeedArticle>(
      title: widget.title.isNotEmpty ? widget.title : context.l10n.rssTitle,
      interval: const Duration(minutes: 15),
      create: (context) {
        final rss = context.read<RssRepository>();
        return ItemsViewModel(
          serverRepository: context.read(),
          fetch: (server) => rss.items(
            server,
            feedId: feedId,
            unreadOnly: unreadOnly,
            limit: limit,
          ),
          id: (a) => a.id,
        );
      },
      builder: (context, vm) {
        final l10n = context.l10n;
        if (vm.items.isEmpty) return Text(l10n.rssCaughtUp);
        final rss = context.read<RssRepository>();
        final date = DateFormat.MMMd(
          Localizations.localeOf(context).toLanguageTag(),
        ).add_Hm();
        void mark(FeedArticle a, bool read) => vm.change(
          a,
          a.withRead(read),
          (server) => rss.setRead(server, a.id, read: read),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final a in vm.items)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(
                  a.title,
                  style: a.read
                      ? TextStyle(color: Theme.of(context).colorScheme.outline)
                      : null,
                ),
                subtitle: Text(
                  [
                    if (feedId.isEmpty) a.feed,
                    if (a.publishedAt case final at?) date.format(at),
                  ].join(' · '),
                ),
                trailing: IconButton(
                  tooltip: a.read ? l10n.rssMarkUnread : l10n.rssMarkRead,
                  icon: Icon(a.read ? Icons.mark_email_unread : Icons.done),
                  onPressed: () => mark(a, !a.read),
                ),
                onTap: a.link == null
                    ? null
                    : () {
                        if (!a.read) mark(a, true);
                        unawaited(LinkOpener.of(context).open(a.link!));
                      },
              ),
          ],
        );
      },
    );
  }
}
