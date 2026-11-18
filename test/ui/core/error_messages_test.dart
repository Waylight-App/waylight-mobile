import 'package:flutter_test/flutter_test.dart';

import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/ui/core/error_messages.dart';

import '../../testing/pump_app.dart';

void main() {
  test('every API failure has its own message', () {
    final messages = {
      for (final failure in ApiFailure.values)
        l10nEn.errorMessage(ApiException(failure)),
    };

    expect(messages, hasLength(ApiFailure.values.length));
  });

  test('unknown errors get the fallback', () {
    expect(l10nEn.errorMessage(Exception('boom')), l10nEn.errorUnknown);
  });
}
