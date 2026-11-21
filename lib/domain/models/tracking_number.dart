/// The keys under which carrier links carry the tracking number, e.g.
/// `?piececode=…` (DHL) or `?tracknum=…`.
const _keys = [
  'piececode',
  'idc',
  'tracknum',
  'tracknumbers',
  'tracking',
  'trackingnumber',
  'tracking_number',
  'parcelnumber',
  'trknbr',
  'id',
];

/// Turns the text of a scanned code into a tracking number (#196): links
/// of carriers give the number from their query, GS1 application
/// identifiers in parentheses are dropped, spaces go. `null` when nothing
/// like a tracking number is left; the person can always type one.
String? trackingNumberFrom(String scanned) {
  var text = scanned.trim();
  if (text.isEmpty) return null;
  final uri = Uri.tryParse(text);
  if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
    final query = {
      for (final e in uri.queryParameters.entries) e.key.toLowerCase(): e.value,
    };
    final key = _keys.firstWhere(
      (k) => (query[k] ?? '').trim().isNotEmpty,
      orElse: () => '',
    );
    if (key.isEmpty) return null;
    text = query[key]!.split(',').first;
  }
  // "(00)340434161094042557" → the digits after the identifier.
  text = text.replaceAll(RegExp(r'^\(\d{2,4}\)'), '');
  text = text.replaceAll(RegExp(r'[\s\-]'), '').toUpperCase();
  final ok = RegExp(r'^[A-Z0-9]{8,40}$').hasMatch(text);
  return ok ? text : null;
}
