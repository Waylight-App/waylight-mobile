/// A countdown to a date (`GET /api/countdowns`).
final class Countdown {
  /// Creates the countdown.
  const Countdown({
    required this.title,
    required this.date,
    this.emoji = '',
    this.time,
  });

  /// What it counts down to.
  final String title;

  /// The day, as a local date without time.
  final DateTime date;

  /// An emoji, or empty.
  final String emoji;

  /// The time of day as written by the server ("08:30"), if any.
  final String? time;

  /// Whole days from [today] to [date]; negative once it is over.
  int daysFrom(DateTime today) => DateTime.utc(
    date.year,
    date.month,
    date.day,
  ).difference(DateTime.utc(today.year, today.month, today.day)).inDays;
}

/// The next birthday of a person (`GET /api/birthdays`).
final class Birthday {
  /// Creates the birthday.
  const Birthday({
    required this.name,
    required this.next,
    required this.inDays,
    this.age,
  });

  /// The person's name.
  final String name;

  /// The date of the next birthday.
  final DateTime next;

  /// Days until then; 0 is today. Counted by the server.
  final int inDays;

  /// The age on that day, if the year of birth is known.
  final int? age;
}

/// Hourly electricity prices (`GET /api/electricity/prices`).
final class ElectricityPrices {
  /// Creates the prices.
  const ElectricityPrices({
    required this.zone,
    required this.hours,
    this.stale = false,
  });

  /// The bidding zone, such as "DE-LU".
  final String zone;

  /// Today's and, once published, tomorrow's hours.
  final List<PriceHour> hours;

  /// Whether the server shows its last known prices after a failure.
  final bool stale;

  /// The hour that contains [now], if any.
  PriceHour? at(DateTime now) {
    for (final h in hours) {
      if (!now.isBefore(h.start) &&
          now.isBefore(h.start.add(const Duration(hours: 1)))) {
        return h;
      }
    }
    return null;
  }
}

/// The price of one hour.
final class PriceHour {
  /// Creates the hour.
  const PriceHour({
    required this.start,
    required this.centPerKWh,
    this.cheapest = false,
  });

  /// The start of the hour.
  final DateTime start;

  /// The price in cent per kWh, without taxes and fees.
  final double centPerKWh;

  /// Whether it is one of the cheapest hours of its day.
  final bool cheapest;
}

/// A public or school holiday (`GET /api/holidays`).
final class Holiday {
  /// Creates the holiday.
  const Holiday({
    required this.school,
    required this.start,
    required this.end,
    required this.daysUntil,
    this.key = '',
    this.name = '',
    this.current = false,
  });

  /// Whether it is a school holiday (else a public holiday).
  final bool school;

  /// The public holiday's key, such as "christmas_day", which the app
  /// translates; empty for school holidays.
  final String key;

  /// The name from the school holiday calendar; empty for public holidays.
  final String name;

  /// The first day.
  final DateTime start;

  /// The last day.
  final DateTime end;

  /// Days until it starts; 0 while it lasts.
  final int daysUntil;

  /// Whether it is going on now.
  final bool current;
}
