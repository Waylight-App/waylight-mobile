/// What a Waylight server says about itself and the caller.
final class ServerStatus {
  /// Creates a status.
  const ServerStatus({
    required this.setupRequired,
    this.username = '',
    this.role = '',
    this.demo = false,
    this.demoPassword = '',
  });

  /// Whether the server has no account yet and must be set up in a browser
  /// first; the app does not run the setup.
  final bool setupRequired;

  /// The signed-in account's name; empty for the owner or when signed out.
  final String username;

  /// The signed-in account's role, e.g. `owner` or `member`; empty when
  /// signed out.
  final String role;

  /// Whether this is a public demo whose data is reset regularly.
  final bool demo;

  /// The public password of the demo; empty elsewhere.
  final String demoPassword;

  @override
  bool operator ==(Object other) =>
      other is ServerStatus &&
      other.setupRequired == setupRequired &&
      other.username == username &&
      other.role == role &&
      other.demo == demo &&
      other.demoPassword == demoPassword;

  @override
  int get hashCode =>
      Object.hash(setupRequired, username, role, demo, demoPassword);

  @override
  String toString() =>
      'ServerStatus(setupRequired: $setupRequired, role: $role)';
}
