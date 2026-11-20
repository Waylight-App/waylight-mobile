/// One record of the app's log as it is kept on the device (#197).
final class LogEntry {
  /// Creates the entry.
  const LogEntry({
    required this.time,
    required this.level,
    required this.logger,
    required this.message,
  });

  /// When it was logged.
  final DateTime time;

  /// The level, e.g. "WARNING".
  final String level;

  /// The logger's name, e.g. "ApiClient".
  final String logger;

  /// The message, already redacted.
  final String message;

  /// One line of the report.
  String get line =>
      '${time.toUtc().toIso8601String()} $level $logger: $message';
}

/// What a diagnostic report says (#197). It contains no address, account
/// name or credential.
final class DiagnosticReport {
  /// Creates the report.
  const DiagnosticReport({
    required this.appVersion,
    required this.device,
    required this.serverVersion,
    required this.modules,
    required this.connection,
    required this.log,
  });

  /// Version of the app.
  final String appVersion;

  /// Operating system and device model.
  final String device;

  /// Version of the connected server, or "unknown".
  final String serverVersion;

  /// Modules switched on on the server.
  final List<String> modules;

  /// How the server is reached: "https", "http" or "none".
  final String connection;

  /// The last log records, oldest first.
  final List<LogEntry> log;

  /// The report as plain text for a bug report.
  String get text => [
    'Waylight app ${appVersion.isEmpty ? 'unknown' : appVersion}',
    'Device: $device',
    'Server: $serverVersion',
    'Connection: $connection',
    'Modules: ${modules.isEmpty ? '-' : modules.join(', ')}',
    '',
    'Log (${log.length}):',
    for (final e in log) e.line,
  ].join('\n');
}
