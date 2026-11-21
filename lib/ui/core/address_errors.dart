import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/ui/core/localization.dart';

/// The message shown at the address field, for input the app rejects
/// itself; `null` for every other error.
String? fieldError(AppLocalizations l10n, Exception error) => switch (error) {
  InvalidServerAddress(:final reason) => switch (reason) {
    InvalidServerAddressReason.empty => l10n.connectErrorEmpty,
    InvalidServerAddressReason.malformed => l10n.connectErrorInvalid,
    InvalidServerAddressReason.unsupportedScheme => l10n.connectErrorScheme,
    InvalidServerAddressReason.unexpectedParts => l10n.connectErrorParts,
    InvalidServerAddressReason.insecure => l10n.connectErrorInsecure,
  },
  _ => null,
};
