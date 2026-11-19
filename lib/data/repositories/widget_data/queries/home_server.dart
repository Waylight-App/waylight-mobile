import 'package:waylight_mobile/data/repositories/widget_data/queries/json.dart';
import 'package:waylight_mobile/data/repositories/widget_data/widget_data_repository.dart';
import 'package:waylight_mobile/domain/models/home_server.dart';

/// `GET /api/system`.
const systemQuery = WidgetQuery<SystemStatus>('/api/system', parseSystem);

/// `GET /api/services`, without hidden tiles.
const servicesQuery = WidgetQuery<List<MonitoredService>>(
  '/api/services',
  parseServices,
);

/// `GET /api/backup-status/sources`.
const backupSourcesQuery = WidgetQuery<List<BackupSource>>(
  '/api/backup-status/sources',
  parseBackupSources,
);

/// Maps `GET /api/system`; `null` if it does not match.
SystemStatus? parseSystem(Object? json) {
  if (json case {
    'hostname': final String hostname,
    'cpuPercent': final num cpu,
    'memory': {'percent': final num memory},
    'uptimeSeconds': final num uptime,
  }) {
    final disks = listOf<DiskUsage>(json['disks'] ?? const <Object?>[], (d) {
      if (d case {
        'label': final String label,
        'usage': {
          'percent': final num percent,
          'used': final num used,
          'total': final num total,
        },
      }) {
        final days = switch (d['forecast']) {
          {'status': 'ok', 'daysUntilFull': final int n} when n > 0 => n,
          _ => null,
        };
        return DiskUsage(
          label: label,
          percent: percent.toDouble(),
          usedBytes: used.toInt(),
          totalBytes: total.toInt(),
          daysUntilFull: days,
        );
      }
      return null;
    });
    if (disks == null) return null;
    final load = json['load'];
    return SystemStatus(
      hostname: hostname,
      cpuPercent: cpu.toDouble(),
      memoryPercent: memory.toDouble(),
      swapPercent: switch (json['swap']) {
        {'percent': final num p} => p.toDouble(),
        _ => 0,
      },
      disks: disks,
      uptime: Duration(seconds: uptime.toInt()),
      load1: load is List<Object?> && load.isNotEmpty
          ? asDouble(load.first)
          : null,
      temperature: asDouble(json['temperature']),
    );
  }
  return null;
}

/// Maps `GET /api/services`; hidden tiles are left out.
List<MonitoredService>? parseServices(Object? json) {
  if (json is! List<Object?>) return null;
  final visible = [
    for (final s in json)
      if (s is! Map<String, Object?> || s['hidden'] != true) s,
  ];
  return listOf<MonitoredService>(visible, (s) {
    if (s case {
      'id': final String id,
      'name': final String name,
      'state': final String state,
    }) {
      return MonitoredService(
        id: id,
        name: name,
        state: switch (state) {
          'online' => ServiceState.online,
          'offline' => ServiceState.offline,
          _ => ServiceState.unknown,
        },
        url: switch (s['url']) {
          final String u when u.isNotEmpty => Uri.tryParse(u),
          _ => null,
        },
        icon: switch (s['icon']) {
          final String i => i,
          _ => '',
        },
        latencyMs: switch (s['latencyMs']) {
          final int ms when state == 'online' => ms,
          _ => null,
        },
        certExpiresSoon: s['certExpiresSoon'] == true,
      );
    }
    return null;
  });
}

/// Maps `GET /api/backup-status/sources`.
List<BackupSource>? parseBackupSources(Object? json) =>
    listOf<BackupSource>(json, (s) {
      if (s case {'name': final String name, 'state': final String state}) {
        return BackupSource(
          name: name,
          state: switch (state) {
            'ok' => BackupState.ok,
            'overdue' => BackupState.overdue,
            'failed' => BackupState.failed,
            _ => BackupState.waiting,
          },
          lastSuccessAt: asDateTime(s['lastSuccessAt']),
          message: switch (s['lastMessage']) {
            final String m => m,
            _ => '',
          },
        );
      }
      return null;
    });

/// `GET /api/diskhealth`.
const diskHealthQuery = WidgetQuery<List<DiskHealth>>(
  '/api/diskhealth',
  parseDiskHealth,
);

/// `GET /api/docker/containers`.
const dockerQuery = WidgetQuery<DockerOverview>(
  '/api/docker/containers',
  parseDocker,
);

/// `GET /api/proxmox/status`.
const proxmoxQuery = WidgetQuery<ProxmoxOverview>(
  '/api/proxmox/status',
  parseProxmox,
);

/// `GET /api/timeline`, newest first.
const timelineQuery = WidgetQuery<List<TimelineEntry>>(
  '/api/timeline',
  parseTimeline,
);

int? _int(Object? v) => v is num ? v.toInt() : null;

double _percent(Object? used, Object? total) {
  final u = asDouble(used);
  final t = asDouble(total);
  return u == null || t == null || t == 0 ? 0 : u / t * 100;
}

/// Maps `GET /api/diskhealth`.
List<DiskHealth>? parseDiskHealth(Object? json) =>
    listOf<DiskHealth>(json, (d) {
      if (d case {
        'device': final String device,
        'model': final String model,
        'status': final String status,
      }) {
        return DiskHealth(
          device: device,
          model: model,
          status: status,
          temperature: _int(d['temperature']),
          percentageUsed: _int(d['percentageUsed']),
          findings: [
            if (d['findings'] case final List<Object?> findings)
              for (final f in findings)
                if (f case {'message': final String m} when m.isNotEmpty) m,
          ],
        );
      }
      return null;
    });

/// Maps `GET /api/docker/containers`.
DockerOverview? parseDocker(Object? json) {
  if (json case {'containers': final Object? list}) {
    final containers = listOf<DockerContainer>(list, (c) {
      if (c case {
        'name': final String name,
        'state': final String state,
        'status': final String status,
      }) {
        return DockerContainer(
          name: name,
          state: state,
          status: status,
          health: switch (c['health']) {
            final String h => h,
            _ => 'none',
          },
        );
      }
      return null;
    });
    if (containers == null) return null;
    return DockerOverview(
      containers: containers,
      running: _int(json['running']) ?? 0,
      stopped: _int(json['stopped']) ?? 0,
      unhealthy: _int(json['unhealthy']) ?? 0,
    );
  }
  return null;
}

/// Maps `GET /api/proxmox/status`.
ProxmoxOverview? parseProxmox(Object? json) {
  if (json case {
    'nodes': final Object? nodes,
    'guests': final Object? guests,
  }) {
    final n = listOf<ProxmoxNode>(nodes, (x) {
      if (x case {'name': final String name}) {
        return ProxmoxNode(
          name: name,
          online: x['online'] == true,
          cpuPercent: asDouble(x['cpuPercent']) ?? 0,
          memoryPercent: _percent(x['memUsed'], x['memTotal']),
        );
      }
      return null;
    });
    final g = listOf<ProxmoxGuest>(guests, (x) {
      if (x case {
        'id': final int id,
        'name': final String name,
        'kind': final String kind,
      }) {
        return ProxmoxGuest(
          id: id,
          name: name,
          kind: kind,
          running: x['status'] == 'running',
        );
      }
      return null;
    });
    if (n == null || g == null) return null;
    return ProxmoxOverview(nodes: n, guests: g);
  }
  return null;
}

/// Maps `GET /api/timeline`.
List<TimelineEntry>? parseTimeline(Object? json) =>
    listOf<TimelineEntry>(json, (e) {
      if (e case {
        'at': final String at,
        'source': final String source,
        'severity': final String severity,
        'subject': final String subject,
        'message': final String message,
      }) {
        final time = DateTime.tryParse(at);
        if (time == null) return null;
        return TimelineEntry(
          at: time,
          source: source,
          severity: severity,
          subject: subject,
          message: message,
        );
      }
      return null;
    });
