import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:waylight_mobile/data/repositories/actions/home_server_actions_repository.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/data/repositories/widget_data/queries/home_server.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/home_server.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/ui/core/error_messages.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/widgets/common/admin_actions.dart';
import 'package:waylight_mobile/ui/widgets/common/compact_state_widget.dart';
import 'package:waylight_mobile/ui/widgets/common/simple_widget.dart';
import 'package:waylight_mobile/ui/widgets/common/widget_rows.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The native view of the Docker widget (#120): counts and the containers,
/// stopped and unhealthy ones first; admins restart allowed containers and
/// read their logs (#108).
class DockerWidget extends StatelessWidget {
  /// Creates the view for [widget].
  const DockerWidget({required this.widget, super.key});

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
            : context.l10n.dockerTitle,
        full: () => DockerWidget(widget: widget, key: ValueKey(widget.id)),
      );

  @override
  Widget build(BuildContext context) => SimpleWidget<DockerOverview>(
    placement: widget,
    defaultTitle: context.l10n.dockerTitle,
    query: dockerQuery,
    interval: const Duration(minutes: 1),
    builder: (context, docker) {
      final l10n = context.l10n;
      Tone tone(DockerContainer c) => c.health == 'unhealthy'
          ? Tone.critical
          : c.state == 'running'
          ? Tone.ok
          : Tone.warning;
      final sorted = [...docker.containers]
        ..sort((a, b) => tone(b).index.compareTo(tone(a).index));
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.dockerSummary(
              docker.running,
              docker.stopped,
              docker.unhealthy,
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: Dimens.gapTiny),
          for (final c in sorted)
            InfoRow(
              leading: StatusDot(tone: tone(c), label: c.state),
              title: c.name,
              subtitle: c.status,
              trailing: c.health == 'unhealthy' ? l10n.dockerUnhealthy : null,
              trailingTone: Tone.critical,
              onTap: () => _actions(context, c.name),
            ),
        ],
      );
    },
  );

  static Future<void> _actions(BuildContext context, String name) async {
    final l10n = context.l10n;
    final repo = context.read<HomeServerActionsRepository>();
    final server = context.read<ServerRepository>().current;
    if (server == null || !await isAdmin(context)) return;
    final allowed = switch (await repo.dockerActions(server)) {
      Ok(:final value) => value.allows(name),
      Error() => false,
    };
    if (!allowed || !context.mounted) return;
    await showActions(context, [
      (
        icon: Icons.restart_alt,
        label: l10n.dockerRestart,
        onTap: () async {
          if (!await confirmAction(
            context,
            title: l10n.dockerRestartConfirm(name),
            action: l10n.dockerRestart,
          )) {
            return;
          }
          if (!context.mounted) return;
          await runAction(
            context,
            (server) => repo.restart(server, name),
            done: l10n.dockerRestarted(name),
          );
        },
      ),
      (
        icon: Icons.notes,
        label: l10n.dockerLogs,
        onTap: () => showDialog<void>(
          context: context,
          builder: (context) =>
              _LogsDialog(name: name, repo: repo, server: server),
        ),
      ),
    ]);
  }
}

class _LogsDialog extends StatelessWidget {
  const _LogsDialog({
    required this.name,
    required this.repo,
    required this.server,
  });

  final String name;
  final HomeServerActionsRepository repo;

  // Passed in: the dialog lives in the navigator's overlay, which need not
  // see the providers of the dashboard.
  final ServerAddress server;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(name),
      content: SizedBox(
        width: double.maxFinite,
        child: FutureBuilder(
          future: repo.logs(server, name),
          builder: (context, snapshot) => switch (snapshot.data) {
            Ok(:final value) => SingleChildScrollView(
              reverse: true,
              child: SelectableText(
                value.join('\n'),
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(fontFamily: 'monospace'),
              ),
            ),
            Error(:final error) => Text(context.l10n.errorMessage(error)),
            null => const Center(child: CircularProgressIndicator()),
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(MaterialLocalizations.of(context).closeButtonLabel),
        ),
      ],
    );
  }
}
