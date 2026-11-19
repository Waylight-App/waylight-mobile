/// The NASA Astronomy Picture of the Day (`GET /api/space/apod`).
final class Apod {
  /// Creates the picture.
  const Apod({
    required this.title,
    required this.imagePath,
    this.explanation = '',
    this.link,
  });

  /// The title.
  final String title;

  /// The server's path of the image; empty for a video.
  final String imagePath;

  /// NASA's explanation.
  final String explanation;

  /// The page at NASA.
  final Uri? link;
}

/// Values of a custom JSON endpoint (`GET /api/apiwidget/endpoints/{id}/values`).
final class ApiValues {
  /// Creates the values.
  const ApiValues({required this.name, required this.values});

  /// The endpoint's name.
  final String name;

  /// The values in order.
  final List<ApiValue> values;
}

/// One value of [ApiValues].
final class ApiValue {
  /// Creates the value.
  const ApiValue({
    required this.label,
    required this.text,
    this.unit = '',
    this.status = 'ok',
  });

  /// What it is.
  final String label;

  /// The value as text.
  final String text;

  /// Its unit.
  final String unit;

  /// "ok", "warning" or "critical" from the owner's thresholds, or "error".
  final String status;
}

/// Unread mail (`GET /api/mail/inbox`).
final class Inbox {
  /// Creates the inbox.
  const Inbox({required this.unread, required this.messages, this.webmail});

  /// How many messages are unread.
  final int unread;

  /// The newest unread messages.
  final List<MailHeader> messages;

  /// The web mail, if set.
  final Uri? webmail;
}

/// The header of an unread message.
final class MailHeader {
  /// Creates the header.
  const MailHeader({required this.from, required this.subject, this.date});

  /// The sender.
  final String from;

  /// The subject.
  final String subject;

  /// When it arrived.
  final DateTime? date;
}

/// An item of the drop zone (`GET /api/drop`).
final class Drop {
  /// Creates the item.
  const Drop({
    required this.id,
    required this.isFile,
    this.text = '',
    this.fileName = '',
    this.size = 0,
    this.expiresAt,
  });

  /// The server's id.
  final String id;

  /// Whether it is a file (else text or a link).
  final bool isFile;

  /// The text or link.
  final String text;

  /// The file's name.
  final String fileName;

  /// The size in bytes.
  final int size;

  /// When it disappears.
  final DateTime? expiresAt;
}

/// Focus time per day (`GET /api/focus/stats`).
final class FocusDay {
  /// Creates the day.
  const FocusDay({
    required this.date,
    required this.minutes,
    this.sessions = 0,
  });

  /// The day.
  final DateTime date;

  /// Focus minutes.
  final int minutes;

  /// Finished sessions.
  final int sessions;
}
