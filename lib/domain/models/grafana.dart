/// A firing or pending alert of Grafana Alerting (#165).
final class GrafanaAlert {
  /// Creates the alert.
  const GrafanaAlert({
    required this.name,
    required this.firing,
    this.summary = '',
    this.severity = '',
    this.since,
  });

  /// The alert rule's name.
  final String name;

  /// Firing; otherwise pending.
  final bool firing;

  /// The summary or description.
  final String summary;

  /// The severity label, may be empty.
  final String severity;

  /// Since when the alert is active.
  final DateTime? since;
}

/// The alerts with the link to Grafana's alert list.
final class GrafanaAlerts {
  /// Creates the list.
  const GrafanaAlerts({required this.alerts, this.url});

  /// Firing first, then pending.
  final List<GrafanaAlert> alerts;

  /// The alert list in Grafana.
  final Uri? url;
}
