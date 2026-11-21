import 'package:waylight_mobile/data/repositories/push/push_repository.dart';
import 'package:waylight_mobile/ui/core/error_messages.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/settings/view_models/settings_area.dart';
import 'package:waylight_mobile/ui/settings/view_models/settings_index.dart';

/// The words for an account role.
String roleLabel(AppLocalizations l10n, String role) => switch (role) {
  'owner' => l10n.settingsRoleOwner,
  'admin' => l10n.settingsRoleAdmin,
  'member' => l10n.settingsRoleMember,
  'guest' => l10n.settingsRoleGuest,
  _ => l10n.settingsAccount,
};

/// The name of a settings area, on the start page and as screen title.
String areaTitle(AppLocalizations l10n, SettingsArea area) => switch (area) {
  SettingsArea.account => l10n.settingsAreaAccount,
  SettingsArea.server => l10n.settingsAreaServer,
  SettingsArea.appearance => l10n.settingsAppearance,
  SettingsArea.notifications => l10n.settingsAreaNotifications,
  SettingsArea.phone => l10n.settingsAreaPhone,
  SettingsArea.about => l10n.settingsAreaAbout,
};

/// Why notifications could not be turned on.
String pushErrorText(AppLocalizations l10n, Exception error) => switch (error) {
  PushUnavailable(reason: PushUnavailableReason.permissionDenied) =>
    l10n.settingsPushDenied,
  PushUnavailable() => l10n.settingsPushNotInBuild,
  _ => l10n.errorMessage(error),
};

/// The name of a single setting in the results of the settings search.
String itemTitle(AppLocalizations l10n, SettingsItem item) => switch (item) {
  SettingsItem.account => l10n.settingsAccount,
  SettingsItem.security => l10n.securityTitle,
  SettingsItem.signOut => l10n.homeSignOut,
  SettingsItem.serverAddress => l10n.settingsAddress,
  SettingsItem.serverVersion => l10n.settingsVersion,
  SettingsItem.addresses => l10n.addressesTitle,
  SettingsItem.otherServers => l10n.settingsOtherServers,
  SettingsItem.checkAddresses => l10n.settingsCheckNow,
  SettingsItem.disconnect => l10n.homeDisconnect,
  SettingsItem.theme => l10n.settingsTheme,
  SettingsItem.colours => l10n.settingsColours,
  SettingsItem.language => l10n.settingsLanguage,
  SettingsItem.push => l10n.settingsPushSwitch,
  SettingsItem.battery => l10n.settingsSearchBattery,
  SettingsItem.reminders => l10n.settingsReminders,
  SettingsItem.lock => l10n.settingsLock,
  SettingsItem.homeWidgets => l10n.settingsHomeWidgets,
  SettingsItem.quickTiles => l10n.quickTilesTitle,
  SettingsItem.wallDisplay => l10n.kioskUse,
  SettingsItem.appVersion => l10n.settingsAppVersion,
  SettingsItem.source => l10n.settingsSource,
  SettingsItem.privacy => l10n.settingsPrivacy,
  SettingsItem.diagnostics => l10n.diagnosticsCreate,
  SettingsItem.licences => l10n.settingsLicences,
};
