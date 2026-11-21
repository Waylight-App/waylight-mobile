import 'package:waylight_mobile/data/services/api/platform_api.dart';
import 'package:waylight_mobile/domain/models/address_check.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The outcome of [AddressSelector.select].
typedef AddressSelection = ({
  ServerAddress? chosen,
  Map<ServerAddress, AddressCheck> checks,
});

/// Picks the address of a server to use right now (#189): the first one, in
/// the user's order, that answers and accepts the session. All addresses
/// are asked at once, so the choice takes no longer than one timeout.
class AddressSelector {
  /// Creates the selector.
  AddressSelector({
    required this._api,
    this.timeout = const Duration(seconds: 3),
  });

  final PlatformApi _api;

  /// How long one address may take to answer.
  final Duration timeout;

  /// Checks [addresses] of [server]; with [signedIn] an address must also
  /// accept the session, so a different device under the same home
  /// network address is never used.
  Future<AddressSelection> select(
    ServerAddress server,
    List<ServerAddress> addresses, {
    required bool signedIn,
  }) async {
    final results = await Future.wait([
      for (final a in addresses)
        _api.probeAuthStatus(server, via: a, timeout: timeout),
    ]);
    final checks = <ServerAddress, AddressCheck>{};
    ServerAddress? chosen;
    for (final (i, a) in addresses.indexed) {
      final check = switch (results[i]) {
        Ok(:final value) when !signedIn || value.authenticated =>
          AddressCheck.ok,
        Ok() => AddressCheck.rejected,
        Error() => AddressCheck.unreachable,
      };
      checks[a] = check;
      if (check == AddressCheck.ok) chosen ??= a;
    }
    return (chosen: chosen, checks: checks);
  }
}
