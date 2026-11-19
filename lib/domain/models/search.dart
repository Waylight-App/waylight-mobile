import 'package:waylight_mobile/domain/models/dashboard.dart';

/// What the search field of the account knows (`GET /api/search/settings`).
final class SearchSettings {
  /// Creates the settings.
  const SearchSettings({
    this.defaultProvider = 'duckduckgo',
    this.shortcuts = const [],
    this.keywords = const [],
    this.todoPrefix = 't',
  });

  /// The id of the web search, e.g. `duckduckgo`.
  final String defaultProvider;

  /// Shortcuts such as `maps` with a URL template.
  final List<SearchShortcut> shortcuts;

  /// Own keywords that open a target.
  final List<SearchKeyword> keywords;

  /// The quick capture prefix for to-dos, e.g. `t`.
  final String todoPrefix;
}

/// A shortcut such as `!maps Berlin`.
final class SearchShortcut {
  /// Creates the shortcut.
  const SearchShortcut({
    required this.keyword,
    required this.name,
    required this.urlTemplate,
  });

  /// The word typed first, without `!`.
  final String keyword;

  /// The name of the target, e.g. "OpenStreetMap".
  final String name;

  /// An http(s) address with `{query}`.
  final String urlTemplate;
}

/// An own keyword that opens an address or runs a search.
final class SearchKeyword {
  /// Creates the keyword.
  const SearchKeyword({
    required this.keyword,
    required this.kind,
    required this.target,
    this.label = '',
  });

  /// The word to type.
  final String keyword;

  /// `service`, `bookmark`, `widget`, `url` or `query`.
  final String kind;

  /// The id of the target, an http(s) address or a search text.
  final String target;

  /// The name of the target.
  final String label;
}

/// One thing the search can do with what was typed.
sealed class SearchResult {
  const SearchResult();
}

/// Opens an address in the browser.
final class OpenAddress extends SearchResult {
  /// Creates the result.
  const OpenAddress({required this.label, required this.uri});

  /// What is opened.
  final String label;

  /// The address.
  final Uri uri;
}

/// Opens a tab of the dashboard with the matching widget.
final class OpenWidget extends SearchResult {
  /// Creates the result.
  const OpenWidget({required this.widget, required this.tab});

  /// The widget that matched.
  final WidgetPlacement widget;

  /// Its tab.
  final DashboardTab tab;
}

/// Adds a to-do with the text after the prefix.
final class CaptureTodo extends SearchResult {
  /// Creates the result.
  const CaptureTodo(this.title);

  /// The title of the new to-do.
  final String title;
}

/// The web search addresses of the providers the server offers.
const _providers = {
  'duckduckgo': 'https://duckduckgo.com/?q={query}',
  'startpage': 'https://www.startpage.com/do/search?q={query}',
  'brave': 'https://search.brave.com/search?q={query}',
  'ecosia': 'https://www.ecosia.org/search?q={query}',
  'google': 'https://www.google.com/search?q={query}',
  'bing': 'https://www.bing.com/search?q={query}',
};

Uri? _fill(String template, String query) {
  final uri = Uri.tryParse(
    template.replaceAll('{query}', Uri.encodeQueryComponent(query)),
  );
  return uri != null && (uri.isScheme('https') || uri.isScheme('http'))
      ? uri
      : null;
}

/// The web search of [provider] for [query]; DuckDuckGo for unknown ones.
Uri webSearch(String provider, String query) =>
    _fill(_providers[provider] ?? _providers['duckduckgo']!, query)!;

/// What the search offers for [query], most specific first: quick capture,
/// own keywords, shortcuts, matching widgets. The web search is always
/// offered by the screen as the last choice.
List<SearchResult> searchResults(
  String query,
  SearchSettings settings,
  Dashboard? dashboard,
) {
  final text = query.trim();
  if (text.isEmpty) return const [];
  final (first, rest) = switch (text.indexOf(' ')) {
    -1 => (text, ''),
    final i => (text.substring(0, i), text.substring(i + 1).trim()),
  };
  final word = first.toLowerCase().replaceFirst('!', '');
  final results = <SearchResult>[];

  if (settings.todoPrefix.isNotEmpty &&
      word == settings.todoPrefix.toLowerCase() &&
      rest.isNotEmpty) {
    results.add(CaptureTodo(rest));
  }
  for (final k in settings.keywords) {
    if (k.keyword.toLowerCase() != word) continue;
    final label = k.label.isEmpty ? k.target : k.label;
    switch (k.kind) {
      case 'url':
        if (_fill(k.target, '') case final uri?) {
          results.add(OpenAddress(label: label, uri: uri));
        }
      case 'query':
        results.add(
          OpenAddress(
            label: label,
            uri: webSearch(
              settings.defaultProvider,
              '${k.target} $rest'.trim(),
            ),
          ),
        );
      case 'widget':
        for (final tab in dashboard?.tabs ?? const <DashboardTab>[]) {
          for (final w in tab.widgets) {
            if (w.id == k.target) results.add(OpenWidget(widget: w, tab: tab));
          }
        }
    }
  }
  for (final s in settings.shortcuts) {
    if (s.keyword.toLowerCase().replaceFirst('!', '') == word &&
        rest.isNotEmpty) {
      if (_fill(s.urlTemplate, rest) case final uri?) {
        results.add(OpenAddress(label: '${s.name}: $rest', uri: uri));
      }
    }
  }
  final needle = text.toLowerCase();
  for (final tab in dashboard?.tabs ?? const <DashboardTab>[]) {
    for (final w in tab.widgets) {
      if (w.displayTitle.toLowerCase().contains(needle) ||
          w.kind.toLowerCase().contains(needle)) {
        results.add(OpenWidget(widget: w, tab: tab));
      }
    }
  }
  return results;
}

/// A page of a connected wiki that matches the query (`GET /api/wiki/search`).
final class WikiHit {
  /// Creates the hit.
  const WikiHit({
    required this.title,
    required this.url,
    this.excerpt = '',
    this.wiki = '',
  });

  /// The page title.
  final String title;

  /// The page on the wiki's own host.
  final Uri url;

  /// The matching text.
  final String excerpt;

  /// The wiki's name.
  final String wiki;
}
