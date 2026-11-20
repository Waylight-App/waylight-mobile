import 'dart:async';

import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/ui/core/error_messages.dart';
import 'package:waylight_mobile/ui/core/link_opener.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/widgets/common/error_snack_listener.dart';
import 'package:waylight_mobile/ui/widgets/common/summary_button.dart';
import 'package:waylight_mobile/ui/widgets/rss/rss_reader_view_model.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The feed reader (#106). With summaries on the server, a long press on an
/// article summarises it (#155).
class RssScreen extends StatefulWidget {
  /// Creates the screen for [viewModel].
  const RssScreen({required this.viewModel, super.key});

  /// The state and actions of this screen.
  final RssReaderViewModel viewModel;

  @override
  State<RssScreen> createState() => _RssScreenState();
}

class _RssScreenState extends State<RssScreen> {
  bool _summaries = false;

  @override
  void initState() {
    super.initState();
    summariesAvailable(context).then((on) {
      if (mounted && on) setState(() => _summaries = true);
    }).ignore();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final vm = widget.viewModel;
    return ErrorSnackListener(
      listenable: vm,
      takeError: vm.takeLastError,
      child: ListenableBuilder(
        listenable: Listenable.merge([vm, vm.load]),
        builder: (context, _) {
          final date = DateFormat.MMMd(
            Localizations.localeOf(context).toLanguageTag(),
          ).add_Hm();
          return Scaffold(
            appBar: AppBar(
              title: Text(l10n.rssTitle),
              actions: [
                IconButton(
                  tooltip: l10n.rssAllRead,
                  icon: const Icon(Icons.done_all),
                  onPressed: vm.items.any((i) => !i.read)
                      ? vm.markAllRead
                      : null,
                ),
              ],
            ),
            body: RefreshIndicator(
              onRefresh: vm.refresh,
              child: ListView(
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: Dimens.gap),
                    child: Row(
                      children: [
                        FilterChip(
                          label: Text(l10n.rssUnreadOnly),
                          selected: vm.unreadOnly,
                          onSelected: vm.setUnreadOnly,
                        ),
                        const SizedBox(width: Dimens.gapSmall),
                        ChoiceChip(
                          label: Text('${l10n.rssAllFeeds} (${vm.unread})'),
                          selected: vm.feedId.isEmpty,
                          onSelected: (_) => vm.chooseFeed(''),
                        ),
                        for (final f in vm.feeds) ...[
                          const SizedBox(width: Dimens.gapSmall),
                          ChoiceChip(
                            label: Text('${f.title} (${f.unread})'),
                            selected: vm.feedId == f.id,
                            onSelected: (_) => vm.chooseFeed(f.id),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (vm.load.result case Error(:final error)
                      when vm.items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(Dimens.gap),
                      child: Text(l10n.errorMessage(error)),
                    )
                  else if (vm.items.isEmpty && !vm.load.running)
                    Padding(
                      padding: const EdgeInsets.all(Dimens.gap),
                      child: Text(l10n.rssCaughtUp),
                    ),
                  for (final a in vm.items)
                    ListTile(
                      title: Text(
                        a.title,
                        style: a.read
                            ? TextStyle(
                                color: Theme.of(context).colorScheme.outline,
                              )
                            : null,
                      ),
                      subtitle: Text(
                        [
                          a.feed,
                          if (a.publishedAt case final at?) date.format(at),
                        ].join(' · '),
                      ),
                      trailing: IconButton(
                        tooltip: a.read ? l10n.rssMarkUnread : l10n.rssMarkRead,
                        icon: Icon(
                          a.read ? Icons.mark_email_unread : Icons.done,
                        ),
                        onPressed: () => vm.setRead(a, read: !a.read),
                      ),
                      onTap: a.link == null
                          ? null
                          : () {
                              unawaited(vm.setRead(a, read: true));
                              unawaited(LinkOpener.of(context).open(a.link!));
                            },
                      onLongPress: _summaries && a.link != null
                          ? () => showSummarySheet(context, url: a.link)
                          : null,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
