import 'package:waylight_mobile/ui/core/widget_registry.dart';
import 'package:waylight_mobile/ui/widgets/bookmarks/bookmarks_widget.dart';
import 'package:waylight_mobile/ui/widgets/clock/clock_widget.dart';
import 'package:waylight_mobile/ui/widgets/notes/notes_widget.dart';
import 'package:waylight_mobile/ui/widgets/todos/todos_widget.dart';
import 'package:waylight_mobile/ui/widgets/transit/transit_widget.dart';
import 'package:waylight_mobile/ui/widgets/waste/waste_widget.dart';
import 'package:waylight_mobile/ui/widgets/weather/weather_widget.dart';

/// The widget kinds with a native view. Add a kind here when its feature
/// folder in `ui/widgets/` is done (docs/adding-a-feature.md).
const nativeWidgets = WidgetRegistry({
  'bookmarks': BookmarksWidget.forPlacement,
  'clock': ClockWidget.forPlacement,
  'notes': NotesWidget.forPlacement,
  'todos': TodosWidget.forPlacement,
  'transit': TransitWidget.forPlacement,
  'waste': WasteWidget.forPlacement,
  'weather': WeatherWidget.forPlacement,
});
