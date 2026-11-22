import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/data/repositories/widget_data/queries/home_server.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/grafana.dart';
import 'package:waylight_mobile/ui/core/link_opener.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/widget_size_scope.dart';
import 'package:waylight_mobile/ui/core/widgets/section_card.dart';
import 'package:waylight_mobile/ui/core/widgets/tile_rows.dart';
import 'package:waylight_mobile/ui/widgets/common/server_image.dart';
import 'package:waylight_mobile/ui/widgets/common/simple_widget.dart';
import 'package:waylight_mobile/ui/widgets/common/widget_rows.dart';

/// Firing and pending alerts of Grafana (#165).
class GrafanaAlertsWidget extends StatelessWidget {
  /// Creates the widget for [placement].
  const GrafanaAlertsWidget({required this.placement, super.key});

  /// Builds the widget for the registry.
  static Widget forPlacement(BuildContext context, WidgetPlacement placement) =>
      GrafanaAlertsWidget(placement: placement);

  /// The placement on the dashboard.
  final WidgetPlacement placement;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SimpleWidget<GrafanaAlerts>(
      placement: placement,
      defaultTitle: l10n.grafanaAlertsTitle,
      query: grafanaAlertsQuery,
      interval: const Duration(minutes: 1),
      builder: (context, data) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (data.alerts.isEmpty) Text(l10n.grafanaAllQuiet),
          TileRows(
            items: data.alerts,
            rowHeight: TileRows.twoLineRowHeight,
            rowBuilder: (context, a) => InfoRow(
              leading: StatusDot(
                tone: a.firing ? Tone.critical : Tone.warning,
                label: a.firing ? l10n.grafanaFiring : l10n.grafanaPending,
              ),
              title: a.name,
              subtitle: [
                if (!a.firing) l10n.grafanaPending,
                if (a.summary.isNotEmpty) a.summary,
                if (a.since case final since?) shortDate(context, since),
              ].join(' · '),
            ),
          ),
          if (data.url case final url? when !WidgetSizeScope.inGrid(context))
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => openLink(context, url, l10n.linkOpenFailed),
                child: Text(l10n.grafanaAlertList),
              ),
            ),
        ],
      ),
    );
  }
}

/// One Grafana panel as an image rendered by Grafana (#165), refreshed on
/// the widget's interval and in the app's light or dark look.
class GrafanaPanelWidget extends StatefulWidget {
  /// Creates the widget for [placement].
  const GrafanaPanelWidget({required this.placement, super.key});

  /// Builds the widget for the registry.
  static Widget forPlacement(BuildContext context, WidgetPlacement placement) =>
      GrafanaPanelWidget(placement: placement);

  /// The placement on the dashboard.
  final WidgetPlacement placement;

  @override
  State<GrafanaPanelWidget> createState() => _GrafanaPanelWidgetState();
}

class _GrafanaPanelWidgetState extends State<GrafanaPanelWidget> {
  Timer? _timer;
  int _stamp = DateTime.now().millisecondsSinceEpoch;

  Map<String, Object?> get _config => widget.placement.config;

  String _str(String key) => switch (_config[key]) {
    final String s => s,
    _ => '',
  };

  int get _panelId => switch (_config['panelId']) {
    final num n when n > 0 => n.toInt(),
    _ => 0,
  };

  String get _range {
    final r = _str('range');
    return RegExp(r'^[1-9][0-9]{0,2}[mhdw]$').hasMatch(r) ? r : '6h';
  }

  int get _refreshMinutes => switch (_config['refreshMinutes']) {
    final num n => n.toInt().clamp(1, 60),
    _ => 5,
  };

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(minutes: _refreshMinutes), (_) {
      if (mounted) {
        setState(() => _stamp = DateTime.now().millisecondsSinceEpoch);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// The panel in Grafana, opened on a tap; `null` without its address.
  Uri? get _link {
    final dashboard = Uri.tryParse(_str('dashboardUrl'));
    if (dashboard == null ||
        !(dashboard.scheme == 'http' || dashboard.scheme == 'https')) {
      return null;
    }
    return dashboard.replace(
      queryParameters: {
        ...dashboard.queryParameters,
        'viewPanel': '$_panelId',
        'from': 'now-$_range',
        'to': 'now',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final uid = _str('dashboardUid');
    final title = widget.placement.title.isNotEmpty
        ? widget.placement.title
        : (_str('panelTitle').isNotEmpty
              ? _str('panelTitle')
              : l10n.grafanaPanelTitle);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final link = _link;
    return SectionCard(
      title: title,
      child: uid.isEmpty || _panelId == 0
          ? Text(l10n.grafanaChoosePanel)
          : LayoutBuilder(
              builder: (context, box) {
                // Rounded, so the image is not rendered again for every pixel.
                final width = ((box.maxWidth / 50).round() * 50).clamp(
                  200,
                  1600,
                );
                const height = 300;
                return InkWell(
                  onTap: link == null
                      ? null
                      : () => openLink(context, link, l10n.linkOpenFailed),
                  child: AspectRatio(
                    aspectRatio: width / height,
                    child: ServerImage(
                      path:
                          '/api/grafana/render/${Uri.encodeComponent(uid)}/$_panelId',
                      query: {
                        'width': '$width',
                        'height': '$height',
                        'range': _range,
                        'theme': dark ? 'dark' : 'light',
                        't': '$_stamp',
                      },
                      semanticLabel: l10n.grafanaPanelAlt(title),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
