import 'package:waylight_mobile/data/repositories/push/push_repository.dart';
import 'package:waylight_mobile/ui/core/error_messages.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/settings/view_models/settings_area.dart';

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
