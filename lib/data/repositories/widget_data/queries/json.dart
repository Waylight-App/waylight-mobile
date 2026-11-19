/// Small helpers for the parsers of the widget queries.
library;

/// A number from JSON as double, or `null`.
double? asDouble(Object? v) => v is num ? v.toDouble() : null;

/// A date-time from JSON, or `null`.
DateTime? asDateTime(Object? v) => v is String ? DateTime.tryParse(v) : null;

/// A calendar day ("2026-11-23") as local midnight, or `null`.
DateTime? asDay(Object? v) {
  if (v is! String) return null;
  final parsed = DateTime.tryParse(v);
  return parsed == null
      ? null
      : DateTime(parsed.year, parsed.month, parsed.day);
}

/// Maps every element of a JSON list with [item]; `null` if the value is no
/// list or one element does not match.
List<T>? listOf<T>(Object? json, T? Function(Object? item) item) {
  if (json is! List<Object?>) return null;
  final out = <T>[];
  for (final e in json) {
    final mapped = item(e);
    if (mapped == null) return null;
    out.add(mapped);
  }
  return out;
}
