/// What a Waylight server says about itself before anyone signs in.
final class ServerStatus {
  /// Creates a status.
  const ServerStatus({required this.setupRequired});

  /// Whether the server has no account yet and must be set up in a browser
  /// first; the app does not run the setup.
  final bool setupRequired;

  @override
  bool operator ==(Object other) =>
      other is ServerStatus && other.setupRequired == setupRequired;

  @override
  int get hashCode => setupRequired.hashCode;

  @override
  String toString() => 'ServerStatus(setupRequired: $setupRequired)';
}
