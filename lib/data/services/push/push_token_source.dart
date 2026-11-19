import 'package:waylight_mobile/domain/models/push.dart';

/// Where the phone's push token comes from: Firebase Cloud Messaging on
/// Android, APNs on iOS.
///
/// An interface, because the push services are native code that not every
/// build contains; a build without them uses [NoPushTokenSource].
abstract interface class PushTokenSource {
  /// Whether this build can receive push notifications at all.
  bool get available;

  /// The push service of the token.
  PushPlatform get platform;

  /// Asks for the notification permission if needed and returns the
  /// token; `null` if the permission was denied or no token is available.
  Future<String?> token();
}

/// A [PushTokenSource] for builds without push services.
final class NoPushTokenSource implements PushTokenSource {
  /// Creates the source.
  const NoPushTokenSource();

  @override
  bool get available => false;

  @override
  PushPlatform get platform => PushPlatform.fcm;

  @override
  Future<String?> token() async => null;
}
