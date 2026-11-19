import 'package:waylight_mobile/ui/core/widget_registry.dart';
import 'package:waylight_mobile/ui/widgets/adguard/adguard_widget.dart';
import 'package:waylight_mobile/ui/widgets/backups/backups_widget.dart';
import 'package:waylight_mobile/ui/widgets/birthdays/birthdays_widget.dart';
import 'package:waylight_mobile/ui/widgets/bookmarks/bookmarks_widget.dart';
import 'package:waylight_mobile/ui/widgets/clock/clock_widget.dart';
import 'package:waylight_mobile/ui/widgets/countdown/countdown_widget.dart';
import 'package:waylight_mobile/ui/widgets/diskhealth/diskhealth_widget.dart';
import 'package:waylight_mobile/ui/widgets/docker/docker_widget.dart';
import 'package:waylight_mobile/ui/widgets/electricity/electricity_widget.dart';
import 'package:waylight_mobile/ui/widgets/fritzbox/fritzbox_widget.dart';
import 'package:waylight_mobile/ui/widgets/holidays/holidays_widget.dart';
import 'package:waylight_mobile/ui/widgets/notes/notes_widget.dart';
import 'package:waylight_mobile/ui/widgets/proxmox/proxmox_widget.dart';
import 'package:waylight_mobile/ui/widgets/services/services_widget.dart';
import 'package:waylight_mobile/ui/widgets/speedtest/speedtest_widget.dart';
import 'package:waylight_mobile/ui/widgets/system/system_widget.dart';
import 'package:waylight_mobile/ui/widgets/timeline/timeline_widget.dart';
import 'package:waylight_mobile/ui/widgets/todos/todos_widget.dart';
import 'package:waylight_mobile/ui/widgets/transit/transit_widget.dart';
import 'package:waylight_mobile/ui/widgets/waste/waste_widget.dart';
import 'package:waylight_mobile/ui/widgets/weather/weather_widget.dart';
import 'package:waylight_mobile/ui/widgets/wireguard/wireguard_widget.dart';

/// The widget kinds with a native view. Add a kind here when its feature
/// folder in `ui/widgets/` is done (docs/adding-a-feature.md).
const nativeWidgets = WidgetRegistry({
  'adguard': AdguardWidget.forPlacement,
  'backup-status': BackupsWidget.forPlacement,
  'birthdays': BirthdaysWidget.forPlacement,
  'bookmarks': BookmarksWidget.forPlacement,
  'clock': ClockWidget.forPlacement,
  'countdown': CountdownWidget.forPlacement,
  'diskhealth': DiskHealthWidget.forPlacement,
  'docker': DockerWidget.forPlacement,
  'electricity': ElectricityWidget.forPlacement,
  'fritzbox': FritzboxWidget.forPlacement,
  'fritzbox-calls': CallsWidget.forPlacement,
  'holidays': HolidaysWidget.forPlacement,
  'notes': NotesWidget.forPlacement,
  'proxmox': ProxmoxWidget.forPlacement,
  'services': ServicesWidget.forPlacement,
  'speedtest': SpeedtestWidget.forPlacement,
  'status-overview': StatusOverviewWidget.forPlacement,
  'system': SystemWidget.forPlacement,
  'timeline': TimelineWidget.forPlacement,
  'todos': TodosWidget.forPlacement,
  'transit': TransitWidget.forPlacement,
  'waste': WasteWidget.forPlacement,
  'weather': WeatherWidget.forPlacement,
  'wireguard': WireguardWidget.forPlacement,
});
