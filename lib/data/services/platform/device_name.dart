import 'dart:io';

/// A name for this device in the session list of the web interface, e.g.
/// "Android" or "iPhone". It only helps the user to tell devices apart.
String deviceName() => switch (Platform.operatingSystem) {
  'ios' => 'iPhone',
  'android' => 'Android',
  final other => other,
};
