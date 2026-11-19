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
    this.canWake = false,
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

  /// Whether it has a MAC address, so it can be woken by Wake-on-LAN.
  final bool canWake;
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

/// The S.M.A.R.T. verdict of a disk (`GET /api/diskhealth`).
final class DiskHealth {
  /// Creates the verdict.
  const DiskHealth({
    required this.device,
    required this.model,
    required this.status,
    this.temperature,
    this.percentageUsed,
    this.findings = const [],
  });

  /// The device, such as `/dev/nvme0`.
  final String device;

  /// The disk model.
  final String model;

  /// "ok", "warning", "failing" or "unknown", as the server decides.
  final String status;

  /// The temperature in °C, if known.
  final int? temperature;

  /// The wear of an SSD in percent, if known.
  final int? percentageUsed;

  /// What the server noticed, as sentences.
  final List<String> findings;
}

/// The containers of the Docker host (`GET /api/docker/containers`).
final class DockerOverview {
  /// Creates the overview.
  const DockerOverview({
    required this.containers,
    required this.running,
    required this.stopped,
    required this.unhealthy,
  });

  /// The containers.
  final List<DockerContainer> containers;

  /// How many containers run.
  final int running;

  /// How many containers are stopped.
  final int stopped;

  /// How many containers report unhealthy.
  final int unhealthy;
}

/// One container.
final class DockerContainer {
  /// Creates the container.
  const DockerContainer({
    required this.name,
    required this.state,
    required this.status,
    this.health = 'none',
  });

  /// The container name.
  final String name;

  /// Docker's state, such as "running" or "exited".
  final String state;

  /// Docker's status text, such as "Up 3 days".
  final String status;

  /// "healthy", "unhealthy", "starting" or "none".
  final String health;
}

/// Nodes and guests of Proxmox VE (`GET /api/proxmox/status`).
final class ProxmoxOverview {
  /// Creates the overview.
  const ProxmoxOverview({required this.nodes, required this.guests});

  /// The cluster nodes.
  final List<ProxmoxNode> nodes;

  /// The VMs and containers.
  final List<ProxmoxGuest> guests;
}

/// A Proxmox node.
final class ProxmoxNode {
  /// Creates the node.
  const ProxmoxNode({
    required this.name,
    required this.online,
    required this.cpuPercent,
    required this.memoryPercent,
  });

  /// The node name.
  final String name;

  /// Whether it answers.
  final bool online;

  /// CPU usage in percent.
  final double cpuPercent;

  /// Memory usage in percent.
  final double memoryPercent;
}

/// A Proxmox VM or container.
final class ProxmoxGuest {
  /// Creates the guest.
  const ProxmoxGuest({
    required this.id,
    required this.name,
    required this.kind,
    required this.running,
    this.actions = false,
  });

  /// The VMID.
  final int id;

  /// The guest name.
  final String name;

  /// "qemu" or "lxc".
  final String kind;

  /// Whether it runs.
  final bool running;

  /// Whether the owner allowed starting and shutting it down.
  final bool actions;
}

/// An entry of the instance's timeline (`GET /api/timeline`).
final class TimelineEntry {
  /// Creates the entry.
  const TimelineEntry({
    required this.at,
    required this.source,
    required this.severity,
    required this.subject,
    required this.message,
  });

  /// When it happened.
  final DateTime at;

  /// Where it came from, such as "service" or "container".
  final String source;

  /// "info", "warning" or "critical".
  final String severity;

  /// What it is about.
  final String subject;

  /// What happened.
  final String message;
}
