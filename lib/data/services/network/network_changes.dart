import 'package:flutter/services.dart';

/// Fires when the phone's default network changes, e.g. on joining or
/// leaving the home Wi-Fi (#189). Reads no network name, so it needs no
/// location permission. Where the native side is missing (tests, the
/// background engine) the stream stays silent.
Stream<void> networkChanges({
  EventChannel channel = const EventChannel('app.waylight/network'),
}) => channel
    .receiveBroadcastStream()
    .map((_) {})
    .handleError(
      (Object _) {},
      test: (e) => e is MissingPluginException || e is PlatformException,
    );
