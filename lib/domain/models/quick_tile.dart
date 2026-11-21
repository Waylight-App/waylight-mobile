import 'package:waylight_mobile/domain/models/actions.dart';
import 'package:waylight_mobile/domain/models/presence.dart';

/// The tiles the app offers in Android's Quick Settings (#192).
enum QuickTileKind {
  /// Opens the quick capture of a to-do.
  capture,

  /// Switches the one smart home entity the user chose.
  smartHome,

  /// Cycles the signed-in account's presence status.
  status;

  /// The kind of a native [name], if it is one of these.
  static QuickTileKind? parse(String? name) {
    for (final k in values) {
      if (k.name == name) return k;
    }
    return null;
  }
}

/// What a Quick Settings tile shows, already in the app's language, so the
/// native tile only draws it (as with the home screen widgets, ADR 0009).
final class QuickTileState {
  /// Creates the state.
  const QuickTileState({
    required this.label,
    required this.subtitle,
    required this.active,
  });

  /// The main line, e.g. the entity's name.
  final String label;

  /// The second line, e.g. "On" or "Office".
  final String subtitle;

  /// Whether the tile is drawn switched on.
  final bool active;

  /// The JSON the native tile reads.
  Map<String, Object?> toJson() => {
    'label': label,
    'subtitle': subtitle,
    'active': active,
  };
}

/// The smart home entity a tile switches (#192).
final class QuickTileEntity {
  /// Creates the choice.
  const QuickTileEntity({required this.id, required this.name});

  /// The entity id, such as `light.desk_lamp`.
  final String id;

  /// The friendly name at the time it was chosen.
  final String name;
}

/// Formats the tiles in the app's language.
abstract interface class QuickTileFormatter {
  /// The smart home tile for [entity].
  QuickTileState smartHome(SmartEntity entity);

  /// The status tile for [status].
  QuickTileState status(PresenceStatus status);

  /// A tile of [kind] whose server could not be reached; [label] keeps the
  /// name it showed.
  QuickTileState unreachable(QuickTileKind kind, String label);
}

/// The status a tap on the status tile sets: office, home, away, office …
PresenceStatus nextStatus(PresenceStatus current) => switch (current) {
  PresenceStatus.office => PresenceStatus.home,
  PresenceStatus.home => PresenceStatus.away,
  PresenceStatus.away || PresenceStatus.none => PresenceStatus.office,
};

/// Whether a tile may offer [entity]: only what the owner allowed to switch
/// or press.
bool switchableOnTile(SmartEntity entity) => entity.action != EntityAction.none;
