// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Waylight';

  @override
  String get connectTitle => 'Connect your Waylight';

  @override
  String get connectIntro =>
      'Enter the address you open Waylight with in your browser.';

  @override
  String get connectAddressLabel => 'Server address';

  @override
  String get connectAddressHint => 'https://home.example.org';

  @override
  String get connectButton => 'Connect';

  @override
  String get connectErrorEmpty => 'Enter the address of your server.';

  @override
  String get connectErrorInvalid =>
      'This is not a valid address. Example: https://home.example.org';

  @override
  String get connectErrorScheme =>
      'The address must start with http:// or https://.';

  @override
  String get connectErrorParts =>
      'Leave out user name, password and anything after ? or #.';

  @override
  String get connectErrorNotWaylight =>
      'This address does not answer like a Waylight server.';

  @override
  String get connectInsecureWarning =>
      'Without https:// your password travels unencrypted. Use this only in your own network.';

  @override
  String get homeSetupRequired =>
      'This server has no account yet. Finish the setup in your browser first.';

  @override
  String get homeDisconnect => 'Use another server';

  @override
  String get connectPrivacy => 'The app talks to your server and nobody else.';

  @override
  String get errorUnreachable =>
      'The server cannot be reached. Is your phone in the same network or VPN?';

  @override
  String get errorUnauthorized =>
      'Your session has ended. Please sign in again.';

  @override
  String get errorForbidden => 'Your account may not do this.';

  @override
  String get errorNotFound =>
      'This is not available on your server. The module may be switched off.';

  @override
  String get errorInvalid => 'Please check your input.';

  @override
  String get errorTooManyRequests =>
      'Too many attempts. Please wait a few minutes and try again.';

  @override
  String get errorServer =>
      'The server answered with an error. Please try again later.';

  @override
  String get errorUnknown => 'Something went wrong. Please try again.';

  @override
  String get signInTitle => 'Sign in';

  @override
  String signInServer(String server) {
    return 'on $server';
  }

  @override
  String get signInExpired => 'Your session has ended. Please sign in again.';

  @override
  String get signInUsernameLabel => 'Account name';

  @override
  String get signInUsernameHelper => 'Leave empty for the owner account.';

  @override
  String get signInPasswordLabel => 'Password';

  @override
  String get signInCodeLabel => 'Code';

  @override
  String get signInCodeHint =>
      'The code from your authenticator app, or a recovery code.';

  @override
  String get signInCodeHintRecovery =>
      'This account uses a passkey. Enter one of your recovery codes.';

  @override
  String get signInButton => 'Sign in';

  @override
  String get signInErrorCredentials =>
      'The account name or the password is wrong.';

  @override
  String get signInErrorCode => 'The password or the code is wrong.';

  @override
  String get homeSignOut => 'Sign out';

  @override
  String get dashboardWidgetNotYet => 'Not available in the app yet.';

  @override
  String get dashboardRetry => 'Try again';

  @override
  String get dashboardNoTabs =>
      'There are no tabs for your account yet. Add one in the web interface.';

  @override
  String get dashboardEmptyTab => 'This tab has no widgets yet.';

  @override
  String get connectErrorInsecure =>
      'Plain http:// only works for addresses in your home network. Use https:// for this server.';

  @override
  String get weatherClearSky => 'Clear sky';

  @override
  String get weatherMainlyClear => 'Mainly clear';

  @override
  String get weatherPartlyCloudy => 'Partly cloudy';

  @override
  String get weatherOvercast => 'Overcast';

  @override
  String get weatherFog => 'Fog';

  @override
  String get weatherRimeFog => 'Rime fog';

  @override
  String get weatherLightDrizzle => 'Light drizzle';

  @override
  String get weatherDrizzle => 'Drizzle';

  @override
  String get weatherDenseDrizzle => 'Dense drizzle';

  @override
  String get weatherFreezingDrizzle => 'Freezing drizzle';

  @override
  String get weatherLightRain => 'Light rain';

  @override
  String get weatherRain => 'Rain';

  @override
  String get weatherHeavyRain => 'Heavy rain';

  @override
  String get weatherFreezingRain => 'Freezing rain';

  @override
  String get weatherLightSnow => 'Light snow';

  @override
  String get weatherSnow => 'Snow';

  @override
  String get weatherHeavySnow => 'Heavy snow';

  @override
  String get weatherSnowGrains => 'Snow grains';

  @override
  String get weatherRainShowers => 'Rain showers';

  @override
  String get weatherViolentShowers => 'Violent showers';

  @override
  String get weatherSnowShowers => 'Snow showers';

  @override
  String get weatherThunderstorm => 'Thunderstorm';

  @override
  String get weatherThunderstormWithHail => 'Thunderstorm with hail';

  @override
  String get weatherUnknown => 'Unknown';

  @override
  String weatherDegrees(int value) {
    return '$value °C';
  }

  @override
  String weatherFeelsLike(int value) {
    return 'Feels like $value °C';
  }

  @override
  String weatherRange(int min, int max) {
    return '$min° / $max°';
  }

  @override
  String weatherPrecipitation(int value) {
    return '$value % rain';
  }

  @override
  String get weatherNoPlace =>
      'Choose a place for this widget in the web interface.';

  @override
  String get todosTitle => 'To-dos';

  @override
  String get todosEmpty => 'Nothing to do.';

  @override
  String get todosDone => 'Done';

  @override
  String get todosOverdue => 'Overdue';

  @override
  String get todosToday => 'Today';

  @override
  String get todosTomorrow => 'Tomorrow';

  @override
  String get notesTitle => 'Notes';

  @override
  String get notesNone => 'No notes yet.';

  @override
  String get notesNonePinned => 'No pinned notes.';

  @override
  String get notesPinned => 'Pinned';

  @override
  String get bookmarksTitle => 'Bookmarks';

  @override
  String get bookmarksEmpty => 'No bookmarks yet.';

  @override
  String get linkOpenFailed => 'The link could not be opened.';

  @override
  String get dashboardOpenInWaylight => 'Open in Waylight';

  @override
  String get transitTitle => 'Departures';

  @override
  String get transitNoStop =>
      'Choose a stop for this widget in the web interface.';

  @override
  String get transitEmpty => 'No departures in the next hours.';

  @override
  String get transitNow => 'now';

  @override
  String transitInMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String transitDelay(int minutes) {
    return '+$minutes';
  }

  @override
  String get transitCancelled => 'cancelled';

  @override
  String transitTimeTrack(String time, String track) {
    return '$time · platform $track';
  }

  @override
  String get wasteTitle => 'Waste collection';

  @override
  String get wasteNotConfigured =>
      'Set up the waste calendar in the web interface.';

  @override
  String get wasteEmpty => 'No collections ahead.';

  @override
  String wasteInDays(int days) {
    return 'in $days days';
  }

  @override
  String get freshnessJustNow => 'updated just now';

  @override
  String freshnessMinutesAgo(int minutes) {
    return 'updated $minutes min ago';
  }

  @override
  String freshnessStale(String age) {
    return 'outdated – $age';
  }

  @override
  String freshnessFailed(String age) {
    return 'refresh failed – $age';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsServer => 'Server';

  @override
  String get settingsAddress => 'Address';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsOwnerAccount => 'Owner account';

  @override
  String get settingsRoleOwner => 'Owner';

  @override
  String get settingsRoleAdmin => 'Admin';

  @override
  String get settingsRoleMember => 'Member';

  @override
  String get settingsRoleGuest => 'Guest';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsSystem => 'System';

  @override
  String get settingsLight => 'Light';

  @override
  String get settingsDark => 'Dark';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsAppVersion => 'App version';

  @override
  String get settingsLicence => 'Licence';

  @override
  String get settingsSource => 'Source code';

  @override
  String get settingsPrivacy => 'Privacy';

  @override
  String get settingsLicences => 'Open-source licences';

  @override
  String get pairTitle => 'Connecting the app';

  @override
  String get pairInvalidLink =>
      'This link is not a complete pairing code. Show a new QR code in Waylight under Settings → Mobile app.';

  @override
  String get pairCodeInvalid =>
      'This pairing code is not valid any more. Show a new QR code in Waylight under Settings → Mobile app.';

  @override
  String get pairEnterManually => 'Enter the address instead';

  @override
  String get connectQrHint =>
      'Or scan the QR code under Settings → Mobile app in Waylight with your phone\'s camera.';

  @override
  String get connectTryDemo => 'Try the public demo';

  @override
  String get dashboardDemo =>
      'This is the public demo. Its data is reset every hour.';

  @override
  String get errorConflict =>
      'Someone else changed this in the meantime. It was loaded again.';

  @override
  String get todosAddLabel => 'New to-do';

  @override
  String get todosAdd => 'Add';

  @override
  String get todosClearCompleted => 'Clear completed';

  @override
  String get todosTitleLabel => 'Title';

  @override
  String get todosTitleRequired => 'Enter a title.';

  @override
  String get todosNoDueDate => 'No due date';

  @override
  String get todosRemoveDueDate => 'Remove due date';

  @override
  String get todosDelete => 'Delete';

  @override
  String get todosSave => 'Save';

  @override
  String dashboardOffline(String time) {
    return 'Offline · showing the data from $time';
  }

  @override
  String get signInBrowser =>
      'Sign in in the browser (passkey, Microsoft, SSO)';

  @override
  String get authCallbackTitle => 'Finishing the sign-in';

  @override
  String get authCallbackCancelled =>
      'The sign-in in the browser was cancelled.';

  @override
  String get authCallbackUnexpected =>
      'This sign-in was not started in this app, or it took too long. Please start it again.';

  @override
  String get authCallbackBack => 'Back to the sign-in';

  @override
  String get searchHint => 'Search';

  @override
  String get searchIntro =>
      'Type a keyword, a widget, \"t\" and a to-do, or anything to search the web.';

  @override
  String searchWeb(String query) {
    return 'Search the web for \"$query\"';
  }

  @override
  String searchAddTodo(String title) {
    return 'Add to-do \"$title\"';
  }

  @override
  String searchTodoAdded(String title) {
    return 'To-do \"$title\" added.';
  }

  @override
  String searchOnTab(String tab) {
    return 'On the tab $tab';
  }

  @override
  String get lockTitle => 'Waylight is locked';

  @override
  String get lockUnlock => 'Unlock';

  @override
  String get lockReason => 'Unlock Waylight';

  @override
  String get settingsLock => 'App lock';

  @override
  String get settingsLockSwitch => 'Lock with fingerprint, face or device PIN';

  @override
  String get settingsLockAfter => 'Lock after';

  @override
  String get settingsLockNow => 'At once';

  @override
  String settingsLockMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get shortcutAddTodo => 'Add to-do';

  @override
  String get shortcutDepartures => 'Departures';

  @override
  String get todosPending => 'Not saved on the server yet';

  @override
  String todosConflicts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes could not be saved.',
      one: '1 change could not be saved.',
    );
    return '$_temp0';
  }

  @override
  String get todosConflictsDecide => 'Decide';

  @override
  String get todosConflictChanged => 'Changed elsewhere in the meantime.';

  @override
  String todosConflictRejected(String message) {
    return 'The server refused it: $message';
  }

  @override
  String get todosKeepMine => 'Keep mine';

  @override
  String get todosKeepServer => 'Keep the server\'s';

  @override
  String get todosDiscard => 'Discard';

  @override
  String get todosDeletedTodo => 'Deleted to-do';

  @override
  String get editTabTitle => 'Edit tab';

  @override
  String get editTabReset => 'Reset';

  @override
  String get editTabHidden => 'Hidden on phones';

  @override
  String get editTabUp => 'Move up';

  @override
  String get editTabDown => 'Move down';

  @override
  String get editTabNotEditable =>
      'This tab is shared with you and cannot be changed here.';

  @override
  String get settingsSwitchServer => 'Switch to this server';

  @override
  String get settingsRemoveServer => 'Remove server';

  @override
  String get settingsAddServer => 'Add another server';

  @override
  String get systemTitle => 'System';

  @override
  String get systemCpu => 'CPU';

  @override
  String get systemMemory => 'Memory';

  @override
  String get systemSwap => 'Swap';

  @override
  String get servicesTitle => 'Services';

  @override
  String get servicesEmpty => 'No services yet.';

  @override
  String get servicesOnline => 'Online';

  @override
  String get servicesOffline => 'Offline';

  @override
  String get servicesUnknown => 'Unchecked';

  @override
  String get statusOverviewTitle => 'Status';

  @override
  String get backupsTitle => 'Backups';

  @override
  String get backupsEmpty => 'No backups or jobs report yet.';

  @override
  String get backupsOk => 'OK';

  @override
  String get backupsOverdue => 'Overdue';

  @override
  String get backupsFailed => 'Failed';

  @override
  String get backupsWaiting => 'Waiting';

  @override
  String get countdownTitle => 'Countdowns';

  @override
  String get countdownEmpty => 'No countdowns ahead.';

  @override
  String get birthdaysTitle => 'Birthdays';

  @override
  String get birthdaysEmpty => 'No birthdays yet.';

  @override
  String get electricityTitle => 'Electricity prices';

  @override
  String get electricityTomorrowLater =>
      'Tomorrow\'s prices follow around 1 pm.';

  @override
  String systemUptime(int days, int hours) {
    return 'up $days d $hours h';
  }

  @override
  String systemLoad(String load) {
    return 'load $load';
  }

  @override
  String systemDiskOf(String used, String total) {
    return '$used of $total';
  }

  @override
  String systemFullIn(int days) {
    return 'full in $days days';
  }

  @override
  String backupsLastSuccess(String date) {
    return 'last success $date';
  }

  @override
  String birthdaysTurns(int age) {
    return 'turns $age';
  }

  @override
  String electricityNow(String price) {
    return 'Now $price';
  }

  @override
  String electricityCheapest(String hours) {
    return 'Cheapest hours: $hours';
  }

  @override
  String get holidaysTitle => 'Holidays';

  @override
  String get holidaysEmpty => 'No holidays ahead.';

  @override
  String get holidaysNow => 'now';

  @override
  String get holidayNewYear => 'New Year\'s Day';

  @override
  String get holidayEpiphany => 'Epiphany';

  @override
  String get holidayWomensDay => 'International Women\'s Day';

  @override
  String get holidayGoodFriday => 'Good Friday';

  @override
  String get holidayEasterSunday => 'Easter Sunday';

  @override
  String get holidayEasterMonday => 'Easter Monday';

  @override
  String get holidayLabourDay => 'Labour Day';

  @override
  String get holidayAscension => 'Ascension Day';

  @override
  String get holidayWhitSunday => 'Whit Sunday';

  @override
  String get holidayWhitMonday => 'Whit Monday';

  @override
  String get holidayCorpusChristi => 'Corpus Christi';

  @override
  String get holidayAssumption => 'Assumption Day';

  @override
  String get holidayChildrensDay => 'World Children\'s Day';

  @override
  String get holidayGermanUnity => 'Day of German Unity';

  @override
  String get holidayReformation => 'Reformation Day';

  @override
  String get holidayAllSaints => 'All Saints\' Day';

  @override
  String get holidayRepentance => 'Day of Repentance and Prayer';

  @override
  String get holidayChristmasDay => 'Christmas Day';

  @override
  String get holidayBoxingDay => 'Boxing Day';

  @override
  String get diskHealthTitle => 'Disk health';

  @override
  String get diskHealthEmpty => 'No disks reported yet.';

  @override
  String get diskHealthWarning => 'Warning';

  @override
  String get diskHealthFailing => 'Failing';

  @override
  String get diskHealthUnknown => 'Unknown';

  @override
  String get dockerTitle => 'Docker';

  @override
  String get dockerUnhealthy => 'unhealthy';

  @override
  String get proxmoxRunning => 'Running';

  @override
  String get proxmoxStopped => 'Stopped';

  @override
  String get speedtestTitle => 'Speed test';

  @override
  String get speedtestEmpty => 'No results yet.';

  @override
  String get speedtestDownload => 'Download';

  @override
  String get speedtestUpload => 'Upload';

  @override
  String get speedtestPing => 'Ping';

  @override
  String get timelineTitle => 'Timeline';

  @override
  String get timelineEmpty => 'Nothing happened yet.';

  @override
  String get wireguardEmpty => 'No peers yet.';

  @override
  String get callsTitle => 'Calls';

  @override
  String get callsEmpty => 'No calls.';

  @override
  String get callsIncoming => 'Incoming call';

  @override
  String get callsOutgoing => 'Outgoing call';

  @override
  String get callsMissed => 'missed';

  @override
  String get callsRejected => 'Rejected call';

  @override
  String get dnsFilterTitle => 'DNS filter';

  @override
  String get dnsFilterOn => 'Protection on';

  @override
  String get dnsFilterPaused => 'Protection paused';

  @override
  String diskHealthWear(int percent) {
    return '$percent % worn';
  }

  @override
  String dockerSummary(int running, int stopped, int unhealthy) {
    return '$running running · $stopped stopped · $unhealthy unhealthy';
  }

  @override
  String speedtestAverage(int mbps) {
    return 'average $mbps Mbit/s';
  }

  @override
  String wireguardHandshake(String date) {
    return 'last handshake $date';
  }

  @override
  String dnsFilterQueries(String count) {
    return '$count queries in 24 h';
  }

  @override
  String dnsFilterBlocked(String count) {
    return 'Blocked: $count';
  }

  @override
  String get briefingTitle => 'Daily briefing';

  @override
  String get briefingWarnings => 'Weather warnings';

  @override
  String get briefingIncidents => 'Since last evening';

  @override
  String get briefingTodos => 'To-dos';

  @override
  String get briefingEvents => 'Appointments';

  @override
  String get arrHealth => 'Warnings';

  @override
  String get arrUpcoming => 'Upcoming';

  @override
  String get arrQueue => 'Downloads';

  @override
  String get mediaTitle => 'Media';

  @override
  String get mediaPlaying => 'Playing now';

  @override
  String get mediaRecent => 'Recently added';

  @override
  String get releasesTitle => 'New releases';

  @override
  String get gameDealsTitle => 'Game deals';

  @override
  String get gameDealsFree => 'Free now';

  @override
  String get gameDealsDeals => 'On sale';

  @override
  String get gameDealsNext => 'Free soon';

  @override
  String get spaceTitle => 'Rocket launches';

  @override
  String get readLaterTitle => 'Read later';

  @override
  String get listEmpty => 'Nothing here yet.';

  @override
  String get fuelTitle => 'Fuel prices';

  @override
  String get fuelEmpty => 'No stations found.';

  @override
  String get fuelClosed => 'closed';

  @override
  String get marketsTitle => 'Markets';

  @override
  String get calendarTitle => 'Calendar';

  @override
  String get calendarEmpty => 'No appointments ahead.';

  @override
  String get calendarAllDay => 'all day';

  @override
  String get phoneListTitle => 'Phone list';

  @override
  String get phoneListEmpty => 'No entries yet.';

  @override
  String get studyTitle => 'Study progress';

  @override
  String get studyAverage => 'Average grade';

  @override
  String get studyInProgress => 'in progress';

  @override
  String get appPhotos => 'Photos';

  @override
  String get appVideos => 'Videos';

  @override
  String get appUsers => 'Users';

  @override
  String get appUpdates => 'App updates';

  @override
  String get appMaintenance => 'Maintenance mode';

  @override
  String get appStorage => 'Storage';

  @override
  String get sportsTitle => 'Sports';

  @override
  String listMore(int count) {
    return '$count more';
  }

  @override
  String studyCredits(String passed, String total) {
    return '$passed of $total credits';
  }

  @override
  String sportsPlayed(int games) {
    return '$games games';
  }

  @override
  String sportsPoints(int points) {
    return '$points pts';
  }

  @override
  String get shoppingTitle => 'Shopping list';

  @override
  String get shoppingNotConfigured =>
      'Create a shopping list in the web interface first.';

  @override
  String get shoppingEmpty => 'Nothing to buy.';

  @override
  String get shoppingAdd => 'Add item';

  @override
  String get habitsTitle => 'Habits';

  @override
  String get habitsEmpty => 'No habits due today.';

  @override
  String shoppingClear(int count) {
    return 'Remove $count in the basket';
  }

  @override
  String habitsStreak(int current, int best) {
    return '$current days in a row · best $best';
  }

  @override
  String get rssTitle => 'Feeds';

  @override
  String get rssCaughtUp => 'All caught up.';

  @override
  String get rssMarkRead => 'Mark as read';

  @override
  String get rssMarkUnread => 'Mark as unread';

  @override
  String get parcelsTitle => 'Parcels';

  @override
  String get parcelsEmpty => 'No parcels on their way.';

  @override
  String get parcelsAdd => 'Add parcel';

  @override
  String get parcelsNumber => 'Tracking number';

  @override
  String get parcelsLabel => 'What is it? (optional)';

  @override
  String get parcelsCancel => 'Cancel';

  @override
  String get parcelsTrack => 'Track at the carrier';

  @override
  String get parcelsDelete => 'Stop tracking';

  @override
  String get parcelsAnnounced => 'announced';

  @override
  String get parcelsOnTheWay => 'on its way';

  @override
  String get parcelsDelivered => 'delivered';

  @override
  String get parcelsCheck => 'check';

  @override
  String get smartHomeTitle => 'Smart home';

  @override
  String get smartHomeEmpty => 'Choose entities in the web interface.';

  @override
  String get smartHomeRun => 'Run';

  @override
  String parcelsExpected(String date) {
    return 'expected $date';
  }

  @override
  String get photoFrameTitle => 'Photos';

  @override
  String get photoFrameEmpty => 'No photos in this album yet.';

  @override
  String get radarTitle => 'Rain radar';

  @override
  String get radarNoPlace => 'Choose a place in the web interface.';

  @override
  String get apodTitle => 'Picture of the day';

  @override
  String get apiWidgetNoEndpoint => 'Choose an endpoint in the web interface.';

  @override
  String get mailTitle => 'Mail';

  @override
  String get dropTitle => 'Drop zone';

  @override
  String get dropEmpty => 'Nothing dropped yet.';

  @override
  String get focusTitle => 'Focus';

  @override
  String get focusStart => 'Start';

  @override
  String get focusStop => 'Stop';

  @override
  String mailUnread(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unread messages',
      one: '1 unread message',
      zero: '0 unread messages',
    );
    return '$_temp0';
  }

  @override
  String focusToday(int minutes, int sessions) {
    return 'Today: $minutes min in $sessions sessions';
  }

  @override
  String get servicesOpen => 'Open';

  @override
  String get servicesWake => 'Wake up';

  @override
  String get dockerRestart => 'Restart';

  @override
  String get dockerLogs => 'Show log';

  @override
  String get proxmoxStart => 'Start';

  @override
  String get proxmoxShutdown => 'Shut down';

  @override
  String servicesWakeSent(String name) {
    return 'Wake-up sent to $name.';
  }

  @override
  String dockerRestartConfirm(String name) {
    return 'Restart $name?';
  }

  @override
  String dockerRestarted(String name) {
    return '$name is restarting.';
  }

  @override
  String proxmoxSent(String name) {
    return 'Sent to $name.';
  }

  @override
  String dnsFilterPause(int minutes) {
    return 'Pause for $minutes minutes';
  }
}
