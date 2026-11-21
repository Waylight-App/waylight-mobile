import 'package:waylight_mobile/domain/models/actions.dart';
import 'package:waylight_mobile/domain/models/compact_state.dart';
import 'package:waylight_mobile/domain/models/presence.dart';
import 'package:waylight_mobile/domain/models/quick_tile.dart';
import 'package:waylight_mobile/l10n/generated/app_localizations.dart';
import 'package:waylight_mobile/ui/core/compact_texts.dart';

/// Formats the Quick Settings tiles in the app's language (#192).
class QuickTileTexts implements QuickTileFormatter {
  /// Creates the formatter for [l10n].
  const QuickTileTexts(this.l10n);

  /// The texts in the app's language.
  final AppLocalizations l10n;

  @override
  QuickTileState smartHome(SmartEntity entity) => QuickTileState(
    label: entity.name,
    subtitle: switch (entity.action) {
      EntityAction.press => l10n.smartHomeRun,
      _ => entity.isOn ? l10n.quickTileOn : l10n.quickTileOff,
    },
    active: entity.action == EntityAction.toggle && entity.isOn,
  );

  @override
  QuickTileState status(PresenceStatus status, {CompactState? compact}) =>
      QuickTileState(
        label: l10n.quickTileStatus,
        subtitle: compact != null
            ? compactTextOf(l10n, compact.title)
            : switch (status) {
                PresenceStatus.office => l10n.presenceOffice,
                PresenceStatus.home => l10n.presenceHome,
                PresenceStatus.away => l10n.presenceAway,
                PresenceStatus.none => l10n.presenceNone,
              },
        active: status != PresenceStatus.none,
      );

  @override
  QuickTileState unreachable(QuickTileKind kind, String label) =>
      QuickTileState(
        label: switch (kind) {
          QuickTileKind.status => l10n.quickTileStatus,
          _ => label.isEmpty ? l10n.smartHomeTitle : label,
        },
        subtitle: l10n.quickTileUnreachable,
        active: false,
      );
}
