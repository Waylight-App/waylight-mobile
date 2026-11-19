/// The push service a phone is reached through (server ADR 0025).
enum PushPlatform {
  /// Google Firebase Cloud Messaging (Android).
  fcm,

  /// Apple Push Notification service (iOS).
  apns,
}

/// What a push notification shows, after the device decrypted it.
final class PushContent {
  /// Creates the content.
  const PushContent({required this.title, required this.body, this.link});

  /// The title, such as "Backup failed".
  final String title;

  /// The text below the title.
  final String body;

  /// A `waylight://` link to open on tap, if any.
  final Uri? link;
}
