import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/ui/core/error_messages.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/refresh.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/core/widget_size_scope.dart';
import 'package:waylight_mobile/ui/core/widgets/compact_card.dart';
import 'package:waylight_mobile/ui/core/widgets/section_card.dart';
import 'package:waylight_mobile/utils/command.dart';
import 'package:waylight_mobile/utils/result.dart';

/// Data counts as outdated after this many refresh intervals without
/// success, as in the web interface (`web/src/shared/freshness`).
const staleFactor = 2;

/// The card around a dashboard widget that loads data (#61, #19).
///
/// It shows a progress indicator until the first data, then the content
/// from [builder]. It reloads every [interval] while the app is in the
/// foreground, on pull to refresh and when the app returns. A failed reload
/// keeps the last data and says so in the title row, like outdated data;
/// errors stay inside the card, so one widget never breaks the tab.
class WidgetFrame<T> extends StatefulWidget {
  /// Creates the frame.
  const WidgetFrame({
    required this.title,
    required this.load,
    required this.builder,
    this.errorText,
    this.compact,
    this.interval = const Duration(minutes: 5),
    super.key,
  });

  /// The title of the widget.
  final String title;

  /// Loads the widget's data.
  final Command0<T> load;

  /// Builds the content once data is there.
  final Widget Function(BuildContext context, T data) builder;

  /// The message for errors the widget explains itself, e.g. a missing
  /// setting; `null` falls back to the common error texts.
  final String? Function(Exception error)? errorText;

  /// Builds the compact form for a small or strip tile of the dashboard
  /// grid (#211); without it such tiles say that a tap shows everything.
  final Widget Function(BuildContext context, T data, WidgetSize size)? compact;

  /// How often the data is reloaded while shown.
  final Duration interval;

  @override
  State<WidgetFrame<T>> createState() => _WidgetFrameState<T>();
}

class _WidgetFrameState<T> extends State<WidgetFrame<T>> {
  RefreshController? _refresh;
  Timer? _timer;
  T? _data;
  bool _hasData = false;
  DateTime? _fetchedAt;

  @override
  void initState() {
    super.initState();
    widget.load.addListener(_onLoad);
    _onLoad();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final refresh = RefreshHost.maybeOf(context);
    if (refresh == _refresh) return;
    _refresh?.remove(_reload);
    _refresh = refresh?..add(_reload);
    _timer?.cancel();
    _timer = Timer.periodic(widget.interval, (_) {
      if (_refresh?.active ?? true) _reload().ignore();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _refresh?.remove(_reload);
    widget.load.removeListener(_onLoad);
    super.dispose();
  }

  DateTime _now() => _refresh?.now() ?? DateTime.now();

  Future<void> _reload() async {
    if (!widget.load.running) await widget.load.execute();
  }

  void _onLoad() {
    if (widget.load.result case Ok(:final value)) {
      _data = value;
      _hasData = true;
      _fetchedAt = _now();
    }
    if (mounted) setState(() {});
  }

  /// The status in the title row: empty while fresh.
  String? _status(AppLocalizations l10n) {
    final fetchedAt = _fetchedAt;
    if (!_hasData || fetchedAt == null) return null;
    final minutes = _now().difference(fetchedAt).inMinutes;
    final age = minutes < 1
        ? l10n.freshnessJustNow
        : l10n.freshnessMinutesAgo(minutes);
    if (widget.load.result is Error<T>) return l10n.freshnessFailed(age);
    final stale = _now().difference(fetchedAt) > widget.interval * staleFactor;
    return stale ? l10n.freshnessStale(age) : null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final result = widget.load.result;
    final size = WidgetSizeScope.maybeOf(context);
    if (size != null && isCompact(size)) {
      return CompactCard(
        title: widget.title,
        size: size,
        status: _status(l10n),
        child: switch (result) {
          _ when _hasData =>
            widget.compact?.call(context, _data as T, size) ??
                const TapToOpenHint(),
          Error(:final error) => Text(
            widget.errorText?.call(error) ?? l10n.errorMessage(error),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          _ => const SizedBox.square(
            dimension: Dimens.inlineProgress,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        },
      );
    }
    return SectionCard(
      title: widget.title,
      trailing: _status(l10n),
      child: switch (result) {
        // A failed reload keeps showing the last data.
        _ when _hasData => widget.builder(context, _data as T),
        Error(:final error) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.errorText?.call(error) ?? l10n.errorMessage(error)),
            TextButton(
              onPressed: widget.load.running ? null : () => _reload().ignore(),
              child: Text(l10n.dashboardRetry),
            ),
          ],
        ),
        _ => const Center(
          child: Padding(
            padding: EdgeInsets.all(Dimens.gapSmall),
            child: SizedBox.square(
              dimension: Dimens.inlineProgress,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      },
    );
  }
}
