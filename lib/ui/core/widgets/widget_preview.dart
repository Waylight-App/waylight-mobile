import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/ui/core/widget_size_scope.dart';
import 'package:waylight_mobile/ui/core/widgets/compact_card.dart';
import 'package:waylight_mobile/ui/core/widgets/section_card.dart';

/// A widget's real view filled with example data, for the gallery (#251):
/// the card a tile of [size] gets on the dashboard, with [compact] in
/// small and strip tiles and [full] in medium and large ones. It loads
/// nothing, so it works without a server.
class WidgetPreview extends StatelessWidget {
  /// Creates the preview of the widget [title] in [size].
  const WidgetPreview({
    required this.title,
    required this.size,
    required this.compact,
    required this.full,
    super.key,
  });

  /// The widget's title.
  final String title;

  /// The size of the tile.
  final WidgetSize size;

  /// The compact view, as `WidgetFrame.compact` builds it.
  final WidgetBuilder compact;

  /// The full view, as `WidgetFrame.builder` builds it.
  final WidgetBuilder full;

  @override
  Widget build(BuildContext context) => WidgetSizeScope(
    size: size,
    child: isCompact(size)
        ? CompactCard(
            title: title,
            size: size,
            child: Builder(builder: compact),
          )
        : SectionCard(
            title: title,
            child: Builder(builder: full),
          ),
  );
}
