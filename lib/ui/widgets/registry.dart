import 'package:waylight_mobile/ui/core/widget_registry.dart';
import 'package:waylight_mobile/ui/widgets/backups/backups_widget.dart';
import 'package:waylight_mobile/ui/widgets/birthdays/birthdays_widget.dart';
import 'package:waylight_mobile/ui/widgets/bookmarks/bookmarks_widget.dart';
import 'package:waylight_mobile/ui/widgets/clock/clock_widget.dart';
import 'package:waylight_mobile/ui/widgets/countdown/countdown_widget.dart';
import 'package:waylight_mobile/ui/widgets/electricity/electricity_widget.dart';
import 'package:waylight_mobile/ui/widgets/notes/notes_widget.dart';
import 'package:waylight_mobile/ui/widgets/services/services_widget.dart';
import 'package:waylight_mobile/ui/widgets/system/system_widget.dart';
import 'package:waylight_mobile/ui/widgets/todos/todos_widget.dart';
import 'package:waylight_mobile/ui/widgets/transit/transit_widget.dart';
import 'package:waylight_mobile/ui/widgets/waste/waste_widget.dart';
import 'package:waylight_mobile/ui/widgets/weather/weather_widget.dart';

/// The widget kinds with a native view. Add a kind here when its feature
/// folder in `ui/widgets/` is done (docs/adding-a-feature.md).
const nativeWidgets = WidgetRegistry({
  'backup-status': BackupsWidget.forPlacement,
  'birthdays': BirthdaysWidget.forPlacement,
  'bookmarks': BookmarksWidget.forPlacement,
  'clock': ClockWidget.forPlacement,
  'countdown': CountdownWidget.forPlacement,
  'electricity': ElectricityWidget.forPlacement,
  'notes': NotesWidget.forPlacement,
  'services': ServicesWidget.forPlacement,
  'status-overview': StatusOverviewWidget.forPlacement,
  'system': SystemWidget.forPlacement,
  'todos': TodosWidget.forPlacement,
  'transit': TransitWidget.forPlacement,
  'waste': WasteWidget.forPlacement,
  'weather': WeatherWidget.forPlacement,
});
