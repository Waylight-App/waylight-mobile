import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:waylight_mobile/data/repositories/lock/app_lock_repository.dart';
import 'package:waylight_mobile/data/repositories/push/push_repository.dart';
import 'package:waylight_mobile/domain/models/address_check.dart';
import 'package:waylight_mobile/domain/models/appearance.dart';
import 'package:waylight_mobile/domain/models/reminder.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/routing/routes.dart';
import 'package:waylight_mobile/ui/core/address_errors.dart';
import 'package:waylight_mobile/ui/core/error_messages.dart';
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
                  _Addresses(viewModel: viewModel),
                  _CommandLine(
                    label: l10n.settingsVersion,
                    command: viewModel.serverVersion,
                  ),
                  for (final server in viewModel.servers)
                    if (server.toString() != viewModel.server)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        minTileHeight: Dimens.tapTarget,
                        leading: const Icon(Icons.dns_outlined),
                        title: Text(server.toString()),
                        subtitle: Text(l10n.settingsSwitchServer),
                        onTap: () => viewModel.switchTo(server).ignore(),
                        trailing: IconButton(
                          tooltip: l10n.settingsRemoveServer,
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () =>
                              viewModel.removeServer(server).ignore(),
                        ),
                      ),
                  const SizedBox(height: Dimens.gapSmall),
                  OutlinedButton.icon(
                    key: const ValueKey('settings.addServer'),
                    onPressed: () => viewModel.addServer().ignore(),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.settingsAddServer),
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
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.security),
                    title: Text(l10n.securityTitle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(Routes.security),
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
                  if (viewModel.wallpaperAvailable) ...[
                    const SizedBox(height: Dimens.gap),
                    Text(l10n.settingsColours),
                    const SizedBox(height: Dimens.gapSmall),
                    SegmentedButton<bool>(
                      key: const ValueKey('settings.colours'),
                      segments: [
                        ButtonSegment(
                          value: false,
                          label: Text(l10n.settingsColoursWaylight),
                        ),
                        ButtonSegment(
                          value: true,
                          label: Text(l10n.settingsColoursWallpaper),
                        ),
                      ],
                      selected: {viewModel.useWallpaper},
                      onSelectionChanged: (s) =>
                          viewModel.setWallpaper(enabled: s.single).ignore(),
                    ),
                  ],
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
            if (viewModel.quickTilesAvailable) ...[
              const SizedBox(height: Dimens.gap),
              SectionCard(
                title: l10n.quickTilesTitle,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.quickTilesHint,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    ListTile(
                      key: const ValueKey('settings.tileEntity'),
                      contentPadding: EdgeInsets.zero,
                      minTileHeight: Dimens.tapTarget,
                      title: Text(l10n.quickTileSmartHomeChoice),
                      subtitle: Text(
                        viewModel.tileEntity.isEmpty
                            ? l10n.quickTileNoChoice
                            : viewModel.tileEntity,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _chooseTileEntity(context).ignore(),
                    ),
                  ],
                ),
              ),
            ],
            if (viewModel.remindersAvailable) ...[
              const SizedBox(height: Dimens.gap),
              _Reminders(viewModel: viewModel),
            ],
            if (viewModel.pushAvailable) ...[
              const SizedBox(height: Dimens.gap),
              SectionCard(
                title: l10n.settingsNotifications,
                child: ListenableBuilder(
                  listenable: viewModel.setPush,
                  builder: (context, _) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SwitchListTile(
                        key: const ValueKey('settings.push'),
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.settingsPushSwitch),
                        subtitle: Text(l10n.settingsPushHint),
                        value: viewModel.pushOn,
                        onChanged: viewModel.setPush.running
                            ? null
                            : (on) => viewModel.setPush.execute(on).ignore(),
                      ),
                      if (viewModel.pushOn && !viewModel.batteryUnrestricted)
                        ListTile(
                          key: const ValueKey('settings.push.battery'),
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.battery_alert_outlined),
                          title: Text(l10n.settingsPushBattery),
                          trailing: TextButton(
                            onPressed: () =>
                                viewModel.allowInBackground().ignore(),
                            child: Text(l10n.settingsPushBatteryAction),
                          ),
                        ),
                      if (viewModel.setPush.result case Error(:final error))
                        Text(
                          pushErrorText(l10n, error),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
            if (viewModel.lockAvailable) ...[
              const SizedBox(height: Dimens.gap),
              SectionCard(
                title: l10n.settingsLock,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SwitchListTile(
                      key: const ValueKey('settings.lock'),
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.settingsLockSwitch),
                      value: viewModel.lockEnabled,
                      onChanged: (on) => viewModel
                          .setLock(on, reason: l10n.lockReason)
                          .ignore(),
                    ),
                    if (viewModel.lockEnabled) ...[
                      Text(l10n.settingsLockAfter),
                      const SizedBox(height: Dimens.gapSmall),
                      SegmentedButton<Duration>(
                        key: const ValueKey('settings.lockAfter'),
                        segments: [
                          for (final t in AppLockRepository.timeouts)
                            ButtonSegment(
                              value: t,
                              label: Text(
                                t == Duration.zero
                                    ? l10n.settingsLockNow
                                    : l10n.settingsLockMinutes(t.inMinutes),
                              ),
                            ),
                        ],
                        selected: {viewModel.lockTimeout},
                        onSelectionChanged: (s) =>
                            viewModel.setLockTimeout(s.single).ignore(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
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
                  if (viewModel.diagnosticsAvailable)
                    ListTile(
                      key: const ValueKey('settings.diagnostics'),
                      contentPadding: EdgeInsets.zero,
                      minTileHeight: Dimens.tapTarget,
                      title: Text(l10n.diagnosticsCreate),
                      subtitle: Text(l10n.diagnosticsHint),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => showDiagnosticsSheet(context, viewModel),
                    ),
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

/// Lets the person pick the device of the smart home tile (#192).
extension on SettingsScreen {
  Future<void> _chooseTileEntity(BuildContext context) async {
    final l10n = context.l10n;
    final entities = await viewModel.tileChoices();
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: entities.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(Dimens.gap),
                child: Text(l10n.quickTileNoDevices),
              )
            : ListView(
                shrinkWrap: true,
                children: [
                  for (final e in entities)
                    ListTile(
                      title: Text(e.name),
                      subtitle: Text(e.id),
                      onTap: () {
                        Navigator.pop(context);
                        viewModel.chooseTileEntity(e).ignore();
                      },
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

/// Why notifications could not be turned on.
String pushErrorText(AppLocalizations l10n, Exception error) => switch (error) {
  PushUnavailable(reason: PushUnavailableReason.permissionDenied) =>
    l10n.settingsPushDenied,
  PushUnavailable() => l10n.settingsPushNotInBuild,
  _ => l10n.errorMessage(error),
};

/// Shows the diagnostic report before it is shared (#197): nothing leaves
/// the device unless the person taps "Share".
@visibleForTesting
Future<void> showDiagnosticsSheet(
  BuildContext context,
  SettingsViewModel viewModel,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (context) => FractionallySizedBox(
    heightFactor: 0.85,
    child: FutureBuilder(
      future: viewModel.diagnosticReport(),
      builder: (context, snapshot) {
        final l10n = context.l10n;
        final report = snapshot.data;
        if (report == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(Dimens.gap),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.diagnosticsTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: Dimens.gapSmall),
                Text(
                  l10n.diagnosticsPreview,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: Dimens.gapSmall),
                Expanded(
                  child: SingleChildScrollView(
                    child: SelectableText(
                      report.text,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(fontFamily: 'monospace'),
                    ),
                  ),
                ),
                const SizedBox(height: Dimens.gapSmall),
                FilledButton.icon(
                  key: const ValueKey('diagnostics.share'),
                  icon: const Icon(Icons.share),
                  label: Text(l10n.diagnosticsShare),
                  onPressed: () => viewModel.shareDiagnostics(report).ignore(),
                ),
              ],
            ),
          ),
        );
      },
    ),
  ),
);

/// The addresses of the server, tried in this order (#189).
class _Addresses extends StatelessWidget {
  const _Addresses({required this.viewModel});

  final SettingsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final addresses = viewModel.addresses;
    if (addresses.isEmpty) return const SizedBox.shrink();
    return Column(
      key: const ValueKey('settings.addresses'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: Dimens.gapSmall),
        // A single address is already shown above; the list starts at two.
        if (addresses.length > 1) ...[
          Text(
            l10n.addressesTitle,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Text(
            l10n.addressesHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        for (final (i, a) in addresses.indexed)
          if (addresses.length > 1)
            ListTile(
              contentPadding: EdgeInsets.zero,
              minTileHeight: Dimens.tapTarget,
              leading: Icon(
                a == viewModel.activeAddress
                    ? Icons.check_circle_outline
                    : Icons.radio_button_unchecked,
              ),
              title: Text(a.toString()),
              subtitle: switch ((
                a == viewModel.activeAddress,
                viewModel.checkOf(a),
              )) {
                (true, _) => Text(l10n.addressInUse),
                (_, AddressCheck.unreachable) => Text(l10n.addressUnreachable),
                (_, AddressCheck.rejected) => Text(l10n.addressRejected),
                _ => null,
              },
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (i > 0)
                    IconButton(
                      tooltip: l10n.addressRaise,
                      icon: const Icon(Icons.arrow_upward),
                      onPressed: () => viewModel.raiseAddress(a).ignore(),
                    ),
                  if (addresses.length > 1)
                    IconButton(
                      tooltip: l10n.addressRemove,
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => viewModel.removeAddress(a).ignore(),
                    ),
                ],
              ),
            ),
        if (viewModel.canAddAddress)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              key: const ValueKey('settings.addAddress'),
              icon: const Icon(Icons.add),
              label: Text(l10n.addressAdd),
              onPressed: () => _add(context),
            ),
          ),
      ],
    );
  }

  Future<void> _add(BuildContext context) => showDialog<void>(
    context: context,
    builder: (_) => _AddAddressDialog(viewModel: viewModel),
  );
}

/// Asks for one more address of the server (#189). It owns its text
/// controller, so the controller lives until the closing animation ends.
class _AddAddressDialog extends StatefulWidget {
  const _AddAddressDialog({required this.viewModel});

  final SettingsViewModel viewModel;

  @override
  State<_AddAddressDialog> createState() => _AddAddressDialogState();
}

class _AddAddressDialogState extends State<_AddAddressDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final reason = await widget.viewModel.addAddress(_controller.text);
    if (!mounted) return;
    if (reason == null) {
      Navigator.pop(context);
    } else {
      setState(() => _error = fieldError(l10n, InvalidServerAddress(reason)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final material = MaterialLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.addressAdd),
      content: TextField(
        key: const ValueKey('settings.addressField'),
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.url,
        decoration: InputDecoration(
          hintText: 'https://waylight.example.org',
          errorText: _error,
        ),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(material.cancelButtonLabel),
        ),
        FilledButton(
          key: const ValueKey('settings.addressSave'),
          onPressed: _save,
          child: Text(material.okButtonLabel),
        ),
      ],
    );
  }
}

/// Reminders the phone shows by itself (#190).
class _Reminders extends StatelessWidget {
  const _Reminders({required this.viewModel});

  final SettingsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final r = viewModel.reminders;
    return SectionCard(
      title: l10n.settingsReminders,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.settingsRemindersHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (viewModel.remindersDenied)
            Padding(
              padding: const EdgeInsets.only(top: Dimens.gapSmall),
              child: Text(
                l10n.settingsReminderDenied,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          SwitchListTile(
            key: const ValueKey('settings.reminderTodos'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.settingsReminderTodos),
            value: r.todos,
            onChanged: (v) =>
                viewModel.setReminders(r.copyWith(todos: v)).ignore(),
          ),
          SwitchListTile(
            key: const ValueKey('settings.reminderBirthdays'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.settingsReminderBirthdays),
            value: r.birthdays,
            onChanged: (v) =>
                viewModel.setReminders(r.copyWith(birthdays: v)).ignore(),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.settingsReminderEvents),
            trailing: DropdownButton<int>(
              key: const ValueKey('settings.reminderEvents'),
              value: r.eventMinutes,
              items: [
                DropdownMenuItem(
                  value: 0,
                  child: Text(l10n.settingsReminderEventsOff),
                ),
                for (final m in ReminderSettings.eventChoices)
                  DropdownMenuItem(
                    value: m,
                    child: Text(l10n.settingsReminderMinutes(m)),
                  ),
              ],
              onChanged: (v) => viewModel
                  .setReminders(r.copyWith(eventMinutes: v ?? 0))
                  .ignore(),
            ),
          ),
        ],
      ),
    );
  }
}
