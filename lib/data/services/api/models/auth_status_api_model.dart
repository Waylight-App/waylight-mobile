/// The JSON of `GET /api/auth/status` (schema `AuthStatus` in
/// `api/modules/auth.yaml` of the server).
final class AuthStatusApiModel {
  /// Creates the model.
  const AuthStatusApiModel({
    required this.setupRequired,
    required this.authenticated,
    this.username = '',
    this.role = '',
    this.demo = false,
    this.demoPassword = '',
  });

  /// Parses the response body; `null` if it does not match the schema, which
  /// usually means the address does not belong to a Waylight server.
  static AuthStatusApiModel? fromJson(Object? json) => switch (json) {
    {
      'setupRequired': final bool setupRequired,
      'authenticated': final bool authenticated,
    } =>
      AuthStatusApiModel(
        setupRequired: setupRequired,
        authenticated: authenticated,
        username: switch (json['username']) {
          final String u => u,
          _ => '',
        },
        role: switch (json['role']) {
          final String r => r,
          _ => '',
        },
        demo: json['demo'] == true,
        demoPassword: switch (json['demoPassword']) {
          final String p => p,
          _ => '',
        },
      ),
    _ => null,
  };

  /// Whether the server still waits for its first account.
  final bool setupRequired;

  /// Whether the request carried a valid session.
  final bool authenticated;

  /// The signed-in account's name; empty for the owner.
  final String username;

  /// The signed-in account's role; empty when signed out.
  final String role;

  /// Whether this is a public demo.
  final bool demo;

  /// The public password of the demo.
  final String demoPassword;
}
