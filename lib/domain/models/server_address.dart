import 'package:waylight_mobile/utils/result.dart';

/// Why a text is not a valid server address.
enum InvalidServerAddressReason {
  /// Nothing was entered.
  empty,

  /// The scheme is neither `http` nor `https`.
  unsupportedScheme,

  /// The text has no host or cannot be parsed.
  malformed,

  /// The address contains a user name, password, query or fragment.
  unexpectedParts,
}

/// The text the user entered is not a valid [ServerAddress].
final class InvalidServerAddress implements Exception {
  /// Creates the exception for [reason].
  const InvalidServerAddress(this.reason);

  /// Why the address was rejected.
  final InvalidServerAddressReason reason;

  @override
  String toString() => 'InvalidServerAddress(${reason.name})';
}

/// The base address of a Waylight server, such as
/// `https://home.example.org/waylight`.
///
/// Always absolute, `http` or `https`, without trailing slash, credentials,
/// query or fragment. Create it with [ServerAddress.parse].
final class ServerAddress {
  const ServerAddress._(this.uri);

  /// The normalised base URI.
  final Uri uri;

  /// Parses what a user typed into a server address.
  ///
  /// Surrounding whitespace and trailing slashes are removed. Without a
  /// scheme, `https://` is assumed: plain HTTP has to be chosen explicitly.
  static Result<ServerAddress> parse(String input) {
    final text = input.trim();
    if (text.isEmpty) return _invalid(InvalidServerAddressReason.empty);

    final withScheme = text.contains('://') ? text : 'https://$text';
    final uri = Uri.tryParse(withScheme);
    if (uri == null || uri.host.isEmpty) {
      return _invalid(InvalidServerAddressReason.malformed);
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return _invalid(InvalidServerAddressReason.unsupportedScheme);
    }
    if (uri.userInfo.isNotEmpty || uri.hasQuery || uri.hasFragment) {
      return _invalid(InvalidServerAddressReason.unexpectedParts);
    }

    final path = uri.path.replaceFirst(RegExp(r'/+$'), '');
    return Result.ok(ServerAddress._(uri.replace(path: path)));
  }

  static Result<ServerAddress> _invalid(InvalidServerAddressReason reason) =>
      Result.error(InvalidServerAddress(reason));

  /// Whether requests are encrypted with TLS.
  bool get isSecure => uri.scheme == 'https';

  /// The URI of [path] on this server, e.g. `resolve('/api/auth/status')`.
  Uri resolve(String path) => uri.replace(path: '${uri.path}$path');

  @override
  bool operator ==(Object other) => other is ServerAddress && other.uri == uri;

  @override
  int get hashCode => uri.hashCode;

  @override
  String toString() => uri.toString();
}
