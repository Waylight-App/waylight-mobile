import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// A text is not the code of a setup assistant's paste.
final class InvalidPasteLink implements Exception {
  /// Creates the exception.
  const InvalidPasteLink();

  @override
  String toString() => 'InvalidPasteLink()';
}

/// The QR code the setup assistant shows for "Paste from phone":
/// `<server>/paste/<code>` (a web address a phone camera can open) or the app
/// link `waylight://paste?server=<address>&code=<code>`. The code is
/// single-use and lasts five minutes.
typedef PasteLink = ({ServerAddress server, String code});

// The codes are URL-safe random strings; anything else never came from a
// server and must not end up in a request path.
final _codePattern = RegExp(r'^[A-Za-z0-9._~-]{1,256}$');

/// Reads a scanned or opened paste link.
Result<PasteLink> parsePasteLink(String server, String code) {
  final trimmed = code.trim();
  if (server.trim().isEmpty || !_codePattern.hasMatch(trimmed)) {
    return const Result.error(InvalidPasteLink());
  }
  return switch (ServerAddress.parse(server)) {
    Ok(value: final address) => Result.ok((server: address, code: trimmed)),
    Error(:final error) => Result.error(error),
  };
}

/// Reads the text of a scanned QR code.
Result<PasteLink> parsePasteLinkText(String text) {
  final uri = Uri.tryParse(text.trim());
  if (uri == null) return const Result.error(InvalidPasteLink());
  if (uri.scheme == 'http' || uri.scheme == 'https') {
    final segments = uri.pathSegments;
    if (segments.length != 2 || segments.first != 'paste') {
      return const Result.error(InvalidPasteLink());
    }
    return parsePasteLink(uri.origin, segments.last);
  }
  if (uri.scheme != 'waylight' || uri.host != 'paste') {
    return const Result.error(InvalidPasteLink());
  }
  return parsePasteLink(
    uri.queryParameters['server'] ?? '',
    uri.queryParameters['code'] ?? '',
  );
}
