import 'dart:convert';

import 'package:logging/logging.dart';

import 'package:waylight_mobile/data/repositories/dashboard/dashboard_repository.dart';
import 'package:waylight_mobile/data/services/api/dashboard_api.dart';
import 'package:waylight_mobile/data/services/storage/key_value_store.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// A [DashboardRepository] that asks the server every time.
///
/// Widget sizes (#208) live in the phone layout on servers that know them
/// (Waylight-App/waylight#585). For older servers the repository keeps them
/// on the device, per server, tab and widget, and lays them over what the
/// server answers. Favourites (#333) are kept the same way for servers
/// without them in the phone layout (Waylight-App/waylight#844).
class DashboardRepositoryRemote implements DashboardRepository {
  /// Creates the repository.
  DashboardRepositoryRemote({required this._api, required this._store});

  /// The key under which sizes for servers without them are stored.
  static const storageKey = 'dashboard.sizes';

  final DashboardApi _api;
  final KeyValueStore _store;
  final Logger _log = Logger('DashboardRepository');

  /// The key under which favourites for servers without them are stored
  /// (#333).
  static const favouritesKey = 'dashboard.favourites';

  /// Tabs whose server stores sizes, as `server|tab`.
  final Set<String> _sizesOnServer = {};

  /// Tabs whose server stores favourites, as `server|tab`.
  final Set<String> _favouritesOnServer = {};

  @override
  Future<Result<Dashboard>> dashboard(ServerAddress server) async {
    final Dashboard dashboard;
    switch (await _api.dashboard(server)) {
      case Ok(:final value):
        dashboard = value;
      case Error(:final error):
        return Result.error(error);
    }
    final local = await _localSizes();
    final mine = local[server.toString()] ?? const {};
    final favourites = (await _localFavourites())[server.toString()] ?? {};
    final tabs = <DashboardTab>[];
    for (var tab in dashboard.tabs) {
      final key = '$server|${tab.id}';
      if (tab.sizesOnServer) {
        _sizesOnServer.add(key);
      } else {
        _sizesOnServer.remove(key);
        final sizes = mine[tab.id];
        if (sizes != null && sizes.isNotEmpty) tab = tab.withSizes(sizes);
      }
      if (tab.favouritesOnServer) {
        _favouritesOnServer.add(key);
      } else {
        _favouritesOnServer.remove(key);
        final ids = favourites[tab.id];
        if (ids != null && ids.isNotEmpty) tab = tab.withFavourites(ids);
      }
      tabs.add(tab);
    }
    return Result.ok(
      Dashboard(tabs: tabs, defaultTabId: dashboard.defaultTabId),
    );
  }

  @override
  Future<Result<void>> saveLayout(
    ServerAddress server,
    String tabId,
    List<PhoneLayoutItem> layout,
  ) async {
    final onServer = _sizesOnServer.contains('$server|$tabId');
    final favouritesOnServer = _favouritesOnServer.contains('$server|$tabId');
    final result = await _api.saveLayout(
      server,
      tabId,
      layout,
      withSizes: onServer,
      withFavourites: favouritesOnServer,
    );
    if (result is Ok<void> && !onServer) {
      await _storeSizes(server, tabId, {
        for (final item in layout) item.widget.id: ?item.size,
      });
    }
    if (result is Ok<void> && !favouritesOnServer) {
      await _storeFavourites(server, tabId, {
        for (final item in layout)
          if (item.favourite) item.widget.id,
      });
    }
    return result;
  }

  @override
  Future<Result<List<String>>> widgetKinds(ServerAddress server) =>
      _api.widgetKinds(server);

  @override
  Future<Result<WidgetPlacement>> addWidget(
    ServerAddress server,
    String tabId,
    String kind, {
    required int desktopRows,
  }) => _api.addWidget(server, tabId, kind, row: desktopRows);

  @override
  Future<Result<void>> updateWidget(
    ServerAddress server,
    String id,
    Map<String, Object?> config,
  ) => _api.updateWidget(server, id, config);

  @override
  Future<Result<void>> resetLayout(ServerAddress server, String tabId) async {
    final result = await _api.resetLayout(server, tabId);
    if (result is Ok<void>) {
      await _storeSizes(server, tabId, const {});
      // A reset drops the server's favourites with its layout; the device
      // copy follows, so both kinds of server behave alike.
      await _storeFavourites(server, tabId, const {});
    }
    return result;
  }

  /// Forgets the sizes and favourites kept on the device, e.g. when
  /// signing out.
  Future<void> clear() async {
    try {
      await _store.delete(storageKey);
      await _store.delete(favouritesKey);
    } on Exception catch (e) {
      _log.warning('Could not delete the widget sizes.', e);
    }
  }

  /// The stored favourites: server → tab → widget ids.
  Future<Map<String, Map<String, Set<String>>>> _localFavourites() async {
    try {
      final json = jsonDecode(await _store.read(favouritesKey) ?? '{}');
      return {
        if (json case final Map<String, Object?> servers)
          for (final MapEntry(key: server, value: tabs) in servers.entries)
            if (tabs case final Map<String, Object?> tabs)
              server: {
                for (final MapEntry(key: tab, value: ids) in tabs.entries)
                  if (ids case final List<Object?> ids)
                    tab: {
                      for (final id in ids)
                        if (id case final String id) id,
                    },
              },
      };
    } on Exception catch (e) {
      _log.warning('Ignoring favourites that cannot be read.', e);
      return {};
    }
  }

  Future<void> _storeFavourites(
    ServerAddress server,
    String tabId,
    Set<String> ids,
  ) async {
    final all = await _localFavourites();
    // Nothing to forget: leave the store untouched, so a phone that never
    // marked a favourite keeps nothing about them.
    if (ids.isEmpty && !(all[server.toString()]?.containsKey(tabId) ?? false)) {
      return;
    }
    final tabs = all.putIfAbsent(server.toString(), () => {});
    if (ids.isEmpty) {
      tabs.remove(tabId);
    } else {
      tabs[tabId] = ids;
    }
    try {
      await _store.write(
        favouritesKey,
        jsonEncode({
          for (final MapEntry(key: server, value: tabs) in all.entries)
            if (tabs.isNotEmpty)
              server: {
                for (final MapEntry(key: tab, value: ids) in tabs.entries)
                  tab: [...ids],
              },
        }),
      );
    } on Exception catch (e) {
      _log.warning('Could not store the favourites.', e);
    }
  }

  /// The stored sizes: server → tab → widget → size.
  Future<Map<String, Map<String, Map<String, WidgetSize>>>>
  _localSizes() async {
    try {
      final json = jsonDecode(await _store.read(storageKey) ?? '{}');
      return {
        if (json case final Map<String, Object?> servers)
          for (final MapEntry(key: server, value: tabs) in servers.entries)
            if (tabs case final Map<String, Object?> tabs)
              server: {
                for (final MapEntry(key: tab, value: widgets) in tabs.entries)
                  if (widgets case final Map<String, Object?> widgets)
                    tab: {
                      for (final MapEntry(key: id, value: name)
                          in widgets.entries)
                        id: ?WidgetSize.parse(name),
                    },
              },
      };
    } on Exception catch (e) {
      _log.warning('Ignoring widget sizes that cannot be read.', e);
      return {};
    }
  }

  Future<void> _storeSizes(
    ServerAddress server,
    String tabId,
    Map<String, WidgetSize> sizes,
  ) async {
    final all = await _localSizes();
    final tabs = all.putIfAbsent(server.toString(), () => {});
    if (sizes.isEmpty) {
      tabs.remove(tabId);
    } else {
      tabs[tabId] = sizes;
    }
    try {
      await _store.write(
        storageKey,
        jsonEncode({
          for (final MapEntry(key: server, value: tabs) in all.entries)
            if (tabs.isNotEmpty)
              server: {
                for (final MapEntry(key: tab, value: widgets) in tabs.entries)
                  tab: {
                    for (final MapEntry(key: id, value: size)
                        in widgets.entries)
                      id: size.name,
                  },
              },
        }),
      );
    } on Exception catch (e) {
      _log.warning('Could not store the widget sizes.', e);
    }
  }
}
