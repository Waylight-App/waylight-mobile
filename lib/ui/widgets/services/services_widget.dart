import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:waylight_mobile/data/repositories/actions/home_server_actions_repository.dart';
import 'package:waylight_mobile/data/repositories/widget_data/queries/home_server.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/home_server.dart';
import 'package:waylight_mobile/routing/routes.dart';
import 'package:waylight_mobile/ui/core/link_opener.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/widgets/common/admin_actions.dart';
import 'package:waylight_mobile/ui/widgets/common/compact_state_widget.dart';
import 'package:waylight_mobile/ui/widgets/common/remote_widget.dart';
import 'package:waylight_mobile/ui/widgets/common/widget_rows.dart';

/// The tone and spoken label of a service state.
(Tone, String) _stateOf(BuildContext context, ServiceState state) =>
    switch (state) {
      ServiceState.online => (Tone.ok, context.l10n.servicesOnline),
      ServiceState.offline => (Tone.critical, context.l10n.servicesOffline),
      ServiceState.unknown => (Tone.neutral, context.l10n.servicesUnknown),
    };

/// The native view of the services widget (#143): each service with its
/// state and response time; tapping opens it.
class ServicesWidget extends StatelessWidget {
  /// Creates the view for [widget].
  const ServicesWidget({required this.widget, super.key});

  /// The placement of the widget.
  final WidgetPlacement widget;

  /// The builder for the widget registry.
  /// Small and strip tiles show the server's compact state (#274).
  static Widget forPlacement(BuildContext context, WidgetPlacement widget) =>
      CompactStateWidget.orFull(
        context,
        widget,
        title: widget.title.isNotEmpty
            ? widget.title
            : context.l10n.servicesTitle,
        full: () => ServicesWidget(widget: widget, key: ValueKey(widget.id)),
      );

  @override
  Widget build(BuildContext context) => RemoteWidget<List<MonitoredService>>(
    title: widget.title.isNotEmpty ? widget.title : context.l10n.servicesTitle,
    query: servicesQuery,
    interval: const Duration(minutes: 1),
    builder: (context, services) {
      if (services.isEmpty) return Text(context.l10n.servicesEmpty);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final s in services)
            Builder(
              builder: (context) {
                final (tone, label) = _stateOf(context, s.state);
                return InfoRow(
                  leading: s.icon.isEmpty
                      ? StatusDot(tone: tone, label: label)
                      : Text(s.icon, semanticsLabel: ''),
                  title: s.name,
                  subtitle: s.icon.isEmpty ? null : label,
                  trailing: s.latencyMs == null ? null : '${s.latencyMs} ms',
                  trailingTone: s.state == ServiceState.offline
                      ? Tone.critical
                      : null,
                  onTap: () => _actions(context, s),
                );
              },
            ),
        ],
      );
    },
  );
}

Future<void> _actions(BuildContext context, MonitoredService s) async {
  final l10n = context.l10n;
  final url = s.url;
  final admin = s.canWake && await isAdmin(context);
  if (!context.mounted) return;
  await showActions(context, [
    (
      icon: Icons.insights,
      label: l10n.serviceDetails,
      onTap: () => context.push(
        Uri(
          path: Routes.service,
          queryParameters: {'id': s.id, 'name': s.name},
        ).toString(),
      ),
    ),
    if (url != null)
      (
        icon: Icons.open_in_new,
        label: l10n.servicesOpen,
        onTap: () => LinkOpener.of(context).open(url),
      ),
    if (admin)
      (
        icon: Icons.power_settings_new,
        label: l10n.servicesWake,
        onTap: () => runAction(
          context,
          (server) =>
              context.read<HomeServerActionsRepository>().wake(server, s.id),
          done: l10n.servicesWakeSent(s.name),
        ),
      ),
  ]);
}

/// The native view of the status overview (#144): how many services are
/// up, down or unchecked.
class StatusOverviewWidget extends StatelessWidget {
  /// Creates the view for [widget].
  const StatusOverviewWidget({required this.widget, super.key});

  /// The placement of the widget.
  final WidgetPlacement widget;

  /// The builder for the widget registry.
  /// Small and strip tiles show the server's compact state (#274).
  static Widget forPlacement(BuildContext context, WidgetPlacement widget) =>
      CompactStateWidget.orFull(
        context,
        widget,
        title: widget.title.isNotEmpty
            ? widget.title
            : context.l10n.statusOverviewTitle,
        full: () =>
            StatusOverviewWidget(widget: widget, key: ValueKey(widget.id)),
      );

  @override
  Widget build(BuildContext context) => RemoteWidget<List<MonitoredService>>(
    title: widget.title.isNotEmpty
        ? widget.title
        : context.l10n.statusOverviewTitle,
    query: servicesQuery,
    interval: const Duration(minutes: 1),
    compact: (context, services, size) {
      final l10n = context.l10n;
      if (services.isEmpty) return Text(l10n.servicesEmpty);
      final down = services
          .where((s) => s.state == ServiceState.offline)
          .length;
      return Row(
        children: [
          StatusDot(
            tone: down == 0 ? Tone.ok : Tone.critical,
            label: down == 0 ? l10n.servicesOnline : l10n.servicesOffline,
          ),
          const SizedBox(width: Dimens.gapSmall),
          Flexible(
            child: Text(
              down == 0
                  ? l10n.statusAllUp(services.length)
                  : l10n.statusSomeDown(down),
              maxLines: size == WidgetSize.strip ? 1 : 3,
              overflow: TextOverflow.ellipsis,
              style: size == WidgetSize.strip
                  ? null
                  : Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      );
    },
    builder: (context, services) {
      int count(ServiceState s) => services.where((x) => x.state == s).length;
      final down = services
          .where((s) => s.state == ServiceState.offline)
          .toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              for (final state in ServiceState.values)
                Expanded(
                  child: _Count(
                    count: count(state),
                    state: _stateOf(context, state),
                  ),
                ),
            ],
          ),
          if (down.isNotEmpty) ...[
            const SizedBox(height: Dimens.gapSmall),
            for (final s in down)
              InfoRow(
                leading: StatusDot(
                  tone: Tone.critical,
                  label: context.l10n.servicesOffline,
                ),
                title: s.name,
              ),
          ],
        ],
      );
    },
  );
}

class _Count extends StatelessWidget {
  const _Count({required this.count, required this.state});

  final int count;
  final (Tone, String) state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (tone, label) = state;
    return Semantics(
      label: '$count $label',
      excludeSemantics: true,
      child: Column(
        children: [
          Text(
            '$count',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: count == 0 ? null : toneColor(context, tone),
            ),
          ),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
