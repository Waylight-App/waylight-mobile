import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:waylight_mobile/domain/models/compact_derived.dart';
import 'package:waylight_mobile/domain/models/compact_state.dart';
import 'package:waylight_mobile/domain/models/waste_collection.dart';
import 'package:waylight_mobile/l10n/generated/app_localizations.dart';
import 'package:waylight_mobile/ui/core/compact_texts.dart';

/// Derived compact states in the app's language (#242).
void main() {
  final de = lookupAppLocalizations(const Locale('de'));
  final en = lookupAppLocalizations(const Locale('en'));

  test('translates derived texts', () {
    final state = compactWaste(const [
      WasteCollection(label: 'Bio', dates: [], daysUntil: 2),
    ], DateTime(2026, 11, 21));
    expect(compactTextOf(de, state.title), 'Bio in 2 Tagen');
    expect(compactTextOf(en, state.title), 'Bio in 2 days');
  });

  test('shows server texts as sent', () {
    const text = CompactText(text: '3 open', key: 'srv_123');
    expect(compactTextOf(de, text), '3 open');
  });
}
