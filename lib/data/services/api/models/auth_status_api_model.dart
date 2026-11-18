/// The JSON of `GET /api/auth/status` (schema `AuthStatus` in
/// `api/modules/auth.yaml` of the server).
final class AuthStatusApiModel {
  /// Creates the model.
  const AuthStatusApiModel({
    required this.setupRequired,
    required this.authenticated,
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
      ),
    _ => null,
  };

  /// Whether the server still waits for its first account.
  final bool setupRequired;

  /// Whether the request carried a valid session.
  final bool authenticated;
}
