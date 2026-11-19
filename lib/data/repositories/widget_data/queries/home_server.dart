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
