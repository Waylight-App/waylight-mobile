/// Results of the Speedtest Tracker (`GET /api/speedtest/results`).
final class SpeedtestResults {
  /// Creates the results.
  const SpeedtestResults({required this.latest, required this.history});

  /// The newest result, if any.
  final SpeedtestResult? latest;

  /// Earlier results, oldest first.
  final List<SpeedtestResult> history;
}

/// One speed test.
final class SpeedtestResult {
  /// Creates the result.
  const SpeedtestResult({
    required this.at,
    required this.downloadMbps,
    required this.uploadMbps,
    required this.pingMs,
  });

  /// When it ran.
  final DateTime at;

  /// The download speed in Mbit/s.
  final double downloadMbps;

  /// The upload speed in Mbit/s.
  final double uploadMbps;

  /// The ping in ms.
  final double pingMs;
}

/// A WireGuard peer (`GET /api/wireguard/peers`).
final class WireguardPeer {
  /// Creates the peer.
  const WireguardPeer({
    required this.name,
    required this.online,
    this.latestHandshake,
    this.receivedBytes = 0,
    this.sentBytes = 0,
  });

  /// The name given in Waylight, or the start of the key.
  final String name;

  /// Whether it shook hands recently.
  final bool online;

  /// The last handshake.
  final DateTime? latestHandshake;

  /// Bytes received since the interface started.
  final int receivedBytes;

  /// Bytes sent since the interface started.
  final int sentBytes;
}

/// The internet connection of a FRITZ!Box (`GET /api/fritzbox/status`).
final class FritzboxStatus {
  /// Creates the status.
  const FritzboxStatus({
    required this.model,
    required this.connected,
    this.externalIp = '',
    this.uptime,
    this.downstreamPercent,
    this.upstreamPercent,
  });

  /// The box model.
  final String model;

  /// Whether the internet connection is up.
  final bool connected;

  /// The public IP address.
  final String externalIp;

  /// Time since the connection was made.
  final Duration? uptime;

  /// Current use of the downstream in percent, if the box reports it.
  final double? downstreamPercent;

  /// Current use of the upstream in percent, if the box reports it.
  final double? upstreamPercent;
}

/// The kind of a call.
enum CallType {
  /// Answered call from outside.
  incoming,

  /// Call that was not answered.
  missed,

  /// Call to outside.
  outgoing,

  /// Call that was turned down.
  rejected,
}

/// A call of the FRITZ!Box call list (`GET /api/fritzbox/calls`).
final class PhoneCall {
  /// Creates the call.
  const PhoneCall({
    required this.type,
    required this.number,
    required this.at,
    this.name = '',
    this.durationMinutes = 0,
  });

  /// The kind of call.
  final CallType type;

  /// The other number.
  final String number;

  /// The name from the phone book, or empty.
  final String name;

  /// When it rang.
  final DateTime at;

  /// How long it took.
  final int durationMinutes;
}

/// Statistics of AdGuard Home or Pi-hole (`GET /api/adguard/stats`).
final class DnsFilterStats {
  /// Creates the statistics.
  const DnsFilterStats({
    required this.queries,
    required this.blocked,
    required this.blockedPercent,
    required this.protectionEnabled,
    this.topBlocked = const [],
  });

  /// Queries in the last 24 hours.
  final int queries;

  /// Blocked queries in the last 24 hours.
  final int blocked;

  /// The blocked share in percent.
  final double blockedPercent;

  /// Whether blocking is on.
  final bool protectionEnabled;

  /// The most blocked domains with their counts.
  final List<(String, int)> topBlocked;
}
