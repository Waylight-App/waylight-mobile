import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:waylight_mobile/data/repositories/dashboard/dashboard_repository.dart';
import 'package:waylight_mobile/data/repositories/search/search_repository.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/data/repositories/todos/todos_repository.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/search.dart';
import 'package:waylight_mobile/utils/command.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The state of the search (#22): keywords, shortcuts, widgets, quick
/// capture and the web search, computed on the phone from the search
/// settings and the dashboard.
class SearchViewModel extends ChangeNotifier {
  /// Creates the view model and loads settings and dashboard.
  SearchViewModel({
    required this._serverRepository,
    required this._searchRepository,
    required this._dashboardRepository,
    required this._todosRepository,
    this.debounce = const Duration(milliseconds: 250),
  }) {
    _load().ignore();
    capture = Command1(_capture);
  }

  final ServerRepository _serverRepository;
  final SearchRepository _searchRepository;
  final DashboardRepository _dashboardRepository;
  final TodosRepository _todosRepository;

  /// How long typing has to pause before the results update.
  final Duration debounce;

  SearchSettings _settings = const SearchSettings();
  Dashboard? _dashboard;
  String _query = '';
  List<SearchResult> _results = const [];
  Timer? _timer;

  /// Adds a to-do from the quick capture.
  late final Command1<void, String> capture;

  /// The text the results are for.
  String get query => _query;

  /// What the search offers for [query].
  List<SearchResult> get results => _results;

  /// The web search for [query] with the account's provider.
  Uri get webSearchUri => webSearch(_settings.defaultProvider, _query.trim());

  Future<void> _load() async {
    final server = _serverRepository.current;
    if (server == null) return;
    final settings = await _searchRepository.settings(server);
    if (settings case Ok(:final value)) _settings = value;
    final dashboard = await _dashboardRepository.dashboard(server);
    if (dashboard case Ok(:final value)) _dashboard = value;
    _update();
  }

  /// Updates the results for [text] once typing pauses.
  void onQueryChanged(String text) {
    _query = text;
    _timer?.cancel();
    _timer = Timer(debounce, _update);
  }

  void _update() {
    _results = searchResults(_query, _settings, _dashboard);
    notifyListeners();
  }

  Future<Result<void>> _capture(String title) async {
    final server = _serverRepository.current;
    if (server == null) return const Result.error(NotConnectedException());
    final result = await _todosRepository.create(server, title: title);
    return switch (result) {
      Ok() => const Result.ok(null),
      Error(:final error) => Result.error(error),
    };
  }

  @override
  void dispose() {
    _timer?.cancel();
    capture.dispose();
    super.dispose();
  }
}
