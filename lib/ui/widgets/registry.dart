import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/ui/core/widget_registry.dart';
import 'package:waylight_mobile/ui/widgets/absences/absences_widget.dart';
import 'package:waylight_mobile/ui/widgets/adguard/adguard_widget.dart';
import 'package:waylight_mobile/ui/widgets/announcements/announcements_widget.dart';
import 'package:waylight_mobile/ui/widgets/apps/apps_widgets.dart';
import 'package:waylight_mobile/ui/widgets/backups/backup_health_widget.dart';
import 'package:waylight_mobile/ui/widgets/backups/backups_widget.dart';
import 'package:waylight_mobile/ui/widgets/birthdays/birthdays_widget.dart';
import 'package:waylight_mobile/ui/widgets/bookmarks/bookmarks_widget.dart';
import 'package:waylight_mobile/ui/widgets/calendar/calendar_widget.dart';
import 'package:waylight_mobile/ui/widgets/clock/clock_widget.dart';
import 'package:waylight_mobile/ui/widgets/countdown/countdown_widget.dart';
import 'package:waylight_mobile/ui/widgets/diskhealth/diskhealth_widget.dart';
import 'package:waylight_mobile/ui/widgets/docker/docker_widget.dart';
import 'package:waylight_mobile/ui/widgets/electricity/electricity_widget.dart';
import 'package:waylight_mobile/ui/widgets/fritzbox/fritzbox_widget.dart';
import 'package:waylight_mobile/ui/widgets/fuel/fuel_widget.dart';
import 'package:waylight_mobile/ui/widgets/grafana/grafana_widgets.dart';
import 'package:waylight_mobile/ui/widgets/habits/habits_widget.dart';
import 'package:waylight_mobile/ui/widgets/holidays/holidays_widget.dart';
import 'package:waylight_mobile/ui/widgets/household/household_widgets.dart';
import 'package:waylight_mobile/ui/widgets/lists/list_widgets.dart';
import 'package:waylight_mobile/ui/widgets/markets/markets_widget.dart';
import 'package:waylight_mobile/ui/widgets/media/media_widgets.dart';
import 'package:waylight_mobile/ui/widgets/notes/notes_widget.dart';
import 'package:waylight_mobile/ui/widgets/parcels/parcels_widget.dart';
import 'package:waylight_mobile/ui/widgets/phonelist/phonelist_widget.dart';
import 'package:waylight_mobile/ui/widgets/presence/presence_widget.dart';
import 'package:waylight_mobile/ui/widgets/proxmox/proxmox_widget.dart';
import 'package:waylight_mobile/ui/widgets/readlater/read_later_widget.dart';
import 'package:waylight_mobile/ui/widgets/rss/rss_widget.dart';
import 'package:waylight_mobile/ui/widgets/services/services_widget.dart';
import 'package:waylight_mobile/ui/widgets/shopping/shopping_widget.dart';
import 'package:waylight_mobile/ui/widgets/smarthome/smarthome_widget.dart';
import 'package:waylight_mobile/ui/widgets/speedtest/speedtest_widget.dart';
import 'package:waylight_mobile/ui/widgets/sports/sports_widget.dart';
import 'package:waylight_mobile/ui/widgets/study/study_widget.dart';
import 'package:waylight_mobile/ui/widgets/system/system_widget.dart';
import 'package:waylight_mobile/ui/widgets/timeline/timeline_widget.dart';
import 'package:waylight_mobile/ui/widgets/todos/todos_widget.dart';
import 'package:waylight_mobile/ui/widgets/transit/transit_widget.dart';
import 'package:waylight_mobile/ui/widgets/waste/waste_widget.dart';
import 'package:waylight_mobile/ui/widgets/weather/weather_widget.dart';
import 'package:waylight_mobile/ui/widgets/wireguard/wireguard_widget.dart';

/// Kinds with long lists and no small or strip tile: they start at medium
/// and also offer large.
const _roomySizes = WidgetSizes([WidgetSize.medium, WidgetSize.large]);

/// The widget kinds with a native view. Add a kind here when its feature
/// folder in `ui/widgets/` is done (docs/adding-a-feature.md); add its
/// `preview` to `previews` once it has example data (#251).
const nativeWidgets = WidgetRegistry(
  // A clock needs no more than half a screen; kinds not listed offer every
  // size.
  sizes: {
    'absences': _roomySizes,
    'announcements': _roomySizes,
    'bookmarks': _roomySizes,
    'fritzbox-calls': _roomySizes,
    'grafana-alerts': _roomySizes,
    'notes': _roomySizes,
    'phonelist': _roomySizes,
    'sports': _roomySizes,
    'study': _roomySizes,
    // Pictures and charts need room, so they start large.
    'space': WidgetSizes([
      WidgetSize.medium,
      WidgetSize.large,
    ], defaultSize: WidgetSize.large),
    'grafana-panel': WidgetSizes([
      WidgetSize.medium,
      WidgetSize.large,
    ], defaultSize: WidgetSize.large),
    // The radar is a square picture; it does not fit a small tile or a strip.
    'radar': WidgetSizes([
      WidgetSize.medium,
      WidgetSize.large,
    ], defaultSize: WidgetSize.large),
    'clock': WidgetSizes([
      WidgetSize.small,
      WidgetSize.medium,
      WidgetSize.strip,
    ], defaultSize: WidgetSize.small),
  },
  // The groups of the server's widget picker; kinds not listed are
  // everyday widgets.
  categories: {
    'briefing': WidgetCategory.information,
    'calendar': WidgetCategory.information,
    'gamedeals': WidgetCategory.information,
    'holidays': WidgetCategory.information,
    'markets': WidgetCategory.information,
    'parcels': WidgetCategory.information,
    'radar': WidgetCategory.information,
    'releases': WidgetCategory.information,
    'rss': WidgetCategory.information,
    'shopping': WidgetCategory.information,
    'space': WidgetCategory.information,
    'sports': WidgetCategory.information,
    'timeline': WidgetCategory.information,
    'transit': WidgetCategory.information,
    'waste': WidgetCategory.information,
    'weather': WidgetCategory.information,
    'apiwidget': WidgetCategory.server,
    'arr': WidgetCategory.server,
    'backup-health': WidgetCategory.server,
    'backup-status': WidgetCategory.server,
    'diskhealth': WidgetCategory.server,
    'docker': WidgetCategory.server,
    'proxmox': WidgetCategory.server,
    'services': WidgetCategory.server,
    'speedtest': WidgetCategory.server,
    'status-overview': WidgetCategory.server,
    'system': WidgetCategory.server,
    'adguard': WidgetCategory.network,
    'fritzbox': WidgetCategory.network,
    'fritzbox-calls': WidgetCategory.network,
    'grafana-alerts': WidgetCategory.network,
    'grafana-panel': WidgetCategory.network,
    'immich': WidgetCategory.network,
    'media': WidgetCategory.network,
    'nextcloud': WidgetCategory.network,
    'smarthome': WidgetCategory.network,
    'wireguard': WidgetCategory.network,
  },
  previews: {
    'focus': FocusWidget.preview,
    'presence': PresenceWidget.preview,
    'todos': TodosWidget.preview,
    'transit': TransitWidget.preview,
    'weather': WeatherWidget.preview,
  },
  {
    'adguard': AdguardWidget.forPlacement,
    'apiwidget': ApiValuesWidget.forPlacement,
    'arr': ListWidget.arr,
    'backup-health': BackupHealthWidget.forPlacement,
    'board': HouseholdWidgets.board,
    'backup-status': BackupsWidget.forPlacement,
    'birthdays': BirthdaysWidget.forPlacement,
    'bookmarks': BookmarksWidget.forPlacement,
    'briefing': ListWidget.briefing,
    'calendar': CalendarWidget.forPlacement,
    'chores': HouseholdWidgets.chores,
    'contracts': HouseholdWidgets.contracts,
    'documents': HouseholdWidgets.documents,
    'gifts': HouseholdWidgets.gifts,
    'meals': HouseholdWidgets.meals,
    'meters': HouseholdWidgets.meters,
    'clock': ClockWidget.forPlacement,
    'countdown': CountdownWidget.forPlacement,
    'diskhealth': DiskHealthWidget.forPlacement,
    'docker': DockerWidget.forPlacement,
    'drop': DropWidget.forPlacement,
    'electricity': ElectricityWidget.forPlacement,
    'focus': FocusWidget.forPlacement,
    'presence': PresenceWidget.forPlacement,
    'absences': AbsencesWidget.forPlacement,
    'announcements': AnnouncementsWidget.forPlacement,
    'fritzbox': FritzboxWidget.forPlacement,
    'fritzbox-calls': CallsWidget.forPlacement,
    'fuel': FuelWidget.forPlacement,
    'grafana-alerts': GrafanaAlertsWidget.forPlacement,
    'grafana-panel': GrafanaPanelWidget.forPlacement,
    'gamedeals': ListWidget.gameDeals,
    'habits': HabitsWidget.forPlacement,
    'holidays': HolidaysWidget.forPlacement,
    'immich': AppOverviewWidget.immich,
    'mail': MailWidget.forPlacement,
    'markets': MarketsWidget.forPlacement,
    'media': ListWidget.media,
    'nextcloud': AppOverviewWidget.nextcloud,
    'notes': NotesWidget.forPlacement,
    'parcels': ParcelsWidget.forPlacement,
    'phonelist': PhoneListWidget.forPlacement,
    'photo-frame': PhotoFrameWidget.forPlacement,
    'proxmox': ProxmoxWidget.forPlacement,
    'radar': RadarWidget.forPlacement,
    'readlater': ReadLaterWidget.forPlacement,
    'releases': ListWidget.releases,
    'rss': RssWidget.forPlacement,
    'services': ServicesWidget.forPlacement,
    'shopping': ShoppingWidget.forPlacement,
    'smarthome': SmartHomeWidget.forPlacement,
    'space': SpaceWidget.forPlacement,
    'speedtest': SpeedtestWidget.forPlacement,
    'sports': SportsWidget.forPlacement,
    'status-overview': StatusOverviewWidget.forPlacement,
    'study': StudyWidget.forPlacement,
    'system': SystemWidget.forPlacement,
    'timeline': TimelineWidget.forPlacement,
    'todos': TodosWidget.forPlacement,
    'transit': TransitWidget.forPlacement,
    'waste': WasteWidget.forPlacement,
    'weather': WeatherWidget.forPlacement,
    'wireguard': WireguardWidget.forPlacement,
  },
);
