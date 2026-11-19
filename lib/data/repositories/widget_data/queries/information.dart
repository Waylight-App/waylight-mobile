import 'package:waylight_mobile/data/repositories/widget_data/queries/json.dart';
import 'package:waylight_mobile/data/repositories/widget_data/widget_data_repository.dart';
import 'package:waylight_mobile/domain/models/information.dart';

/// `GET /api/fuel/overview`.
const fuelQuery = WidgetQuery<FuelOverview>('/api/fuel/overview', parseFuel);

/// `GET /api/markets/watchlist`; `symbols` comes from the widget's settings.
const marketsQuery = WidgetQuery<List<MarketQuote>>(
  '/api/markets/watchlist',
  parseMarkets,
);

/// The symbols of the web interface when a widget names none.
const defaultMarketSymbols = ['fx:USD', 'stooq:^dax', 'stooq:btcusd'];

/// `GET /api/calendar/events`.
const calendarQuery = WidgetQuery<List<CalendarEvent>>(
  '/api/calendar/events',
  parseCalendar,
);

/// `GET /api/phonelist/entries`.
const phoneListQuery = WidgetQuery<List<PhoneEntry>>(
  '/api/phonelist/entries',
  parsePhoneList,
);

/// `GET /api/study/progress`.
const studyQuery = WidgetQuery<StudyProgress>(
  '/api/study/progress',
  parseStudy,
);

/// The list widgets, each mapped to sections of [FeedItem]s.
const briefingQuery = WidgetQuery<List<FeedSection>>(
  '/api/briefing',
  parseBriefing,
);

/// Sonarr, Radarr and Prowlarr.
const arrQuery = WidgetQuery<List<FeedSection>>('/api/arr/overview', parseArr);

/// Plex, Jellyfin and Emby.
const mediaQuery = WidgetQuery<List<FeedSection>>(
  '/api/media/overview',
  parseMedia,
);

/// New releases of followed artists.
const releasesQuery = WidgetQuery<List<FeedSection>>(
  '/api/releases',
  parseReleases,
);

/// Game deals.
const gameDealsQuery = WidgetQuery<List<FeedSection>>(
  '/api/gamedeals/overview',
  parseGameDeals,
);

/// Rocket launches.
const launchesQuery = WidgetQuery<List<FeedSection>>(
  '/api/space/launches',
  parseLaunches,
);

String _s(Object? v) => v is String ? v : '';

Uri? _url(Object? v) => v is String && v.isNotEmpty ? Uri.tryParse(v) : null;

FeedTone _tone(Object? severity) => switch (severity) {
  'critical' || 'error' => FeedTone.critical,
  'warning' => FeedTone.warning,
  _ => FeedTone.neutral,
};

/// Maps `GET /api/fuel/overview`: favourites when there are any.
FuelOverview? parseFuel(Object? json) {
  if (json case {'fuel': final String fuel, 'place': final String place}) {
    FuelStation? station(Object? s) {
      if (s case {'name': final String name}) {
        return FuelStation(
          name: name,
          brand: _s(s['brand']),
          address: _s(s['address']),
          open: s['open'] == true,
          price: asDouble(s['price']),
          distanceKm: asDouble(s['distanceKm']),
        );
      }
      return null;
    }

    final favourites = listOf(json['favourites'] ?? const <Object?>[], station);
    final cheapest = listOf(json['cheapest'] ?? const <Object?>[], station);
    if (favourites == null || cheapest == null) return null;
    return FuelOverview(
      fuel: fuel,
      place: place,
      stations: favourites.isNotEmpty ? favourites : cheapest,
    );
  }
  return null;
}

/// Maps `GET /api/markets/watchlist`.
List<MarketQuote>? parseMarkets(Object? json) => listOf<MarketQuote>(json, (r) {
  if (r case {'symbol': final String symbol}) {
    return MarketQuote(
      symbol: symbol,
      value: asDouble(r['value']),
      changePercent: asDouble(r['changePct']),
      history: [
        if (r['history'] case final List<Object?> h)
          for (final p in h)
            if (p case {'value': final num v}) v.toDouble(),
      ],
    );
  }
  return null;
});

/// Maps `GET /api/calendar/events`.
List<CalendarEvent>? parseCalendar(Object? json) {
  if (json case {'events': final Object? events}) {
    return listOf<CalendarEvent>(events, (e) {
      if (e case {
        'summary': final String summary,
        'start': final String start,
        'end': final String end,
      }) {
        final from = DateTime.tryParse(start);
        final to = DateTime.tryParse(end);
        if (from == null || to == null) return null;
        return CalendarEvent(
          summary: summary,
          start: from.toLocal(),
          end: to.toLocal(),
          allDay: e['allDay'] == true,
          location: _s(e['location']),
          calendar: _s(e['calendar']),
        );
      }
      return null;
    });
  }
  return null;
}

/// Maps `GET /api/phonelist/entries`.
List<PhoneEntry>? parsePhoneList(Object? json) => listOf<PhoneEntry>(json, (e) {
  if (e case {'name': final String name}) {
    return PhoneEntry(
      name: name,
      role: _s(e['role']),
      team: _s(e['team']),
      phone: _s(e['phone']),
      dial: _s(e['dial']),
      email: _s(e['email']),
    );
  }
  return null;
});

/// Maps `GET /api/study/progress`.
StudyProgress? parseStudy(Object? json) {
  if (json case {
    'totalEcts': final num total,
    'passedEcts': final num passed,
    'percent': final num percent,
  }) {
    return StudyProgress(
      totalEcts: total.toDouble(),
      passedEcts: passed.toDouble(),
      percent: percent.toDouble(),
      average: asDouble(json['average']),
      inProgress: [
        if (json['inProgress'] case final List<Object?> list)
          for (final m in list)
            if (m case {'name': final String n}) n,
      ],
    );
  }
  return null;
}

/// Maps `GET /api/briefing`: one section per kind, titled by the kind.
List<FeedSection>? parseBriefing(Object? json) {
  if (json case {'sections': final Object? sections}) {
    return listOf<FeedSection>(sections, (s) {
      if (s case {'kind': final String kind, 'items': final Object? items}) {
        final mapped = listOf<FeedItem>(items, (i) {
          if (i case {'text': final String text}) {
            return FeedItem(
              title: text,
              detail: _s(i['detail']),
              at: asDateTime(i['at'])?.toLocal(),
              tone: _tone(i['severity']),
            );
          }
          return null;
        });
        if (mapped == null) return null;
        return FeedSection(
          title: 'briefing.$kind',
          items: mapped,
          more: (s['more'] as num?)?.toInt() ?? 0,
        );
      }
      return null;
    });
  }
  return null;
}

/// Maps `GET /api/arr/overview`: health warnings, upcoming, queue.
List<FeedSection>? parseArr(Object? json) {
  if (json is! Map<String, Object?>) return null;
  List<FeedItem> items(
    String key,
    FeedItem? Function(Map<String, Object?>) f,
  ) => [
    if (json[key] case final List<Object?> list)
      for (final e in list)
        if (e is Map<String, Object?>) ?f(e),
  ];
  return [
    FeedSection(
      title: 'arr.health',
      items: items(
        'health',
        (e) => FeedItem(
          title: _s(e['message']),
          detail: _s(e['instance']),
          tone: _tone(e['severity']),
        ),
      ),
    ),
    FeedSection(
      title: 'arr.upcoming',
      items: items(
        'upcoming',
        (e) => FeedItem(
          title: _s(e['title']),
          detail: _s(e['detail']),
          at: asDateTime(e['date'])?.toLocal(),
        ),
      ),
    ),
    FeedSection(
      title: 'arr.queue',
      items: items(
        'queue',
        (e) => FeedItem(
          title: _s(e['title']),
          detail:
              '${_s(e['instance'])} · ${(e['progress'] as num?)?.round() ?? 0} %',
          tone: _s(e['error']).isEmpty ? FeedTone.neutral : FeedTone.critical,
        ),
      ),
    ),
  ].where((s) => s.items.isNotEmpty).toList();
}

/// Maps `GET /api/media/overview`: playing now, then recently added.
List<FeedSection>? parseMedia(Object? json) {
  if (json is! Map<String, Object?>) return null;
  String title(Map<String, Object?> e) {
    final series = _s(e['series']);
    return series.isEmpty ? _s(e['title']) : '$series · ${_s(e['title'])}';
  }

  return [
    FeedSection(
      title: 'media.playing',
      items: [
        if (json['sessions'] case final List<Object?> list)
          for (final e in list)
            if (e is Map<String, Object?>)
              FeedItem(
                title: title(e),
                detail: '${_s(e['user'])} · ${_s(e['device'])}',
              ),
      ],
    ),
    FeedSection(
      title: 'media.recent',
      items: [
        if (json['recent'] case final List<Object?> list)
          for (final e in list)
            if (e is Map<String, Object?>)
              FeedItem(
                title: title(e),
                detail: switch (e['year']) {
                  final int y => '$y',
                  _ => '',
                },
                at: asDateTime(e['addedAt'])?.toLocal(),
              ),
      ],
    ),
  ].where((s) => s.items.isNotEmpty).toList();
}

/// Maps `GET /api/releases`.
List<FeedSection>? parseReleases(Object? json) {
  if (json case {'releases': final List<Object?> list}) {
    return [
      FeedSection(
        title: '',
        items: [
          for (final e in list)
            if (e is Map<String, Object?>)
              FeedItem(
                title: '${_s(e['artist'])} – ${_s(e['title'])}',
                detail: _s(e['type']),
                at: asDay(e['date']),
              ),
        ],
      ),
    ];
  }
  return null;
}

/// Maps `GET /api/gamedeals/overview`: free now, deals, free next.
List<FeedSection>? parseGameDeals(Object? json) {
  if (json is! Map<String, Object?>) return null;
  List<FeedItem> free(String key) => [
    if (json[key] case final List<Object?> list)
      for (final e in list)
        if (e is Map<String, Object?>)
          FeedItem(
            title: _s(e['title']),
            at: asDateTime(e[key == 'freeNow' ? 'end' : 'start'])?.toLocal(),
            url: _url(e['url']),
          ),
  ];
  return [
    FeedSection(title: 'gamedeals.free', items: free('freeNow')),
    FeedSection(
      title: 'gamedeals.deals',
      items: [
        if (json['deals'] case final List<Object?> list)
          for (final e in list)
            if (e is Map<String, Object?>)
              FeedItem(
                title: _s(e['name']),
                detail:
                    '-${(e['discountPct'] as num?)?.round() ?? 0} % · ${_s(e['finalPrice'])}',
                at: asDateTime(e['endsAt'])?.toLocal(),
                url: _url(e['url']),
              ),
      ],
    ),
    FeedSection(title: 'gamedeals.next', items: free('freeNext')),
  ].where((s) => s.items.isNotEmpty).toList();
}

/// Maps `GET /api/space/launches`.
List<FeedSection>? parseLaunches(Object? json) {
  final items = listOf<FeedItem>(json, (e) {
    if (e case {'mission': final String mission, 'net': final String net}) {
      return FeedItem(
        title: mission,
        detail: '${_s(e['rocket'])} · ${_s(e['provider'])}',
        at: DateTime.tryParse(net)?.toLocal(),
        tone: e['webcastLive'] == true ? FeedTone.warning : FeedTone.neutral,
      );
    }
    return null;
  });
  return items == null ? null : [FeedSection(title: '', items: items)];
}

/// `GET /api/immich/overview`.
const immichQuery = WidgetQuery<AppOverview>(
  '/api/immich/overview',
  parseImmich,
);

/// `GET /api/nextcloud/status`.
const nextcloudQuery = WidgetQuery<AppOverview>(
  '/api/nextcloud/status',
  parseNextcloud,
);

int? _int(Object? v) => v is num ? v.toInt() : null;

/// Maps `GET /api/immich/overview`.
AppOverview? parseImmich(Object? json) {
  if (json is! Map<String, Object?>) return null;
  return AppOverview(
    version: _s(json['version']),
    photos: _int(json['photos']),
    videos: _int(json['videos']),
    storageUsed: _int(json['diskUsed']),
    storageTotal: _int(json['diskTotal']),
    storagePercent: asDouble(json['diskPercent']),
  );
}

/// Maps `GET /api/nextcloud/status`; the server part is only there for
/// admins.
AppOverview? parseNextcloud(Object? json) {
  if (json is! Map<String, Object?>) return null;
  final quota = json['quota'];
  final server = json['server'];
  return AppOverview(
    version: _s(json['version']),
    maintenance: json['maintenance'] == true,
    users: server is Map<String, Object?> ? _int(server['users']) : null,
    appUpdates: server is Map<String, Object?>
        ? _int(server['appUpdates'])
        : null,
    storageUsed: quota is Map<String, Object?> ? _int(quota['used']) : null,
    storageTotal: quota is Map<String, Object?> ? _int(quota['total']) : null,
    storagePercent: quota is Map<String, Object?>
        ? asDouble(quota['percent'])
        : null,
  );
}

/// `GET /api/sports/overview`; `league` comes from the widget's settings
/// ("bl1" like the web interface when none is set).
const sportsQuery = WidgetQuery<LeagueTable>(
  '/api/sports/overview',
  parseSports,
  query: {'league': 'bl1'},
);

/// Maps `GET /api/sports/overview`.
LeagueTable? parseSports(Object? json) {
  if (json case {
    'league': {'name': final String league},
    'table': final Object? table,
  }) {
    final rows = listOf<LeagueRow>(table, (r) {
      if (r case {
        'position': final int position,
        'team': final Map<String, Object?> team,
        'points': final int points,
        'played': final int played,
      }) {
        final short = _s(team['shortName']);
        return LeagueRow(
          position: position,
          team: short.isNotEmpty ? short : _s(team['name']),
          points: points,
          played: played,
        );
      }
      return null;
    });
    return rows == null ? null : LeagueTable(league: league, rows: rows);
  }
  return null;
}
