import 'dart:async';

import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:waylight_mobile/data/repositories/actions/drop_repository.dart';
import 'package:waylight_mobile/data/repositories/focus/focus_timer_repository.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/data/repositories/widget_data/queries/media.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/focus_timer.dart';
import 'package:waylight_mobile/domain/models/media.dart';
import 'package:waylight_mobile/ui/core/link_opener.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/core/themes/radar_colors.dart';
import 'package:waylight_mobile/ui/core/widgets/section_card.dart';
import 'package:waylight_mobile/ui/widgets/common/compact_state_widget.dart';
import 'package:waylight_mobile/ui/widgets/common/items_view_model.dart';
import 'package:waylight_mobile/ui/widgets/common/items_widget.dart';
import 'package:waylight_mobile/ui/widgets/common/server_image.dart';
import 'package:waylight_mobile/ui/widgets/common/simple_widget.dart';
import 'package:waylight_mobile/ui/widgets/common/widget_rows.dart';
import 'package:waylight_mobile/ui/widgets/lists/list_widgets.dart';

/// The photo frame (#137): the album's photos one after another.
class PhotoFrameWidget extends StatelessWidget {
  /// Creates the view for [widget].
  const PhotoFrameWidget({required this.widget, super.key});

  /// The placement of the widget.
  final WidgetPlacement widget;

  /// The builder for the widget registry.
  static Widget forPlacement(BuildContext context, WidgetPlacement widget) =>
      PhotoFrameWidget(widget: widget, key: ValueKey(widget.id));

  @override
  Widget build(BuildContext context) {
    final album = switch (widget.config['album']) {
      final String a when a.trim().isNotEmpty => a.trim(),
      _ => 'Photos',
    };
    final seconds = switch (widget.config['interval']) {
      final int i when i >= 5 && i <= 3600 => i,
      _ => 30,
    };
    final cover = widget.config['fit'] == 'cover';
    return SimpleWidget<List<String>>(
      placement: widget,
      defaultTitle: context.l10n.photoFrameTitle,
      query: photosQuery.withQuery({'album': album}),
      interval: const Duration(minutes: 30),
      builder: (context, ids) => ids.isEmpty
          ? Text(context.l10n.photoFrameEmpty)
          : _Slideshow(
              ids: ids,
              every: Duration(seconds: seconds),
              fit: cover ? BoxFit.cover : BoxFit.contain,
            ),
    );
  }
}

class _Slideshow extends StatefulWidget {
  const _Slideshow({required this.ids, required this.every, required this.fit});

  final List<String> ids;
  final Duration every;
  final BoxFit fit;

  @override
  State<_Slideshow> createState() => _SlideshowState();
}

class _SlideshowState extends State<_Slideshow> {
  late final Timer _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.every, (_) => setState(() => _index++));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 3 / 2,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(Dimens.radiusBanner),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        child: ServerImage(
          key: ValueKey(_index % widget.ids.length),
          path: photoPath(widget.ids[_index % widget.ids.length]),
          fit: widget.fit,
          semanticLabel: context.l10n.photoFrameTitle,
        ),
      ),
    ),
  );
}

/// The rain radar (#139) for the place of the widget's settings, reloaded
/// every ten minutes.
class RadarWidget extends StatefulWidget {
  /// Creates the view for [widget].
  const RadarWidget({required this.widget, super.key});

  /// The placement of the widget.
  final WidgetPlacement widget;

  /// The builder for the widget registry.
  static Widget forPlacement(BuildContext context, WidgetPlacement widget) =>
      RadarWidget(widget: widget, key: ValueKey(widget.id));

  @override
  State<RadarWidget> createState() => _RadarWidgetState();
}

class _RadarWidgetState extends State<RadarWidget> {
  late final Timer _timer;
  int _round = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(minutes: 10),
      (_) => setState(() => _round++),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.widget.config;
    final (lat, lon) = (config['lat'], config['lon']);
    final label = switch (config['label']) {
      final String l when l.isNotEmpty => l,
      _ => context.l10n.radarTitle,
    };
    return SectionCard(
      title: widget.widget.title.isNotEmpty ? widget.widget.title : label,
      child: lat is num && lon is num
          // The radar is made for a dark map, as in the web widget: on the
          // light card its yellow borders and light rain disappear (#176).
          ? ClipRRect(
              borderRadius: BorderRadius.circular(Dimens.radiusSmall),
              child: ColoredBox(
                color: RadarColors.background,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ServerImage(
                            // A new key per round reloads the radar.
                            key: ValueKey(_round),
                            path: '/api/weather/radar',
                            query: {
                              'lat': '$lat',
                              'lon': '$lon',
                              'k': '$_round',
                            },
                            fit: BoxFit.cover,
                            semanticLabel: context.l10n.radarTitle,
                          ),
                          // The place of the widget, in the middle.
                          const Center(child: _RadarMarker()),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Dimens.gapSmall,
                        vertical: Dimens.gapTiny,
                      ),
                      child: Text(
                        '${config['label'] is String && (config['label']! as String).isNotEmpty ? '$label · ' : ''}© Deutscher Wetterdienst',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: RadarColors.caption),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Text(context.l10n.radarNoPlace),
    );
  }
}

/// The red dot with a white ring that marks the widget's place.
class _RadarMarker extends StatelessWidget {
  const _RadarMarker();

  @override
  Widget build(BuildContext context) => Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(
      color: RadarColors.marker,
      shape: BoxShape.circle,
      border: Border.all(color: RadarColors.markerRing, width: 2),
    ),
  );
}

/// The space widget (#147): the next launches and, below, the astronomy
/// picture of the day.
class SpaceWidget extends StatelessWidget {
  /// Creates the view for [widget].
  const SpaceWidget({required this.widget, super.key});

  /// The placement of the widget.
  final WidgetPlacement widget;

  /// The builder for the widget registry.
  static Widget forPlacement(BuildContext context, WidgetPlacement widget) =>
      SpaceWidget(widget: widget, key: ValueKey(widget.id));

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ListWidget.space(context, widget),
      const SizedBox(height: Dimens.gapCard),
      const ApodView(),
    ],
  );
}

/// The astronomy picture of the day, shown below the launches of the space
/// widget (#147).
class ApodView extends StatelessWidget {
  /// Creates the view.
  const ApodView({super.key});

  @override
  Widget build(BuildContext context) => SimpleWidget<Apod>(
    placement: const WidgetPlacement(id: 'apod', kind: 'space'),
    defaultTitle: context.l10n.apodTitle,
    query: apodQuery,
    interval: const Duration(hours: 6),
    builder: (context, apod) {
      final image = Uri.tryParse(apod.imagePath);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (image != null && apod.imagePath.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(Dimens.radiusBanner),
              child: ServerImage(
                path: image.path,
                query: image.queryParameters,
                fit: BoxFit.cover,
                semanticLabel: apod.title,
              ),
            ),
          InfoRow(
            title: apod.title,
            onTap: apod.link == null
                ? null
                : () => LinkOpener.of(context).open(apod.link!),
          ),
        ],
      );
    },
  );
}

/// The JSON widget (#112): the values the owner picked from an own API.
class ApiValuesWidget extends StatelessWidget {
  /// Creates the view for [widget].
  const ApiValuesWidget({required this.widget, super.key});

  /// The placement of the widget.
  final WidgetPlacement widget;

  /// The builder for the widget registry.
  static Widget forPlacement(BuildContext context, WidgetPlacement widget) =>
      ApiValuesWidget(widget: widget, key: ValueKey(widget.id));

  @override
  Widget build(BuildContext context) {
    final id = widget.config['endpointId'];
    if (id is! String || id.isEmpty) {
      return SectionCard(
        title: widget.displayTitle,
        child: Text(context.l10n.apiWidgetNoEndpoint),
      );
    }
    return SimpleWidget<ApiValues>(
      placement: widget,
      defaultTitle: widget.displayTitle,
      query: apiValuesQuery(id),
      interval: const Duration(minutes: 1),
      builder: (context, values) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.title.isEmpty)
            Text(values.name, style: Theme.of(context).textTheme.labelLarge),
          for (final v in values.values)
            InfoRow(
              title: v.label,
              trailing: v.unit.isEmpty ? v.text : '${v.text} ${v.unit}',
              trailingTone: switch (v.status) {
                'warning' => Tone.warning,
                'critical' || 'error' => Tone.critical,
                _ => null,
              },
            ),
        ],
      ),
    );
  }
}

/// The mail widget (#131): unread count and the newest unread messages;
/// tapping opens the web mail.
class MailWidget extends StatelessWidget {
  /// Creates the view for [widget].
  const MailWidget({required this.widget, super.key});

  /// The placement of the widget.
  final WidgetPlacement widget;

  /// The builder for the widget registry.
  static Widget forPlacement(BuildContext context, WidgetPlacement widget) =>
      MailWidget(widget: widget, key: ValueKey(widget.id));

  @override
  Widget build(BuildContext context) {
    final account = widget.config['account'];
    return SimpleWidget<Inbox>(
      placement: widget,
      defaultTitle: context.l10n.mailTitle,
      query: account is String && account.isNotEmpty
          ? inboxQuery.withQuery({'account': account})
          : inboxQuery,
      builder: (context, inbox) {
        final l10n = context.l10n;
        final time = DateFormat.MMMd(
          Localizations.localeOf(context).toLanguageTag(),
        ).add_Hm();
        final open = inbox.webmail == null
            ? null
            : () => LinkOpener.of(context).open(inbox.webmail!);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.mailUnread(inbox.unread),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            for (final m in inbox.messages)
              InfoRow(
                title: m.subject,
                subtitle: [
                  m.from,
                  if (m.date case final d?) time.format(d),
                ].join(' · '),
                onTap: open,
              ),
          ],
        );
      },
    );
  }
}

/// The drop zone (#121, #105): the latest texts and files; texts can be
/// selected and copied, new texts sent, items deleted.
class DropWidget extends StatelessWidget {
  /// Creates the view for [widget].
  const DropWidget({required this.widget, super.key});

  /// The placement of the widget.
  final WidgetPlacement widget;

  /// The builder for the widget registry.
  static Widget forPlacement(BuildContext context, WidgetPlacement widget) =>
      DropWidget(widget: widget, key: ValueKey(widget.id));

  @override
  Widget build(BuildContext context) => ItemsWidget<Drop>(
    title: widget.title.isNotEmpty ? widget.title : context.l10n.dropTitle,
    interval: const Duration(minutes: 1),
    create: (context) {
      final repo = context.read<DropRepository>();
      return ItemsViewModel(
        serverRepository: context.read(),
        fetch: repo.drops,
        id: (d) => d.id,
      );
    },
    builder: (context, vm) {
      final l10n = context.l10n;
      final repo = context.read<DropRepository>();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (vm.items.isEmpty) Text(l10n.dropEmpty),
          for (final d in vm.items)
            Row(
              children: [
                Expanded(
                  child: d.isFile
                      ? InfoRow(
                          leading: const Text('📄', semanticsLabel: ''),
                          title: d.fileName,
                          trailing: formatBytes(d.size),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: Dimens.gapTiny,
                          ),
                          child: SelectableText(d.text),
                        ),
                ),
                if (vm.canEdit)
                  IconButton(
                    tooltip: l10n.noteDelete,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () =>
                        vm.remove(d, (server) => repo.remove(server, d.id)),
                  ),
              ],
            ),
          if (vm.canEdit)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.send),
                label: Text(l10n.dropSend),
                onPressed: () async {
                  final text = await showDialog<String>(
                    context: context,
                    builder: (context) => const _DropTextDialog(),
                  );
                  if (text == null) return;
                  await vm.add((server) => repo.sendText(server, text));
                },
              ),
            ),
        ],
      );
    },
  );
}

/// Asks for a text to drop; returns it, or `null` when cancelled or empty.
class _DropTextDialog extends StatefulWidget {
  const _DropTextDialog();

  @override
  State<_DropTextDialog> createState() => _DropTextDialogState();
}

class _DropTextDialogState extends State<_DropTextDialog> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.dropSend),
      content: TextField(
        controller: _text,
        autofocus: true,
        minLines: 2,
        maxLines: 6,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.parcelsCancel),
        ),
        FilledButton(
          onPressed: () {
            final text = _text.text.trim();
            Navigator.pop(context, text.isEmpty ? null : text);
          },
          child: Text(l10n.dropSend),
        ),
      ],
    );
  }
}

/// The focus timer (#123): today's focus time and a timer whose finished
/// sessions are saved to the server.
class FocusWidget extends StatelessWidget {
  /// Creates the view for [widget].
  const FocusWidget({required this.widget, super.key});

  /// The placement of the widget.
  final WidgetPlacement widget;

  /// The builder for the widget registry.
  /// Small and strip tiles show the server's compact state (#228).
  static Widget forPlacement(BuildContext context, WidgetPlacement widget) =>
      CompactStateWidget.orFull(
        context,
        widget,
        title: widget.title.isNotEmpty ? widget.title : context.l10n.focusTitle,
        full: () => FocusWidget(widget: widget, key: ValueKey(widget.id)),
      );

  @override
  Widget build(BuildContext context) => SimpleWidget<List<FocusDay>>(
    placement: widget,
    defaultTitle: context.l10n.focusTitle,
    query: focusQuery,
    interval: const Duration(minutes: 15),
    builder: (context, days) {
      final today = days.isEmpty ? null : days.last;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.focusToday(today?.minutes ?? 0, today?.sessions ?? 0),
          ),
          const SizedBox(height: Dimens.gapSmall),
          const FocusTimer(),
        ],
      );
    },
  );
}

/// The focus timer (#191): 25 minutes of focus, then a 5-minute break. It
/// shows the state of [FocusTimerRepository], which keeps running when the
/// screen changes or the app is closed.
class FocusTimer extends StatefulWidget {
  /// Creates the timer.
  const FocusTimer({this.now = DateTime.now, super.key});

  /// The clock for the countdown shown; tests pass their own.
  final DateTime Function() now;

  @override
  State<FocusTimer> createState() => _FocusTimerState();
}

class _FocusTimerState extends State<FocusTimer> {
  Timer? _tick;
  late final AppLifecycleListener _lifecycle;

  FocusTimerRepository get _repo => context.read<FocusTimerRepository>();

  Future<void> _refresh() =>
      _repo.refresh(context.read<ServerRepository>().current);

  @override
  void initState() {
    super.initState();
    // The phone may have ended or paused the phase meanwhile.
    _lifecycle = AppLifecycleListener(onResume: () => _refresh().ignore());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refresh().ignore();
    });
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      final s = _repo.state;
      if (s == null || s.paused) return;
      if (s.left(widget.now()) == Duration.zero) {
        _refresh().ignore();
      } else {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final s = context.watch<FocusTimerRepository>().state;
    final left = s?.left(widget.now()) ?? FocusTimerRepository.focusLength;
    final text =
        '${left.inMinutes.toString().padLeft(2, '0')}:${(left.inSeconds % 60).toString().padLeft(2, '0')}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (s != null)
          Text(
            s.phase == FocusPhase.rest ? l10n.focusBreak : l10n.focusRunning,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            if (s == null) ...[
              TextButton(
                onPressed: () => _repo.start(FocusPhase.rest).ignore(),
                child: Text(l10n.focusStartBreak),
              ),
              FilledButton(
                onPressed: () => _repo.start(FocusPhase.focus).ignore(),
                child: Text(l10n.focusStart),
              ),
            ] else ...[
              if (s.paused)
                TextButton(
                  onPressed: () => _repo.resume().ignore(),
                  child: Text(l10n.focusResume),
                )
              else
                TextButton(
                  onPressed: () => _repo.pause().ignore(),
                  child: Text(l10n.focusPause),
                ),
              TextButton(
                onPressed: () => _repo.stop().ignore(),
                child: Text(l10n.focusStop),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
