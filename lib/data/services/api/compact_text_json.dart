import 'package:waylight_mobile/domain/models/compact_state.dart';

/// Maps a text of the server (`CompactText` in the API): the English text,
/// the key of its translation and the values of the placeholders; `null`
/// without a text.
CompactText? parseCompactText(Object? json) => switch (json) {
  {'text': final String text} && final Map<String, Object?> o => CompactText(
    text: text,
    key: switch (o['key']) {
      final String k => k,
      _ => '',
    },
    params: switch (o['params']) {
      final Map<String, Object?> p => {
        for (final MapEntry(:key, :value) in p.entries)
          if (value is String) key: value,
      },
      _ => const {},
    },
  ),
  _ => null,
};
