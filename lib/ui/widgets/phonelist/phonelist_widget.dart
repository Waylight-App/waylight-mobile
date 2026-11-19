import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/data/repositories/widget_data/queries/information.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/information.dart';
import 'package:waylight_mobile/ui/core/link_opener.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/widgets/common/simple_widget.dart';
import 'package:waylight_mobile/ui/widgets/common/widget_rows.dart';

/// The native view of the phone list (#136); tapping an entry calls it.
class PhoneListWidget extends StatelessWidget {
  /// Creates the view for [widget].
  const PhoneListWidget({required this.widget, super.key});

  /// The placement of the widget.
  final WidgetPlacement widget;

  /// The builder for the widget registry.
  static Widget forPlacement(BuildContext context, WidgetPlacement widget) =>
      PhoneListWidget(widget: widget, key: ValueKey(widget.id));

  @override
  Widget build(BuildContext context) => SimpleWidget<List<PhoneEntry>>(
    placement: widget,
    defaultTitle: context.l10n.phoneListTitle,
    query: phoneListQuery,
    interval: const Duration(hours: 1),
    builder: (context, entries) {
      if (entries.isEmpty) return Text(context.l10n.phoneListEmpty);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final e in entries)
            InfoRow(
              title: e.name,
              subtitle: [
                if (e.role.isNotEmpty) e.role,
                if (e.team.isNotEmpty) e.team,
              ].join(' · '),
              trailing: e.phone,
              onTap: e.dial.isEmpty && e.phone.isEmpty
                  ? null
                  : () => LinkOpener.of(context).open(
                      Uri(
                        scheme: 'tel',
                        path: e.dial.isNotEmpty
                            ? e.dial
                            : e.phone.replaceAll(' ', ''),
                      ),
                    ),
            ),
        ],
      );
    },
  );
}
