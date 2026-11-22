import 'package:waylight_mobile/domain/models/backup_health.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/widgets/rows.dart';

/// How the backup traffic light is worded and coloured, shared by the
/// backup widget and the settings start page.
extension BackupStatusTexts on BackupStatus {
  /// The colour of the light.
  Tone get tone => switch (health) {
    BackupHealth.ok => Tone.ok,
    BackupHealth.stale => Tone.warning,
    BackupHealth.failed => Tone.critical,
  };

  /// The verdict in a few words.
  String label(AppLocalizations l10n) => switch (health) {
    BackupHealth.ok => l10n.backupHealthOk,
    BackupHealth.stale => l10n.backupHealthStale,
    BackupHealth.failed => l10n.backupHealthFailed,
  };

  /// The reason or the age below the verdict; [date] formats the time of
  /// the last backup.
  String detail(AppLocalizations l10n, String Function(DateTime) date) {
    if (health == BackupHealth.failed && error.isNotEmpty) return error;
    if (offsiteError.isNotEmpty) return l10n.backupHealthOffsite(offsiteError);
    return switch (lastBackupAt) {
      final at? => l10n.backupHealthLast(date(at.toLocal())),
      null => l10n.backupHealthNone,
    };
  }
}
