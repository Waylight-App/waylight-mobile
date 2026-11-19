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

  /// Plain `http://` to an address outside the private network (ADR 0006).
  insecure,
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

    if (uri.scheme == 'http' && !isPrivateHost(uri.host)) {
      return _invalid(InvalidServerAddressReason.insecure);
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

/// Whether [host] is in a private network, where plain HTTP is allowed
/// (ADR 0006): loopback, RFC 1918 and link-local IPv4, IPv6 unique local
/// and link-local addresses, `localhost`, `.local` (mDNS) and `.home.arpa`.
bool isPrivateHost(String host) {
  final name = host.toLowerCase();
  if (name == 'localhost' ||
      name.endsWith('.local') ||
      name.endsWith('.home.arpa')) {
    return true;
  }
  final v4 = RegExp(r'^(\d{1,3})\.(\d{1,3})\.\d{1,3}\.\d{1,3}$')
      .firstMatch(name);
  if (v4 != null) {
    final a = int.parse(v4.group(1)!);
    final b = int.parse(v4.group(2)!);
    return a == 10 ||
        a == 127 ||
        (a == 172 && b >= 16 && b <= 31) ||
        (a == 192 && b == 168) ||
        (a == 169 && b == 254);
  }
  if (name.contains(':')) {
    // Uri keeps IPv6 hosts without brackets, e.g. fd00::1.
    if (name == '::1') return true;
    final first = int.tryParse(name.split(':').first, radix: 16);
    if (first == null) return false;
    return (first & 0xfe00) == 0xfc00 || (first & 0xffc0) == 0xfe80;
  }
  return false;
}
