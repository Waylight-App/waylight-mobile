import 'package:flutter/foundation.dart';

import 'package:waylight_mobile/domain/models/address_check.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/domain/models/server_status.dart';
import 'package:waylight_mobile/utils/result.dart';

/// An operation needs a server, but none is connected.
final class NotConnectedException implements Exception {
  /// Creates the exception.
  const NotConnectedException();

  @override
  String toString() => 'NotConnectedException()';
}

/// The addresses given to [ServerRepository.setAddresses] are not 1 to
/// [ServerRepository.maxAddresses] different ones (#189).
final class InvalidAddressesException implements Exception {
  /// Creates the exception.
  const InvalidAddressesException();

  @override
  String toString() => 'InvalidAddressesException()';
}

/// The Waylight server the app talks to.
///
/// The single source of truth for the server address. It notifies its
/// listeners when the address changes, so the router can send the user to
/// the right screen.
abstract class ServerRepository extends ChangeNotifier {
  /// The connected server, or `null` before the first connection.
  ServerAddress? get current;

  /// Loads the address saved on the device; call once at start.
  Future<Result<void>> restore();

  /// Checks that [server] is a reachable Waylight server and saves it as
  /// [current].
  Future<Result<ServerStatus>> connect(ServerAddress server);

  /// Asks the [current] server for its [ServerStatus].
  Future<Result<ServerStatus>> status();

  /// The version the [current] server runs, if the account may see it.
  Future<Result<String>> version();

  /// The servers used on this device, the current one included (#51).
  List<ServerAddress> get known;

  /// Makes the known [server] the current one without checking it again.
  Future<Result<void>> switchTo(ServerAddress server);

  /// Leaves the current server but keeps it in [known], e.g. to add
  /// another one.
  Future<Result<void>> leave();

  /// Removes [server] from [known]; leaves it first if it is current.
  Future<Result<void>> forget(ServerAddress server);

  /// Forgets the saved server.
  Future<Result<void>> disconnect();

  /// The most addresses one server can have (#189).
  static const maxAddresses = 3;

  /// The addresses of the [current] server in the order they are tried
  /// (#189); just [current] until more are added.
  List<ServerAddress> get addresses => [?current];

  /// The address requests go to right now; `null` when none answered.
  ServerAddress? get active => current;

  /// What the last check of each address found.
  Map<ServerAddress, AddressCheck> get checks => const {};

  /// Replaces the addresses of the [current] server (1 to [maxAddresses],
  /// no duplicates) and checks them again.
  Future<Result<void>> setAddresses(List<ServerAddress> addresses) async =>
      const Result.error(InvalidAddressesException());

  /// Checks the addresses again and uses the first one that answers, e.g.
  /// after the network changed or the app came back.
  Future<void> selectAddress() async {}
}
