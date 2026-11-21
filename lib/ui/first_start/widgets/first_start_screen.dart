import 'package:material_ui/material_ui.dart';
import 'package:waylight_mobile/data/repositories/push/push_repository.dart';
import 'package:waylight_mobile/domain/models/appearance.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/ui/core/address_errors.dart';
import 'package:waylight_mobile/ui/core/error_messages.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/first_start/view_models/first_start_view_model.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The questions of the first start on a server (#287): one per screen,
/// each one skippable with "Next", all of them with "Skip all".
class FirstStartScreen extends StatelessWidget {
  /// Creates the screen for [viewModel].
  const FirstStartScreen({required this.viewModel, super.key});

  /// The state and actions of the first start.
  final FirstStartViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.firstStartTitle),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            key: const ValueKey('firstStart.skipAll'),
            onPressed: () => viewModel.finish().ignore(),
            child: Text(l10n.firstStartSkipAll),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) {
          if (viewModel.steps.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LinearProgressIndicator(
                value: (viewModel.index + 1) / viewModel.steps.length,
              ),
              Expanded(
                child: _Page(
                  // A new key per question resets the scroll position and
                  // lets TalkBack announce the new title.
                  key: ValueKey(viewModel.step),
                  viewModel: viewModel,
                ),
              ),
              _Buttons(viewModel: viewModel),
            ],
          );
        },
      ),
    );
  }
}

/// The current question with its title and the note on the settings.
class _Page extends StatelessWidget {
  const _Page({required this.viewModel, super.key});

  final FirstStartViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final (title, text, content) = switch (viewModel.step) {
      FirstStartStep.notifications => (
        l10n.settingsNotifications,
        l10n.firstStartNotificationsText,
        _Notifications(viewModel: viewModel),
      ),
      FirstStartStep.lock => (
        l10n.settingsLock,
        l10n.firstStartLockText,
        _Lock(viewModel: viewModel),
      ),
      FirstStartStep.addresses => (
        l10n.firstStartAddressesTitle,
        l10n.firstStartAddressesText,
        _Addresses(viewModel: viewModel),
      ),
      FirstStartStep.look => (
        l10n.settingsAppearance,
        l10n.firstStartLookText,
        _Look(viewModel: viewModel),
      ),
    };
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Dimens.maxFormWidth),
        child: ListView(
          padding: const EdgeInsets.all(Dimens.gap),
          children: [
            Text(
              l10n.firstStartProgress(
                viewModel.index + 1,
                viewModel.steps.length,
              ),
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Dimens.gapSmall),
            Semantics(
              header: true,
              liveRegion: true,
              child: Text(title, style: theme.textTheme.headlineSmall),
            ),
            const SizedBox(height: Dimens.gapSmall),
            Text(text, style: theme.textTheme.bodyLarge),
            const SizedBox(height: Dimens.gap),
            content,
            const SizedBox(height: Dimens.gapLarge),
            Text(
              l10n.firstStartLater,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Back and Next (or Done on the last question).
class _Buttons extends StatelessWidget {
  const _Buttons({required this.viewModel});

  final FirstStartViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(Dimens.gap),
        child: Row(
          children: [
            if (viewModel.index > 0)
              TextButton(
                key: const ValueKey('firstStart.back'),
                onPressed: viewModel.back,
                child: Text(l10n.firstStartBack),
              ),
            const Spacer(),
            FilledButton(
              key: const ValueKey('firstStart.next'),
              onPressed: () => viewModel.next().ignore(),
              child: Text(
                viewModel.isLast ? l10n.firstStartDone : l10n.firstStartNext,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Notifications extends StatelessWidget {
  const _Notifications({required this.viewModel});

  final FirstStartViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListenableBuilder(
      listenable: viewModel.setPush,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            key: const ValueKey('firstStart.push'),
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
              key: const ValueKey('firstStart.battery'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.battery_alert_outlined),
              title: Text(l10n.settingsPushBattery),
              trailing: TextButton(
                onPressed: () => viewModel.allowInBackground().ignore(),
                child: Text(l10n.settingsPushBatteryAction),
              ),
            ),
          if (viewModel.setPush.result case Error(:final error))
            Text(switch (error) {
              PushUnavailable(reason: PushUnavailableReason.permissionDenied) =>
                l10n.settingsPushDenied,
              PushUnavailable() => l10n.settingsPushNotInBuild,
              _ => l10n.errorMessage(error),
            }, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
      ),
    );
  }
}

class _Lock extends StatelessWidget {
  const _Lock({required this.viewModel});

  final FirstStartViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SwitchListTile(
      key: const ValueKey('firstStart.lock'),
      contentPadding: EdgeInsets.zero,
      title: Text(l10n.settingsLockSwitch),
      value: viewModel.lockEnabled,
      onChanged: (on) =>
          viewModel.setLock(on, reason: l10n.lockReason).ignore(),
    );
  }
}

/// The addresses of the server and a field for another one.
class _Addresses extends StatefulWidget {
  const _Addresses({required this.viewModel});

  final FirstStartViewModel viewModel;

  @override
  State<_Addresses> createState() => _AddressesState();
}

class _AddressesState extends State<_Addresses> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final l10n = context.l10n;
    final reason = await widget.viewModel.addAddress(_controller.text);
    if (!mounted) return;
    setState(() {
      _error = reason == null
          ? null
          : fieldError(l10n, InvalidServerAddress(reason));
      if (reason == null) _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final viewModel = widget.viewModel;
    final addresses = viewModel.addresses;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final a in addresses)
          ListTile(
            contentPadding: EdgeInsets.zero,
            minTileHeight: Dimens.tapTarget,
            leading: const Icon(Icons.dns_outlined),
            title: Text(a.toString()),
            trailing: addresses.length > 1
                ? IconButton(
                    tooltip: l10n.addressRemove,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => viewModel.removeAddress(a).ignore(),
                  )
                : null,
          ),
        if (viewModel.canAddAddress) ...[
          const SizedBox(height: Dimens.gapSmall),
          TextField(
            key: const ValueKey('firstStart.addressField'),
            controller: _controller,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              labelText: l10n.addressAdd,
              hintText: 'https://waylight.example.org',
              errorText: _error,
            ),
            onSubmitted: (_) => _add().ignore(),
          ),
          const SizedBox(height: Dimens.gapSmall),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton.icon(
              key: const ValueKey('firstStart.addAddress'),
              icon: const Icon(Icons.add),
              label: Text(l10n.addressAdd),
              onPressed: () => _add().ignore(),
            ),
          ),
        ],
      ],
    );
  }
}

class _Look extends StatelessWidget {
  const _Look({required this.viewModel});

  final FirstStartViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.settingsTheme),
        const SizedBox(height: Dimens.gapSmall),
        SegmentedButton<ThemeChoice>(
          key: const ValueKey('firstStart.theme'),
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
          selected: {viewModel.theme},
          onSelectionChanged: (s) => viewModel.setTheme(s.single),
        ),
        if (viewModel.wallpaperAvailable) ...[
          const SizedBox(height: Dimens.gap),
          Text(l10n.settingsColours),
          const SizedBox(height: Dimens.gapSmall),
          SegmentedButton<bool>(
            key: const ValueKey('firstStart.colours'),
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
      ],
    );
  }
}
