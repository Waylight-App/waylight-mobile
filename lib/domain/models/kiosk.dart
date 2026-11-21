import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The display options of a kiosk display (`GET /api/auth/kiosk`, #193).
final class KioskOptions {
  /// Creates the options.
  const KioskOptions({
    this.rotateSeconds = 0,
    this.nightFrom = '',
    this.nightTo = '',
  });

  /// Seconds per tab; 0 means no rotation.
  final int rotateSeconds;

  /// Start of night dimming as "HH:MM"; empty means never dimmed.
  final String nightFrom;

  /// End of night dimming as "HH:MM".
  final String nightTo;

  /// Whether the screen is dimmed at [now]. A window like 22:00–06:30 runs
  /// over midnight, as on the server's web page.
  bool nightAt(DateTime now) {
    final from = _minutes(nightFrom);
    final to = _minutes(nightTo);
    if (from == null || to == null || from == to) return false;
    final m = now.hour * 60 + now.minute;
    return from < to ? m >= from && m < to : m >= from || m < to;
  }

  static int? _minutes(String hhmm) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(hhmm);
    if (match == null) return null;
    final h = int.parse(match[1]!);
    final m = int.parse(match[2]!);
    return h < 24 && m < 60 ? h * 60 + m : null;
  }

  @override
  bool operator ==(Object other) =>
      other is KioskOptions &&
      other.rotateSeconds == rotateSeconds &&
      other.nightFrom == nightFrom &&
      other.nightTo == nightTo;

  @override
  int get hashCode => Object.hash(rotateSeconds, nightFrom, nightTo);
}

/// The link of a kiosk display could not be read.
final class InvalidKioskLink implements Exception {
  /// Creates the exception.
  const InvalidKioskLink();
}

/// A kiosk link as the server shows it: `https://host/kiosk#<token>` (#193).
/// The token travels in the fragment, so it never reaches server logs.
typedef KioskLink = ({ServerAddress server, String token});

/// Reads a pasted or scanned kiosk link.
Result<KioskLink> parseKioskLink(String input) {
  final uri = Uri.tryParse(input.trim());
  if (uri == null || !uri.path.endsWith('/kiosk') || uri.fragment.isEmpty) {
    return const Result.error(InvalidKioskLink());
  }
  final base = uri.replace(
    path: uri.path.substring(0, uri.path.length - '/kiosk'.length),
    fragment: '',
  );
  final text = base.toString().replaceAll(RegExp(r'#$'), '');
  return switch (ServerAddress.parse(text)) {
    Ok(value: final server) => Result.ok((
      server: server,
      token: Uri.decodeComponent(uri.fragment),
    )),
    Error(:final error) => Result.error(error),
  };
}
