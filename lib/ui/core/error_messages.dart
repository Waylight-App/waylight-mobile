import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/l10n/generated/app_localizations.dart';

/// The texts for failures every feature can meet, so the same failure reads
/// the same everywhere (docs/code-conventions.md#errors).
///
/// Features handle their own errors first (e.g. an invalid address) and
/// pass everything else here.
extension ErrorMessages on AppLocalizations {
  /// The message for [error].
  String errorMessage(Exception error) => switch (error) {
    ApiException(:final failure) => switch (failure) {
      ApiFailure.unreachable => errorUnreachable,
      ApiFailure.unauthorized => errorUnauthorized,
      ApiFailure.forbidden => errorForbidden,
      ApiFailure.notFound => errorNotFound,
      ApiFailure.invalid => errorInvalid,
      ApiFailure.tooManyRequests => errorTooManyRequests,
      ApiFailure.server => errorServer,
    },
    _ => errorUnknown,
  };
}
