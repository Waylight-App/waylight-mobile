/// What a Waylight server says about itself and the caller.
final class ServerStatus {
  /// Creates a status.
  const ServerStatus({
    required this.setupRequired,
    this.username = '',
    this.role = '',
  });

  /// Whether the server has no account yet and must be set up in a browser
  /// first; the app does not run the setup.
  final bool setupRequired;

  /// The signed-in account's name; empty for the owner or when signed out.
  final String username;

  /// The signed-in account's role, e.g. `owner` or `member`; empty when
  /// signed out.
  final String role;

  @override
  bool operator ==(Object other) =>
      other is ServerStatus &&
      other.setupRequired == setupRequired &&
      other.username == username &&
      other.role == role;

  @override
  int get hashCode => Object.hash(setupRequired, username, role);

  @override
  String toString() =>
      'ServerStatus(setupRequired: $setupRequired, role: $role)';
}
