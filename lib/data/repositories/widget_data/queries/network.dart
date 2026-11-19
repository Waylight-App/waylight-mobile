import 'package:waylight_mobile/data/repositories/widget_data/queries/json.dart';
import 'package:waylight_mobile/data/repositories/widget_data/widget_data_repository.dart';
import 'package:waylight_mobile/domain/models/network.dart';

/// `GET /api/speedtest/results`.
const speedtestQuery = WidgetQuery<SpeedtestResults>(
  '/api/speedtest/results',
  parseSpeedtest,
);

/// `GET /api/wireguard/peers`.
const wireguardQuery = WidgetQuery<List<WireguardPeer>>(
  '/api/wireguard/peers',
  parseWireguard,
);

/// `GET /api/fritzbox/status`.
const fritzboxQuery = WidgetQuery<FritzboxStatus>(
  '/api/fritzbox/status',
  parseFritzbox,
);

/// `GET /api/fritzbox/calls`.
const callsQuery = WidgetQuery<List<PhoneCall>>(
  '/api/fritzbox/calls',
  parseCalls,
);

/// `GET /api/adguard/stats`.
const dnsFilterQuery = WidgetQuery<DnsFilterStats>(
  '/api/adguard/stats',
  parseDnsFilter,
);

SpeedtestResult? _result(Object? r) {
  if (r case {
    'at': final String at,
    'downloadMbps': final num down,
    'uploadMbps': final num up,
    'pingMs': final num ping,
  }) {
    final time = DateTime.tryParse(at);
    if (time == null) return null;
    return SpeedtestResult(
      at: time,
      downloadMbps: down.toDouble(),
      uploadMbps: up.toDouble(),
      pingMs: ping.toDouble(),
    );
  }
  return null;
}

/// Maps `GET /api/speedtest/results`.
SpeedtestResults? parseSpeedtest(Object? json) {
  if (json is! Map<String, Object?>) return null;
  final history = listOf<SpeedtestResult>(
    json['history'] ?? const <Object?>[],
    _result,
  );
  if (history == null) return null;
  return SpeedtestResults(latest: _result(json['latest']), history: history);
}

/// Maps `GET /api/wireguard/peers`.
List<WireguardPeer>? parseWireguard(Object? json) {
  if (json case {'peers': final Object? peers}) {
    return listOf<WireguardPeer>(peers, (p) {
      if (p case {'publicKey': final String key}) {
        final name = p['name'];
        return WireguardPeer(
          name: name is String && name.isNotEmpty
              ? name
              : '${key.substring(0, key.length.clamp(0, 8))}…',
          online: p['online'] == true,
          latestHandshake: asDateTime(p['latestHandshake']),
          receivedBytes: (p['receivedBytes'] as num?)?.toInt() ?? 0,
          sentBytes: (p['sentBytes'] as num?)?.toInt() ?? 0,
        );
      }
      return null;
    });
  }
  return null;
}

/// Maps `GET /api/fritzbox/status`.
FritzboxStatus? parseFritzbox(Object? json) {
  if (json case {
    'model': final String model,
    'wan': final Map<String, Object?> wan,
  }) {
    final known = wan['throughputKnown'] == true;
    return FritzboxStatus(
      model: model,
      connected: wan['connected'] == true,
      externalIp: switch (wan['externalIp']) {
        final String ip => ip,
        _ => '',
      },
      uptime: switch (wan['uptimeSeconds']) {
        final num s => Duration(seconds: s.toInt()),
        _ => null,
      },
      downstreamPercent: known ? asDouble(wan['downstreamPercent']) : null,
      upstreamPercent: known ? asDouble(wan['upstreamPercent']) : null,
    );
  }
  return null;
}

/// Maps `GET /api/fritzbox/calls`.
List<PhoneCall>? parseCalls(Object? json) {
  if (json case {'calls': final Object? calls}) {
    return listOf<PhoneCall>(calls, (c) {
      if (c case {
        'type': final String type,
        'number': final String number,
        'at': final String at,
      }) {
        final time = DateTime.tryParse(at);
        if (time == null) return null;
        return PhoneCall(
          type: switch (type) {
            'missed' => CallType.missed,
            'outgoing' => CallType.outgoing,
            'rejected' => CallType.rejected,
            _ => CallType.incoming,
          },
          number: number,
          at: time,
          name: switch (c['name']) {
            final String n => n,
            _ => '',
          },
          durationMinutes: (c['durationMinutes'] as num?)?.toInt() ?? 0,
        );
      }
      return null;
    });
  }
  return null;
}

/// Maps `GET /api/adguard/stats`.
DnsFilterStats? parseDnsFilter(Object? json) {
  if (json case {
    'queries': final num queries,
    'blocked': final num blocked,
    'blockedPercent': final num percent,
  }) {
    return DnsFilterStats(
      queries: queries.toInt(),
      blocked: blocked.toInt(),
      blockedPercent: percent.toDouble(),
      protectionEnabled: json['protectionEnabled'] == true,
      topBlocked: [
        if (json['topBlocked'] case final List<Object?> top)
          for (final t in top)
            if (t case {'domain': final String d, 'count': final num n})
              (d, n.toInt()),
      ],
    );
  }
  return null;
}
