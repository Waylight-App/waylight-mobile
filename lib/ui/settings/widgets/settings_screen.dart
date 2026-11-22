import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:waylight_mobile/domain/models/appearance.dart';
import 'package:waylight_mobile/domain/models/backup_health.dart';
import 'package:waylight_mobile/domain/models/server_status.dart';
import 'package:waylight_mobile/routing/routes.dart';
import 'package:waylight_mobile/ui/core/backup_health_texts.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/core/widgets/command_button.dart';
import 'package:waylight_mobile/ui/core/widgets/message_banner.dart';
import 'package:waylight_mobile/ui/core/widgets/rows.dart';
import 'package:waylight_mobile/ui/settings/view_models/settings_area.dart';
import 'package:waylight_mobile/ui/settings/view_models/settings_index.dart';
import 'package:waylight_mobile/ui/settings/view_models/settings_view_model.dart';
import 'package:waylight_mobile/ui/settings/widgets/settings_area_screen.dart';
import 'package:waylight_mobile/ui/settings/widgets/settings_texts.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The start page of the settings (#231): who is signed in, the search
/// (#232), one row per area with a line of status, and signing out.
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
            _SearchField(viewModel: viewModel),
            const SizedBox(height: Dimens.gap),
            if (viewModel.attentionCount > 0) ...[
              MessageBanner(
                key: const ValueKey('settings.attention'),
                kind: MessageKind.warning,
                message: l10n.attentionBadge(viewModel.attentionCount),
                action: TextButton(
                  onPressed: () => context.push(Routes.attention),
                  child: Text(l10n.settingsAttentionShow),
                ),
              ),
              const SizedBox(height: Dimens.gap),
            ],
            if (viewModel.backup case final backup?
                when viewModel.query.isEmpty) ...[
              _BackupTile(status: backup),
              const SizedBox(height: Dimens.gap),
            ],
            if (viewModel.query.trim().isNotEmpty)
              _Results(viewModel: viewModel, onOpen: _open)
            else
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (final area in SettingsArea.values)
                      if (viewModel.showsArea(area))
                        ListTile(
                          key: ValueKey('settings.area.${area.segment}'),
                          minTileHeight: Dimens.tapTarget,
                          leading: Icon(_icon(area)),
                          title: Text(areaTitle(l10n, area)),
                          subtitle: Text(areaStatus(l10n, viewModel, area)),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _open(context, area.path).ignore(),
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

  Future<void> _open(BuildContext context, String location) async {
    await context.push(location);
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

/// The backup traffic light; shown to the owner only, as the server decides.
class _BackupTile extends StatelessWidget {
  const _BackupTile({required this.status});

  final BackupStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: ListTile(
        key: const ValueKey('settings.backup'),
        minTileHeight: Dimens.tapTarget,
        leading: StatusDot(tone: status.tone, label: status.label(l10n)),
        title: Text(status.label(l10n)),
        subtitle: Text(
          status.detail(
            l10n,
            (d) => DateFormat.MMMEd(
              Localizations.localeOf(context).toLanguageTag(),
            ).add_Hm().format(d),
          ),
        ),
      ),
    );
  }
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

/// Filters the start page as the person types (#232).
class _SearchField extends StatefulWidget {
  const _SearchField({required this.viewModel});

  final SettingsViewModel viewModel;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final _controller = TextEditingController(text: widget.viewModel.query);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TextField(
      key: const ValueKey('settings.search'),
      controller: _controller,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: l10n.settingsSearch,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: widget.viewModel.query.isEmpty
            ? null
            : IconButton(
                tooltip: l10n.settingsSearchClear,
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _controller.clear();
                  widget.viewModel.search('');
                },
              ),
      ),
      onChanged: widget.viewModel.search,
    );
  }
}

/// The areas and settings that match the search.
class _Results extends StatelessWidget {
  const _Results({required this.viewModel, required this.onOpen});

  final SettingsViewModel viewModel;
  final Future<void> Function(BuildContext context, String location) onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hits = searchSettings(
      viewModel.query,
      available: viewModel.available,
      title: (item) => itemTitle(l10n, item),
      areaTitle: (area) => areaTitle(l10n, area),
    );
    if (hits.isEmpty) {
      return Text(l10n.settingsSearchEmpty(viewModel.query.trim()));
    }
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final hit in hits)
            if (viewModel.showsArea(hit.area))
              ListTile(
                key: ValueKey(
                  'settings.hit.${hit.area.segment}.${hit.item?.name ?? ''}',
                ),
                minTileHeight: Dimens.tapTarget,
                title: Text(
                  hit.item == null
                      ? areaTitle(l10n, hit.area)
                      : itemTitle(l10n, hit.item!),
                ),
                subtitle: hit.item == null
                    ? null
                    : Text(areaTitle(l10n, hit.area)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => onOpen(context, _location(hit)).ignore(),
              ),
        ],
      ),
    );
  }

  static String _location(SettingsHit hit) => Uri(
    path: hit.area.path,
    queryParameters: switch (hit.item) {
      final item? => {'focus': item.name},
      null => null,
    },
  ).toString();
}
