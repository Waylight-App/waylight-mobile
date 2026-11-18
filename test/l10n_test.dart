// Every text exists in every language and uses the same placeholders
// (docs/development.md#translations).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> _arb(String locale) =>
    jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync())
        as Map<String, Object?>;

Iterable<String> _keys(Map<String, Object?> arb) =>
    arb.keys.where((key) => !key.startsWith('@'));

Set<String> _placeholders(Object? text) =>
    RegExp(r'\{(\w+)')
        .allMatches(text! as String)
        .map((m) => m.group(1)!)
        .toSet();

void main() {
  final english = _arb('en');
  final locales = Directory('lib/l10n')
      .listSync()
      .map((f) => RegExp(r'app_(\w+)\.arb$').firstMatch(f.path)?.group(1))
      .whereType<String>()
      .where((locale) => locale != 'en');

  test('every English text has a description', () {
    final missing = _keys(english).where((k) => english['@$k'] == null);
    expect(missing, isEmpty);
  });

  for (final locale in locales) {
    group(locale, () {
      final translated = _arb(locale);

      test('has exactly the English keys', () {
        expect(_keys(translated).toSet(), _keys(english).toSet());
      });

      test('uses the same placeholders', () {
        for (final key in _keys(english)) {
          expect(
            _placeholders(translated[key]),
            _placeholders(english[key]),
            reason: key,
          );
        }
      });
    });
  }
}
