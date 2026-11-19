/// The state of the Waylight host (`GET /api/system`).
final class SystemStatus {
  /// Creates the status.
  const SystemStatus({
    required this.hostname,
    required this.cpuPercent,
    required this.memoryPercent,
    required this.swapPercent,
    required this.disks,
    required this.uptime,
    this.load1,
    this.temperature,
  });

  /// The host name.
  final String hostname;

  /// CPU usage in percent.
  final double cpuPercent;

  /// Memory usage in percent.
  final double memoryPercent;

  /// Swap usage in percent; 0 without swap.
  final double swapPercent;

  /// The monitored disks.
  final List<DiskUsage> disks;

  /// Time since the host started.
  final Duration uptime;

  /// The load average of the last minute, if the host reports it.
  final double? load1;

  /// The CPU temperature in °C, if the host reports it.
  final double? temperature;
}

/// One disk of [SystemStatus].
final class DiskUsage {
  /// Creates the usage.
  const DiskUsage({
    required this.label,
    required this.percent,
    required this.usedBytes,
    required this.totalBytes,
    this.daysUntilFull,
  });

  /// The label, such as "Data".
  final String label;

  /// Used space in percent.
  final double percent;

  /// Used bytes.
  final int usedBytes;

  /// Size in bytes.
  final int totalBytes;

  /// Days until the disk is full at the current rate, when the server could
  /// forecast it.
  final int? daysUntilFull;
}

/// Whether a monitored service answers (`GET /api/services`).
enum ServiceState {
  /// The service answers.
  online,

  /// The service does not answer.
  offline,

  /// Not checked yet.
  unknown,
}

/// A monitored service.
final class MonitoredService {
  /// Creates the service.
  const MonitoredService({
    required this.id,
    required this.name,
    required this.state,
    this.url,
    this.icon = '',
    this.latencyMs,
    this.certExpiresSoon = false,
  });

  /// The server's id.
  final String id;

  /// The name of the tile.
  final String name;

  /// The state of the last check.
  final ServiceState state;

  /// The address the tile opens.
  final Uri? url;

  /// An emoji, or empty.
  final String icon;

  /// The response time of the last check, if it answered.
  final int? latencyMs;

  /// Whether its TLS certificate expires soon.
  final bool certExpiresSoon;
}

/// The state of a monitored backup or job (`GET /api/backup-status/sources`).
enum BackupState {
  /// The last run succeeded in time.
  ok,

  /// No run within the expected time.
  overdue,

  /// The last run failed.
  failed,

  /// No run reported yet.
  waiting,
}

/// A backup or job that reports to Waylight.
final class BackupSource {
  /// Creates the source.
  const BackupSource({
    required this.name,
    required this.state,
    this.lastSuccessAt,
    this.message = '',
  });

  /// The name.
  final String name;

  /// The current state.
  final BackupState state;

  /// The last successful run.
  final DateTime? lastSuccessAt;

  /// The message of the last report, such as an error.
  final String message;
}
