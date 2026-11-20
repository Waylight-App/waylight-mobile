/// The push service a phone is reached through (server ADR 0025).
enum PushPlatform {
  /// The relay's Server-Sent Events stream (Android, server ADR 0027).
  sse,

  /// Apple Push Notification service (iOS).
  apns,
}
