import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/domain/models/appearance.dart';
import 'package:waylight_mobile/ui/core/link_opener.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/core/widgets/command_button.dart';
import 'package:waylight_mobile/ui/core/widgets/section_card.dart';
import 'package:waylight_mobile/ui/settings/view_models/settings_view_model.dart';
import 'package:waylight_mobile/utils/command.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The address of the app's source code.
final sourceUrl = Uri.parse('https://github.com/Waylight-App/waylight-mobile');

/// The privacy section of the app's documentation.
final privacyUrl = Uri.parse(
  'https://github.com/Waylight-App/waylight-mobile/blob/main/docs/security.md',
);

/// Server, account, appearance and information about the app (#14).
class SettingsScreen extends StatelessWidget {
  /// Creates the screen for [viewModel].
  const SettingsScreen({required this.viewModel, super.key});

  /// The state and actions of this screen.
  final SettingsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(Dimens.gap),
          children: [
            SectionCard(
              title: l10n.settingsServer,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Line(label: l10n.settingsAddress, value: viewModel.server),
                  _CommandLine(
                    label: l10n.settingsVersion,
                    command: viewModel.serverVersion,
                  ),
                  const SizedBox(height: Dimens.gapSmall),
                  CommandButton(
                    key: const ValueKey('settings.disconnect'),
                    command: viewModel.disconnect,
                    onPressed: () => viewModel.disconnect.execute().ignore(),
                    label: l10n.homeDisconnect,
                    variant: CommandButtonVariant.outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: Dimens.gap),
            SectionCard(
              title: l10n.settingsAccount,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ListenableBuilder(
                    listenable: viewModel.account,
                    builder: (context, _) => switch (viewModel.account.result) {
                      Ok(:final value) => _Line(
                        label: roleLabel(l10n, value.role),
                        value: value.username.isEmpty
                            ? l10n.settingsOwnerAccount
                            : value.username,
                      ),
                      _ => const SizedBox.shrink(),
                    },
                  ),
                  const SizedBox(height: Dimens.gapSmall),
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
            const SizedBox(height: Dimens.gap),
            SectionCard(
              title: l10n.settingsAppearance,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.settingsTheme),
                  const SizedBox(height: Dimens.gapSmall),
                  SegmentedButton<ThemeChoice>(
                    key: const ValueKey('settings.theme'),
                    segments: [
                      ButtonSegment(
                        value: ThemeChoice.system,
                        label: Text(l10n.settingsSystem),
                      ),
                      ButtonSegment(
                        value: ThemeChoice.light,
                        label: Text(l10n.settingsLight),
                      ),
                      ButtonSegment(
                        value: ThemeChoice.dark,
                        label: Text(l10n.settingsDark),
                      ),
                    ],
                    selected: {viewModel.appearance.theme},
                    onSelectionChanged: (s) => viewModel.setTheme(s.single),
                  ),
                  const SizedBox(height: Dimens.gap),
                  Text(l10n.settingsLanguage),
                  const SizedBox(height: Dimens.gapSmall),
                  SegmentedButton<AppLanguage>(
                    key: const ValueKey('settings.language'),
                    segments: [
                      ButtonSegment(
                        value: AppLanguage.system,
                        label: Text(l10n.settingsSystem),
                      ),
                      // Language names in their own language, so anyone
                      // finds theirs.
                      const ButtonSegment(
                        value: AppLanguage.en,
                        label: Text('English'),
                      ),
                      const ButtonSegment(
                        value: AppLanguage.de,
                        label: Text('Deutsch'),
                      ),
                    ],
                    selected: {viewModel.appearance.language},
                    onSelectionChanged: (s) => viewModel.setLanguage(s.single),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Dimens.gap),
            SectionCard(
              title: l10n.settingsAbout,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _CommandLine(
                    label: l10n.settingsAppVersion,
                    command: viewModel.appVersion,
                  ),
                  _Line(label: l10n.settingsLicence, value: 'MIT'),
                  _LinkTile(label: l10n.settingsSource, url: sourceUrl),
                  _LinkTile(label: l10n.settingsPrivacy, url: privacyUrl),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    minTileHeight: Dimens.tapTarget,
                    title: Text(l10n.settingsLicences),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => showLicensePage(
                      context: context,
                      applicationName: l10n.appTitle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The words for an account role.
@visibleForTesting
String roleLabel(AppLocalizations l10n, String role) => switch (role) {
  'owner' => l10n.settingsRoleOwner,
  'admin' => l10n.settingsRoleAdmin,
  'member' => l10n.settingsRoleMember,
  'guest' => l10n.settingsRoleGuest,
  _ => l10n.settingsAccount,
};

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimens.gapTiny),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Flexible(child: Text(value, textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}

/// A [_Line] whose value is loaded by [command]; hidden when it fails.
class _CommandLine extends StatelessWidget {
  const _CommandLine({required this.label, required this.command});

  final String label;
  final Command0<String> command;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: command,
    builder: (context, _) => switch (command.result) {
      Ok(:final value) => _Line(label: label, value: value),
      _ => const SizedBox.shrink(),
    },
  );
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({required this.label, required this.url});

  final String label;
  final Uri url;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    minTileHeight: Dimens.tapTarget,
    title: Text(label),
    trailing: const Icon(Icons.open_in_new),
    onTap: () => openLink(context, url, context.l10n.linkOpenFailed),
  );
}
