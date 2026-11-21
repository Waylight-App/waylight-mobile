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
  String get connectPrivacy => 'Your Waylight. Your data. Your server.';

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
  String get attentionTitle => 'Needs your attention';

  @override
  String attentionBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count things need your attention',
      one: '1 thing needs your attention',
    );
    return '$_temp0';
  }

  @override
  String get attentionBroken => 'Not working any more';

  @override
  String get attentionSetup => 'Not set up yet';

  @override
  String get attentionEmpty => 'Everything is set up and working.';

  @override
  String get attentionSignIn => 'Sign in again';

  @override
  String get attentionCheck => 'Check again';

  @override
  String get attentionFix => 'Fix access';

  @override
  String get attentionChoose => 'Set up';

  @override
  String get attentionConnect => 'Connect';

  @override
  String get attentionStillBroken => 'Still not working.';

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
  String get pairWatchTitle => 'Pair a watch';

  @override
  String get pairWatchEntry => 'Pair a watch';

  @override
  String get pairWatchIntro =>
      'Open Waylight on your Wear OS watch and choose Pair with phone. The watch shows a QR code. Both devices need to be in the same Wi-Fi.';

  @override
  String get pairWatchScan => 'Scan the watch\'s code';

  @override
  String get pairWatchScanAgain => 'Scan another code';

  @override
  String get pairWatchScanPrompt =>
      'Point the camera at the QR code on the watch';

  @override
  String pairWatchFound(String address) {
    return 'Watch found at $address';
  }

  @override
  String get pairWatchSend => 'Pair this watch';

  @override
  String get pairWatchDone =>
      'The watch is paired. It shows up under Settings → Apps in Waylight, where you can revoke it.';

  @override
  String get pairWatchUnavailable => 'Pairing a watch needs the Android app.';

  @override
  String get pairWatchInvalidCode =>
      'This is not the code of a Waylight watch. Open Pair with phone on the watch and scan the code it shows.';

  @override
  String get pairWatchUnreachable =>
      'The watch does not answer. Check that the phone and the watch are in the same Wi-Fi and the code is still shown on the watch.';

  @override
  String get pairWatchNotDecryptable =>
      'The watch could not read the message. Scan the code the watch shows now.';

  @override
  String get pairWatchRejected =>
      'The server did not accept the pairing. Try again.';

  @override
  String get pairWatchInvalidServer =>
      'The watch does not accept this server\'s address. Plain HTTP only works for addresses in the home network.';

  @override
  String get pairWatchServerUnreachable =>
      'The watch cannot reach your server. Check its network connection.';

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
  String get editTabTitle => 'Arrange tab';

  @override
  String get editTabReset => 'Reset';

  @override
  String get editTabHidden => 'Hidden on phones';

  @override
  String get editTabUp => 'Move earlier';

  @override
  String get editTabDown => 'Move later';

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

  @override
  String get weatherWarning => 'Weather warning';

  @override
  String get weatherUv => 'UV index today';

  @override
  String weatherWarningUntil(String time) {
    return 'until $time';
  }

  @override
  String get calendarNewEvent => 'New event';

  @override
  String get calendarEventTitle => 'Title';

  @override
  String get calendarEventLocation => 'Location (optional)';

  @override
  String get calendarSave => 'Save';

  @override
  String get calendarShowAll => 'Show agenda';

  @override
  String get shoppingOpen => 'Open list';

  @override
  String calendarEventAdded(String title) {
    return 'Added $title.';
  }

  @override
  String get smartHomeAll => 'All devices';

  @override
  String get rssOpen => 'Open reader';

  @override
  String get rssAllRead => 'Mark all read';

  @override
  String get rssUnreadOnly => 'Unread';

  @override
  String get rssAllFeeds => 'All';

  @override
  String get timelineOpen => 'All events';

  @override
  String get timelineAll => 'All';

  @override
  String get timelineCritical => 'Critical';

  @override
  String get noteNew => 'New note';

  @override
  String get noteEdit => 'Edit note';

  @override
  String get noteBodyHint => 'Text (Markdown)';

  @override
  String get noteSaved => 'Note saved.';

  @override
  String get noteConflict =>
      'This note was changed elsewhere. Reload it and edit again.';

  @override
  String get noteTitleMissing => 'Give the note a title.';

  @override
  String get noteDelete => 'Delete';

  @override
  String get noteDeleteConfirm => 'Delete this note?';

  @override
  String get notePin => 'Pin';

  @override
  String get noteUnpin => 'Unpin';

  @override
  String get readLaterUnread => 'Unread';

  @override
  String get readLaterSave => 'Save link';

  @override
  String get readLaterOriginal => 'Open original';

  @override
  String get readLaterArchive => 'Archive';

  @override
  String get readLaterNoCopy =>
      'There is no reader copy of this page; open the original.';

  @override
  String get dropSend => 'Send text';

  @override
  String get serviceDetails => 'Uptime and outages';

  @override
  String get serviceUptime => 'Uptime';

  @override
  String get serviceDay => 'Last 24 hours';

  @override
  String get serviceWeek => 'Last 7 days';

  @override
  String get serviceMonth => 'Last 30 days';

  @override
  String get serviceQuarter => 'Last 90 days';

  @override
  String get serviceIncidents => 'Outages';

  @override
  String get serviceNoIncidents => 'No outages recorded.';

  @override
  String serviceDownSince(String time) {
    return 'Down since $time';
  }

  @override
  String get securityTitle => 'Password and sign-in';

  @override
  String get securityPassword => 'Password';

  @override
  String get securityChangePassword => 'Change password';

  @override
  String get securityCurrentPassword => 'Current password';

  @override
  String get securityNewPassword => 'New password';

  @override
  String get securityPasswordChanged =>
      'Password changed. Other devices are signed out.';

  @override
  String get securityTotp => 'Two-factor sign-in';

  @override
  String get securityTotpOn =>
      'On: a code from your authenticator app is asked at sign-in.';

  @override
  String get securityTotpIsOff => 'Off.';

  @override
  String get securityTotpSetUp => 'Set up';

  @override
  String get securityTotpOff => 'Turn off';

  @override
  String get securityTotpHint =>
      'Add this key to your authenticator app, or open the app directly, then enter the code it shows.';

  @override
  String get securityOpenAuthenticator => 'Open authenticator app';

  @override
  String get securityCode => 'Code';

  @override
  String get securityConfirm => 'Confirm';

  @override
  String get securityRecoveryCodes => 'Recovery codes';

  @override
  String get securityCodesSaved => 'I saved them';

  @override
  String get securitySessions => 'Signed-in devices';

  @override
  String get securityThisDevice => 'This device';

  @override
  String get securitySignOutSession => 'Sign out';

  @override
  String get securitySignOutOthers => 'Sign out all other devices';

  @override
  String get securitySessionEnded => 'Signed out.';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsPushSwitch => 'Notifications on this phone';

  @override
  String get settingsPushHint =>
      'Messages from the notification rules of Waylight arrive end-to-end encrypted through the Waylight relay, without Google. While on, Android shows a permanent notification “Waylight is connected”. In the web interface, also turn on the channel “Waylight app”.';

  @override
  String get settingsPushDenied =>
      'Notifications are blocked for this app in the system settings.';

  @override
  String get settingsPushNotInBuild =>
      'This version of the app has no push notifications.';

  @override
  String get summaryAction => 'Summarise';

  @override
  String get summaryTitle => 'Summary';

  @override
  String get summaryByAi =>
      'Written by the server\'s local AI; it can be wrong.';

  @override
  String get bookmarkAdd => 'Add bookmark';

  @override
  String get bookmarkEdit => 'Edit bookmark';

  @override
  String get bookmarkFolder => 'Folder';

  @override
  String get bookmarkNoFolder => 'No folder';

  @override
  String get searchOpenWidget => 'Open widget';

  @override
  String get shareTitle => 'Save to Waylight';

  @override
  String get shareTodo => 'As a to-do';

  @override
  String get shareNote => 'As a note';

  @override
  String shareSaved(String target) {
    return 'Saved: $target';
  }

  @override
  String get homeWidgetTodos => 'To-dos today';

  @override
  String get homeWidgetTodosEmpty => 'Nothing due today';

  @override
  String get homeWidgetDepartures => 'Departures';

  @override
  String get homeWidgetNoStop =>
      'Add a transit widget with a stop to the dashboard';

  @override
  String get homeWidgetNoDepartures => 'No departures';

  @override
  String get homeWidgetCancelled => 'cancelled';

  @override
  String homeWidgetUpdated(String time) {
    return 'Updated $time';
  }

  @override
  String get summaryAsk => 'Ask about it';

  @override
  String get grafanaAlertsTitle => 'Grafana alerts';

  @override
  String get grafanaAllQuiet => 'No alert is firing.';

  @override
  String get grafanaFiring => 'firing';

  @override
  String get grafanaPending => 'pending';

  @override
  String get grafanaAlertList => 'Alert list';

  @override
  String get grafanaPanelTitle => 'Grafana panel';

  @override
  String get grafanaChoosePanel =>
      'Choose a dashboard and a panel in the web interface.';

  @override
  String grafanaPanelAlt(String title) {
    return 'Grafana panel $title';
  }

  @override
  String get settingsPushBattery =>
      'Android may cut the connection to save battery.';

  @override
  String get settingsPushBatteryAction => 'Allow';

  @override
  String get dashboardOpenWidget => 'open in full';

  @override
  String get widgetSizeFull => 'Full width';

  @override
  String get widgetSizeSmall => 'Small';

  @override
  String get widgetSizeMedium => 'Medium';

  @override
  String get widgetSizeLarge => 'Large';

  @override
  String get widgetSizeStrip => 'Strip';

  @override
  String editTabSize(String size) {
    return 'Size: $size';
  }

  @override
  String editTabSizeOf(String widget) {
    return 'Size of $widget';
  }

  @override
  String get editTabHint =>
      'Hold and drag to move. Tap the size to change it. − hides a widget on phones.';

  @override
  String get editTabDone => 'Done';

  @override
  String editTabHide(String widget) {
    return 'Hide $widget on phones';
  }

  @override
  String get editTabHideOnPhones => 'Hide on phones';

  @override
  String editTabShow(String widget) {
    return 'Show $widget again';
  }

  @override
  String get editTabDiscardTitle => 'Discard your changes?';

  @override
  String get editTabDiscard => 'Discard';

  @override
  String get editTabKeep => 'Keep editing';

  @override
  String get dashboardTapToOpen => 'Tap to see everything';

  @override
  String todosCompactOpen(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count open',
      one: '1 open',
    );
    return '$_temp0';
  }

  @override
  String todosCompactNext(String title) {
    return 'next: $title';
  }

  @override
  String transitThen(String times) {
    return 'then $times';
  }

  @override
  String calendarMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+$count more',
      one: '+1 more',
    );
    return '$_temp0';
  }

  @override
  String statusAllUp(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count services up',
      one: '1 service up',
    );
    return '$_temp0';
  }

  @override
  String statusSomeDown(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count services down',
      one: '1 service down',
    );
    return '$_temp0';
  }

  @override
  String get galleryOpen => 'Add widget';

  @override
  String galleryTitle(String tab) {
    return 'Add to “$tab”';
  }

  @override
  String get gallerySearch => 'Search widgets';

  @override
  String get galleryAdd => 'Add';

  @override
  String get galleryAdded => 'Added';

  @override
  String get galleryEmpty => 'No widgets match.';

  @override
  String get editTabMore => 'More';

  @override
  String get diagnosticsCreate => 'Create diagnostic report';

  @override
  String get diagnosticsHint =>
      'For a bug report: app and server version, device and the last errors, without addresses or passwords.';

  @override
  String get diagnosticsTitle => 'Diagnostic report';

  @override
  String get diagnosticsPreview =>
      'This is everything the report contains. It only leaves the phone if you share it.';

  @override
  String get diagnosticsShare => 'Share';

  @override
  String get settingsColours => 'Colours';

  @override
  String get settingsColoursWaylight => 'Like Waylight';

  @override
  String get settingsColoursWallpaper => 'Wallpaper';

  @override
  String get addressesTitle => 'Addresses';

  @override
  String get addressesHint =>
      'Tried in this order; the first that answers and knows your session is used, e.g. the home network first, then the address on the go.';

  @override
  String get addressInUse => 'In use';

  @override
  String get addressUnreachable => 'Not reachable right now';

  @override
  String get addressRejected =>
      'Answers, but does not know your session – another server under this address?';

  @override
  String get addressRaise => 'Try earlier';

  @override
  String get addressRemove => 'Remove address';

  @override
  String get addressAdd => 'Add address';

  @override
  String get reminderTodoBody => 'Due today';

  @override
  String get reminderEventAllDay => 'All day today';

  @override
  String reminderEventAt(String time, int minutes) {
    return 'At $time, in $minutes min';
  }

  @override
  String reminderBirthdayTitle(String name) {
    return '$name\'s birthday';
  }

  @override
  String reminderBirthdayAge(int age) {
    return 'Turns $age today';
  }

  @override
  String get reminderBirthdayBody => 'Birthday today';

  @override
  String get settingsReminders => 'Reminders on this phone';

  @override
  String get settingsRemindersHint =>
      'Shown by the phone itself, also offline. Updated whenever the app loads the dashboard.';

  @override
  String get settingsReminderTodos => 'To-dos on their due day, at 8:00';

  @override
  String get settingsReminderEvents => 'Events';

  @override
  String get settingsReminderEventsOff => 'Off';

  @override
  String settingsReminderMinutes(int minutes) {
    return '$minutes min before';
  }

  @override
  String get settingsReminderBirthdays => 'Birthdays, at 8:00';

  @override
  String get settingsReminderDenied =>
      'Notifications are turned off for Waylight in the system settings.';

  @override
  String get focusStartBreak => 'Break';

  @override
  String get focusPause => 'Pause';

  @override
  String get focusResume => 'Resume';

  @override
  String get focusRunning => 'Focus';

  @override
  String get focusBreak => 'Break';

  @override
  String get kioskUse => 'Use as wall display';

  @override
  String get kioskUseHint =>
      'Paste the link of a kiosk display from the web interface (Settings → Accounts → Kiosk displays).';

  @override
  String get kioskStart => 'Start';

  @override
  String get kioskLinkInvalid =>
      'This is not a kiosk link. It looks like https://…/kiosk#…';

  @override
  String get kioskLinkRejected =>
      'The server does not know this link any more. Create a new one in the web interface.';

  @override
  String get kioskLinkFailed =>
      'The wall display could not start. Is the server reachable?';

  @override
  String get kioskNoTabs => 'No tabs for this display.';

  @override
  String get kioskLeave => 'Leave wall display (hold)';

  @override
  String get kioskLeaveReason => 'Confirm to leave the wall display';

  @override
  String get presenceTitle => 'Presence';

  @override
  String get presenceOffice => 'Office';

  @override
  String get presenceHome => 'Home';

  @override
  String get presenceAway => 'Away';

  @override
  String get presenceNone => 'Not set';

  @override
  String get presenceMine => 'My status today';

  @override
  String get presenceReturnOn => 'Back on';

  @override
  String presenceBack(String date) {
    return 'back $date';
  }

  @override
  String get presenceFromAbsence => 'from the absences';

  @override
  String get presenceEmpty => 'Nobody in this group.';

  @override
  String get presenceOff => 'Presence is switched off for this organisation.';

  @override
  String presenceCounts(int office, int home, int away, int none) {
    return '$office in the office · $home at home · $away away · $none not set';
  }

  @override
  String get absencesTitle => 'Absences';

  @override
  String get absencesToday => 'Away today';

  @override
  String get absencesWeek => 'Later this week';

  @override
  String get absencesNobodyToday => 'Everyone is here today.';

  @override
  String get absencesNobodyWeek => 'No other absences this week.';

  @override
  String get absencesOff => 'Absences are not available on this server.';

  @override
  String get absenceHoliday => 'Holiday';

  @override
  String get absenceSick => 'Sick';

  @override
  String get absenceRemote => 'Working remotely';

  @override
  String get absenceAway => 'Away';

  @override
  String absenceRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get absenceAdd => 'Enter an absence';

  @override
  String absenceEdit(String name) {
    return 'Edit absence of $name';
  }

  @override
  String get absenceDelete => 'Delete';

  @override
  String get absenceFrom => 'From';

  @override
  String get absenceTo => 'To (included)';

  @override
  String get absenceKind => 'Kind';

  @override
  String get absenceNote => 'Note (optional)';

  @override
  String get absencePrivate => 'Private: others only see that I am away';

  @override
  String get absencePrivateBadge => 'private';

  @override
  String get absenceErrorDates => 'The last day must not be before the first.';

  @override
  String get announcementsTitle => 'Announcements';

  @override
  String get announcementsEmpty => 'No announcements.';

  @override
  String get announcementsOff =>
      'Announcements are not available on this server.';

  @override
  String get announcementUnread => 'unread';

  @override
  String get announcementPinned => 'Pinned';

  @override
  String get announcementWrite => 'Write an announcement';

  @override
  String get announcementEdit => 'Edit announcement';

  @override
  String get announcementDelete => 'Delete';

  @override
  String get announcementPublish => 'Publish';

  @override
  String get announcementTitleField => 'Title';

  @override
  String get announcementBodyField => 'Text';

  @override
  String get announcementMarkdownHint =>
      'Markdown: **bold**, *italic*, lists and links.';

  @override
  String get announcementExpires => 'Expires';

  @override
  String get announcementNoExpiry => 'No expiry';

  @override
  String get announcementNotify => 'Send to the notification channels';

  @override
  String get parcelsScan => 'Scan the label';

  @override
  String get parcelsScanPrompt =>
      'Point the camera at the barcode of the shipping label';

  @override
  String get parcelsScanNoNumber =>
      'No tracking number in this code. Type it, or scan the barcode next to the number.';

  @override
  String get quickTileStatus => 'My status';

  @override
  String get quickTileOn => 'On';

  @override
  String get quickTileOff => 'Off';

  @override
  String get quickTileUnreachable => 'Not reachable';

  @override
  String get quickTileChooseTitle => 'Smart home tile';

  @override
  String get quickTileChooseHint =>
      'Choose the device the Waylight tile in Quick Settings switches.';

  @override
  String quickTileChosen(String name) {
    return 'The tile now switches $name.';
  }

  @override
  String get quickTileNoDevices =>
      'The server allows no device to be switched.';

  @override
  String get quickTilesTitle => 'Quick Settings tiles';

  @override
  String get quickTilesHint =>
      'Add Waylight\'s tiles in the phone\'s Quick Settings: add a to-do, switch a device, set your status.';

  @override
  String get quickTileSmartHomeChoice => 'Device of the smart home tile';

  @override
  String get quickTileNoChoice => 'Not chosen yet';

  @override
  String get settingsAreaAccount => 'Account & security';

  @override
  String get settingsAreaServer => 'Server & connection';

  @override
  String get settingsAreaNotifications => 'Notifications & reminders';

  @override
  String get settingsAreaPhone => 'This phone';

  @override
  String get settingsAreaAbout => 'About & help';

  @override
  String get settingsAreaEmpty => 'Nothing to set here on this phone.';

  @override
  String get settingsStatusNoAddress => 'No address answers';

  @override
  String get settingsStatusPushOn => 'Push on';

  @override
  String get settingsStatusPushOff => 'Push off';

  @override
  String get settingsStatusRemindersOn => 'Reminders on';

  @override
  String get settingsStatusRemindersOff => 'Reminders off';

  @override
  String get settingsStatusLockOn => 'App lock on';

  @override
  String get settingsStatusLockOff => 'App lock off';

  @override
  String get settingsStatusPhone => 'Widgets and tiles';

  @override
  String settingsStatusVersion(String version) {
    return 'Version $version';
  }

  @override
  String get settingsConnection => 'Connection';

  @override
  String get settingsOtherServers => 'Other servers';

  @override
  String get settingsAdvanced => 'Advanced';

  @override
  String get settingsCheckNow => 'Check addresses now';

  @override
  String get settingsCheckNowHint =>
      'Tries the addresses in order and uses the first that answers.';

  @override
  String get settingsHomeWidgets => 'Home screen widgets';

  @override
  String get settingsHomeWidgetsHint =>
      'Touch and hold an empty spot on the home screen, choose Widgets and pick one from Waylight.';

  @override
  String get settingsWallDisplayHint =>
      'Choose “Add another server” under Server & connection, then “Use as wall display” and paste the link of a kiosk display.';
}
