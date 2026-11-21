import 'package:waylight_mobile/data/services/api/module_api.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The containers the owner allowed to restart and read logs of.
final class DockerActions {
  /// Creates the permissions.
  const DockerActions({this.enabled = false, this.containers = const {}});

  /// Whether container actions are turned on at all.
  final bool enabled;

  /// The allowed container names.
  final Set<String> containers;

  /// Whether [name] may be restarted and its logs read.
  bool allows(String name) => enabled && containers.contains(name);
}

/// Actions on the home server for admins (#108): wake a service, restart a
/// container and read its log, power a Proxmox guest, pause the DNS filter.
/// The server checks every permission again.
abstract interface class HomeServerActionsRepository {
  /// Wakes a sleeping service by Wake-on-LAN.
  Future<Result<void>> wake(ServerAddress server, String serviceId);

  /// What may be done with containers.
  Future<Result<DockerActions>> dockerActions(ServerAddress server);

  /// Restarts a container.
  Future<Result<void>> restart(ServerAddress server, String container);

  /// The last lines of a container's log.
  Future<Result<List<String>>> logs(ServerAddress server, String container);

  /// Starts or shuts down a Proxmox guest; [action] is "start" or
  /// "shutdown", never a hard stop.
  Future<Result<void>> powerGuest(
    ServerAddress server,
    int guestId,
    String action,
  );

  /// Pauses blocking of the DNS filter [provider] (`adguard` or `pihole`)
  /// for [minutes].
  Future<Result<void>> pauseDnsFilter(
    ServerAddress server,
    int minutes, {
    required String provider,
  });
}

/// A [HomeServerActionsRepository] on the modules' endpoints.
class HomeServerActionsRepositoryRemote implements HomeServerActionsRepository {
  /// Creates the repository.
  const HomeServerActionsRepositoryRemote({required this._api});

  final ModuleApi _api;

  static Result<void> _done(Result<Object?> r) => switch (r) {
    Ok() => const Result.ok(null),
    Error(:final error) => Result.error(error),
  };

  @override
  Future<Result<void>> wake(ServerAddress server, String serviceId) async =>
      _done(
        await _api.post(
          server,
          '/api/services/${Uri.encodeComponent(serviceId)}/wake',
        ),
      );

  @override
  Future<Result<DockerActions>> dockerActions(ServerAddress server) =>
      _api.read(server, '/api/docker/actions', (json) {
        if (json case {'enabled': final bool enabled}) {
          return DockerActions(
            enabled: enabled,
            containers: {
              if (json['containers'] case final List<Object?> list)
                for (final c in list)
                  if (c is String) c,
            },
          );
        }
        return null;
      });

  @override
  Future<Result<void>> restart(ServerAddress server, String container) async =>
      _done(
        await _api.post(
          server,
          '/api/docker/containers/${Uri.encodeComponent(container)}/restart',
        ),
      );

  @override
  Future<Result<List<String>>> logs(ServerAddress server, String container) =>
      _api.read(
        server,
        '/api/docker/containers/${Uri.encodeComponent(container)}/logs',
        (json) => switch (json) {
          {'lines': final List<Object?> lines} => [
            for (final l in lines)
              if (l is String) l,
          ],
          _ => null,
        },
      );

  @override
  Future<Result<void>> powerGuest(
    ServerAddress server,
    int guestId,
    String action,
  ) async =>
      _done(await _api.post(server, '/api/proxmox/guests/$guestId/$action'));

  @override
  Future<Result<void>> pauseDnsFilter(
    ServerAddress server,
    int minutes, {
    required String provider,
  }) async => _done(
    await _api.post(
      server,
      '/api/adguard/pause',
      body: {'minutes': minutes},
      query: {'provider': provider},
    ),
  );
}
