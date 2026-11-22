import 'package:waylight_mobile/data/services/api/api_client.dart';
import 'package:waylight_mobile/data/services/api/compact_text_json.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/compact_state.dart';
import 'package:waylight_mobile/domain/models/help.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The in-app help of the server (`api/openapi.base.yaml`, #289).
class HelpApi {
  /// Creates the service on top of an [ApiClient].
  const HelpApi(this._client);

  final ApiClient _client;

  /// Reads `GET /api/help/widgets` in [language] (`lang`, e.g. `de`); the
  /// server answers in English for a language it has no texts in.
  Future<Result<List<WidgetHelp>>> widgets(
    ServerAddress server, {
    String language = '',
  }) async {
    final result = await _client.getJson(
      server
          .resolve('/api/help/widgets')
          .replace(
            queryParameters: {if (language.isNotEmpty) 'lang': language},
          ),
    );
    return switch (result) {
      Ok(:final value) => switch (parseWidgetHelp(value)) {
        final help? => Result.ok(help),
        null => const Result.error(ApiException(ApiFailure.server)),
      },
      Error(:final error) => Result.error(error),
    };
  }
}

/// Maps `GET /api/help/widgets`; entries without texts or a web address
/// are left out, so a newer server does not break the app.
List<WidgetHelp>? parseWidgetHelp(Object? json) {
  if (json case {'widgets': final List<Object?> list}) {
    return [
      for (final w in list)
        if (w case {
          'kind': final String kind,
          'shows': final Object? shows,
          'setUp': final Object? setUp,
          'docsUrl': final String url,
        })
          if ((parseCompactText(shows), parseCompactText(setUp)) case (
            final CompactText s,
            final CompactText u,
          ))
            if (Uri.tryParse(url) case final uri? when uri.hasScheme)
              WidgetHelp(kind: kind, shows: s, setUp: u, docsUrl: uri),
    ];
  }
  return null;
}
