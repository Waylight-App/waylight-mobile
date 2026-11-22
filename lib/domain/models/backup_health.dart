/// The traffic light of the server's own backups (`GET /api/backups/status`).
enum BackupHealth {
  /// The newest backup is recent and the off-site copy, if any, worked.
  ok,

  /// The newest backup is older than expected, there is none yet or the
  /// off-site upload failed.
  stale,

  /// The latest backup attempt failed and no backup followed it.
  failed,
}

/// How well the server's backups are doing.
final class BackupStatus {
  /// Creates the status.
  const BackupStatus({
    required this.health,
    this.lastBackupAt,
    this.error = '',
    this.offsiteError = '',
  });

  /// The traffic light.
  final BackupHealth health;

  /// When the newest backup was made; `null` when there is none.
  final DateTime? lastBackupAt;

  /// Why the latest attempt failed; empty unless [health] is failed.
  final String error;

  /// Why the off-site upload failed; empty when it did not.
  final String offsiteError;
}
