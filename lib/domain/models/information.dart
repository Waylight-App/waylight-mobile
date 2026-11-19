/// A fuel station with its price (`GET /api/fuel/overview`).
final class FuelStation {
  /// Creates the station.
  const FuelStation({
    required this.name,
    required this.brand,
    required this.address,
    required this.open,
    this.price,
    this.distanceKm,
  });

  /// The station's name.
  final String name;

  /// The brand, such as "JET".
  final String brand;

  /// The address, for the maps app.
  final String address;

  /// Whether it is open now.
  final bool open;

  /// The price in euro per litre of the chosen fuel, if known.
  final double? price;

  /// The distance from the configured place.
  final double? distanceKm;
}

/// Fuel prices around a place or of the favourites.
final class FuelOverview {
  /// Creates the overview.
  const FuelOverview({
    required this.fuel,
    required this.place,
    required this.stations,
  });

  /// The fuel, such as "e10".
  final String fuel;

  /// The place the cheapest stations are around.
  final String place;

  /// The favourites if there are any, else the cheapest stations.
  final List<FuelStation> stations;
}

/// A value of the markets watchlist (`GET /api/markets/watchlist`).
final class MarketQuote {
  /// Creates the quote.
  const MarketQuote({
    required this.symbol,
    this.value,
    this.changePercent,
    this.history = const [],
  });

  /// The symbol as configured, such as "stooq:^dax".
  final String symbol;

  /// The last value, if known.
  final double? value;

  /// The change against the day before in percent.
  final double? changePercent;

  /// The values of the last weeks, oldest first, for a sparkline.
  final List<double> history;
}

/// A line of a generic list widget: title, detail, date and a link.
final class FeedItem {
  /// Creates the item.
  const FeedItem({
    required this.title,
    this.detail = '',
    this.at,
    this.url,
    this.tone = FeedTone.neutral,
  });

  /// The main text.
  final String title;

  /// A second line.
  final String detail;

  /// The date that belongs to it.
  final DateTime? at;

  /// What tapping opens.
  final Uri? url;

  /// How urgent it is.
  final FeedTone tone;
}

/// How urgent a [FeedItem] is.
enum FeedTone {
  /// Nothing special.
  neutral,

  /// Needs attention.
  warning,

  /// A problem.
  critical,
}

/// A titled group of [FeedItem]s, such as the sections of the briefing or
/// the upcoming episodes and the queue of Sonarr.
final class FeedSection {
  /// Creates the section.
  const FeedSection({required this.title, required this.items, this.more = 0});

  /// The heading; the server's key where the app translates it.
  final String title;

  /// The lines.
  final List<FeedItem> items;

  /// How many more lines the server left out.
  final int more;
}

/// A calendar event (`GET /api/calendar/events`).
final class CalendarEvent {
  /// Creates the event.
  const CalendarEvent({
    required this.summary,
    required this.start,
    required this.end,
    this.allDay = false,
    this.location = '',
    this.calendar = '',
  });

  /// The title.
  final String summary;

  /// The start.
  final DateTime start;

  /// The end.
  final DateTime end;

  /// Whether it lasts whole days.
  final bool allDay;

  /// Where it takes place.
  final String location;

  /// The name of its calendar.
  final String calendar;
}

/// An entry of the phone list (`GET /api/phonelist/entries`).
final class PhoneEntry {
  /// Creates the entry.
  const PhoneEntry({
    required this.name,
    this.role = '',
    this.team = '',
    this.phone = '',
    this.dial = '',
    this.email = '',
  });

  /// The person or place.
  final String name;

  /// The role and the team.
  final String role;

  /// The team.
  final String team;

  /// The number as written and as dialled.
  final String phone;

  /// The number to dial, without spaces.
  final String dial;

  /// The e-mail address.
  final String email;
}

/// Progress of a degree (`GET /api/study/progress`).
final class StudyProgress {
  /// Creates the progress.
  const StudyProgress({
    required this.totalEcts,
    required this.passedEcts,
    required this.percent,
    this.average,
    this.inProgress = const [],
  });

  /// The credits needed and passed.
  final double totalEcts;

  /// The credits passed.
  final double passedEcts;

  /// Passed share in percent.
  final double percent;

  /// The weighted grade average, if there are grades.
  final double? average;

  /// The modules in progress.
  final List<String> inProgress;
}

/// Library or account facts of a self-hosted app (`GET /api/immich/overview`,
/// `GET /api/nextcloud/status`).
final class AppOverview {
  /// Creates the overview.
  const AppOverview({
    this.version = '',
    this.photos,
    this.videos,
    this.users,
    this.appUpdates,
    this.maintenance = false,
    this.storageUsed,
    this.storageTotal,
    this.storagePercent,
  });

  /// The app's version.
  final String version;

  /// Photos and videos of an Immich library.
  final int? photos;

  /// Videos of an Immich library.
  final int? videos;

  /// Accounts of a Nextcloud, for admins.
  final int? users;

  /// Pending app updates of a Nextcloud, for admins.
  final int? appUpdates;

  /// Whether Nextcloud is in maintenance mode.
  final bool maintenance;

  /// Used and total storage in bytes, and the share in percent.
  final int? storageUsed;

  /// Total storage in bytes.
  final int? storageTotal;

  /// Used storage in percent.
  final double? storagePercent;
}

/// The table of a league (`GET /api/sports/overview`).
final class LeagueTable {
  /// Creates the table.
  const LeagueTable({required this.league, required this.rows});

  /// The league's name, such as "1. Bundesliga".
  final String league;

  /// The top of the table.
  final List<LeagueRow> rows;
}

/// A line of [LeagueTable].
final class LeagueRow {
  /// Creates the line.
  const LeagueRow({
    required this.position,
    required this.team,
    required this.points,
    required this.played,
  });

  /// The place in the table.
  final int position;

  /// The team's short name.
  final String team;

  /// Points.
  final int points;

  /// Games played.
  final int played;
}
