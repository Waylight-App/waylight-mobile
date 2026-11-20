/// Removes what could identify a person or open an account from a log
/// message (#197): addresses, IP addresses, e-mail addresses, credentials
/// and long tokens. Applied when a message is written, so the log file
/// never holds them.
String redact(String message) {
  var out = message;
  for (final (pattern, replace) in _rules) {
    out = out.replaceAllMapped(pattern, replace);
  }
  return out;
}

final _rules = <(RegExp, String Function(Match))>[
  // Credentials in key=value or key: value form, e.g. "token=abc" or
  // "Cookie: session=…". Runs first so their values never reach the
  // other rules half-replaced.
  (
    RegExp(
      r'(authorization|cookie|set-cookie|password|passwort|token|secret|session|csrf|api[_-]?key)(\s*[:=]\s*)(bearer\s+)?[^\s,;&]+',
      caseSensitive: false,
    ),
    (m) => '${m[1]}${m[2]}<redacted>',
  ),
  (
    RegExp(r'bearer\s+[A-Za-z0-9._~+/=-]+', caseSensitive: false),
    (_) => 'Bearer <redacted>',
  ),
  // Addresses with a scheme, including user info, host, port, path and query.
  (
    RegExp(r'\b[a-z][a-z0-9+.-]*://\S+', caseSensitive: false),
    (_) => '<address>',
  ),
  (RegExp(r'\b[\w.+-]+@[\w-]+(\.[\w-]+)+\b'), (_) => '<e-mail>'),
  (RegExp(r'\b(\d{1,3}\.){3}\d{1,3}(:\d+)?\b'), (_) => '<ip>'),
  (
    RegExp(r'\b([0-9a-f]{0,4}:){2,7}[0-9a-f]{1,4}\b', caseSensitive: false),
    (_) => '<ip>',
  ),
  // Host names with a dot and a known shape, e.g. "nas.example.org:8090".
  (
    RegExp(r'\b([a-z0-9-]+\.)+[a-z]{2,}(:\d+)?\b', caseSensitive: false),
    (_) => '<host>',
  ),
  // Long random strings: tokens, keys, cookies without a name.
  (RegExp(r'\b[A-Za-z0-9_\-+/=]{32,}\b'), (_) => '<redacted>'),
];
