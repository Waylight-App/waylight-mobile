import 'package:waylight_mobile/domain/models/server_address.dart';

/// Where requests to a server actually go (#189).
///
/// A server keeps the address it was connected with as its identity:
/// sessions, the offline copy and push registrations are keyed by it. When
/// another of its addresses is in use (the home network instead of the
/// public domain, say), the `ApiClient` sends requests there; everything
/// above the transport keeps using the identity.
final class AddressRoutes {
  final Map<ServerAddress, ServerAddress> _via = {};

  /// Sends requests to [server] through [via]; `null` or [server] itself
  /// removes the route.
  void route(ServerAddress server, ServerAddress? via) {
    if (via == null || via == server) {
      _via.remove(server);
    } else {
      _via[server] = via;
    }
  }

  /// Removes every route, e.g. when the server is forgotten.
  void clear() => _via.clear();

  /// The address [uri] is sent to: the same path under the address in use.
  Uri rewrite(Uri uri) {
    for (final MapEntry(key: server, value: via) in _via.entries) {
      final base = server.uri;
      if (uri.origin != base.origin || !uri.path.startsWith(base.path)) {
        continue;
      }
      final rest = uri.path.substring(base.path.length);
      return uri.replace(
        scheme: via.uri.scheme,
        host: via.uri.host,
        port: via.uri.port,
        path: '${via.uri.path}$rest',
      );
    }
    return uri;
  }
}
