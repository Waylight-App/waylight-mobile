import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:waylight_mobile/domain/models/appearance.dart';
import 'package:waylight_mobile/domain/models/server_status.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/core/widgets/command_button.dart';
import 'package:waylight_mobile/ui/settings/view_models/settings_area.dart';
import 'package:waylight_mobile/ui/settings/view_models/settings_view_model.dart';
import 'package:waylight_mobile/ui/settings/widgets/settings_area_screen.dart';
import 'package:waylight_mobile/ui/settings/widgets/settings_texts.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The start page of the settings (#231): who is signed in, one row per
/// area with a line of status, and signing out.
class SettingsScreen extends StatelessWidget {
  /// Creates the start page for [viewModel].
  const SettingsScreen({required this.viewModel, super.key});

  /// The state and actions of the settings.
  final SettingsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListenableBuilder(
        listenable: Listenable.merge([
          viewModel,
          viewModel.account,
          viewModel.appVersion,
        ]),
        builder: (context, _) => SettingsPage(
          children: [
            _Profile(viewModel: viewModel),
            const SizedBox(height: Dimens.gap),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (final area in SettingsArea.values)
                    if (_shows(area))
                      ListTile(
                        key: ValueKey('settings.area.${area.segment}'),
                        minTileHeight: Dimens.tapTarget,
                        leading: Icon(_icon(area)),
                        title: Text(areaTitle(l10n, area)),
                        subtitle: Text(areaStatus(l10n, viewModel, area)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _open(context, area).ignore(),
                      ),
                ],
              ),
            ),
            const SizedBox(height: Dimens.gap),
            CommandButton(
              key: const ValueKey('settings.signOut'),
              command: viewModel.signOut,
              onPressed: () => viewModel.signOut.execute().ignore(),
              label: l10n.homeSignOut,
              variant: CommandButtonVariant.outlined,
            ),
          ],
        ),
      ),
    );
  }

  // An area without anything this phone can set stays off the start page;
  // its link still opens and says so.
  bool _shows(SettingsArea area) =>
      area != SettingsArea.notifications ||
      viewModel.pushAvailable ||
      viewModel.remindersAvailable;

  Future<void> _open(BuildContext context, SettingsArea area) async {
    await context.push(area.path);
    // Push, battery and the tile choice have no repository that tells
    // this page about changes made in the area.
    await viewModel.refresh();
  }

  static IconData _icon(SettingsArea area) => switch (area) {
    SettingsArea.account => Icons.person_outline,
    SettingsArea.server => Icons.dns_outlined,
    SettingsArea.appearance => Icons.palette_outlined,
    SettingsArea.notifications => Icons.notifications_outlined,
    SettingsArea.phone => Icons.smartphone,
    SettingsArea.about => Icons.info_outline,
  };
}

/// The line of status below an area on the start page.
@visibleForTesting
String areaStatus(
  AppLocalizations l10n,
  SettingsViewModel viewModel,
  SettingsArea area,
) {
  final parts = switch (area) {
    SettingsArea.account => [
      if (viewModel.account.result case Ok(:final value))
        ..._account(l10n, value),
    ],
    SettingsArea.server => [
      viewModel.activeAddress?.toString() ?? l10n.settingsStatusNoAddress,
    ],
    SettingsArea.appearance => [
      _theme(l10n, viewModel.appearance.theme),
      _language(l10n, viewModel.appearance.language),
    ],
    SettingsArea.notifications => [
      if (viewModel.pushAvailable)
        viewModel.pushOn
            ? l10n.settingsStatusPushOn
            : l10n.settingsStatusPushOff,
      if (viewModel.remindersAvailable)
        viewModel.anyReminderOn
            ? l10n.settingsStatusRemindersOn
            : l10n.settingsStatusRemindersOff,
    ],
    SettingsArea.phone => [
      if (viewModel.lockAvailable)
        viewModel.lockEnabled
            ? l10n.settingsStatusLockOn
            : l10n.settingsStatusLockOff
      else
        l10n.settingsStatusPhone,
    ],
    SettingsArea.about => [
      if (viewModel.appVersion.result case Ok(:final value))
        l10n.settingsStatusVersion(value),
    ],
  };
  return parts.join(' · ');
}

List<String> _account(AppLocalizations l10n, ServerStatus status) => [
  if (status.username.isEmpty) l10n.settingsOwnerAccount else status.username,
  roleLabel(l10n, status.role),
];

String _theme(AppLocalizations l10n, ThemeChoice theme) => switch (theme) {
  ThemeChoice.system => l10n.settingsSystem,
  ThemeChoice.light => l10n.settingsLight,
  ThemeChoice.dark => l10n.settingsDark,
};

// Language names stay in their own language, as in the picker.
String _language(AppLocalizations l10n, AppLanguage language) =>
    switch (language) {
      AppLanguage.system => l10n.settingsSystem,
      AppLanguage.en => 'English',
      AppLanguage.de => 'Deutsch',
    };

/// The signed-in account and its server at the top of the start page.
class _Profile extends StatelessWidget {
  const _Profile({required this.viewModel});

  final SettingsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final status = switch (viewModel.account.result) {
      Ok(:final value) => value,
      _ => null,
    };
    final name = switch (status) {
      null => '',
      ServerStatus(username: '') => l10n.settingsOwnerAccount,
      ServerStatus(:final username) => username,
    };
    return MergeSemantics(
      child: Row(
        children: [
          ExcludeSemantics(
            child: CircleAvatar(
              radius: Dimens.tapTarget / 2,
              child: Text(
                name.isEmpty ? '' : name.characters.first.toUpperCase(),
                style: theme.textTheme.titleLarge,
              ),
            ),
          ),
          const SizedBox(width: Dimens.gap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (name.isNotEmpty)
                  Text(name, style: theme.textTheme.titleMedium),
                Text(
                  [
                    if (status != null) roleLabel(l10n, status.role),
                    viewModel.server,
                  ].join(' · '),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
