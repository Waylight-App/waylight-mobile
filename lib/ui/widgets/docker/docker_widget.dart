import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/data/repositories/widget_data/queries/home_server.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/home_server.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/widgets/common/simple_widget.dart';
import 'package:waylight_mobile/ui/widgets/common/widget_rows.dart';

/// The native view of the Docker widget (#120): counts and the containers,
/// stopped and unhealthy ones first. Restarting follows with #108.
class DockerWidget extends StatelessWidget {
  /// Creates the view for [widget].
  const DockerWidget({required this.widget, super.key});

  /// The placement of the widget.
  final WidgetPlacement widget;

  /// The builder for the widget registry.
  static Widget forPlacement(BuildContext context, WidgetPlacement widget) =>
      DockerWidget(widget: widget, key: ValueKey(widget.id));

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
            ),
        ],
      );
    },
  );
}
