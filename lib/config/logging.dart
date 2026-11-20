import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import 'package:waylight_mobile/data/services/logging/log_store.dart';

/// Sends every log record to the Dart developer log and, when [store] is
/// given, keeps it on the device for a diagnostic report (#197).
///
/// Debug builds log everything, release builds only warnings and worse.
/// Messages must never contain passwords, tokens or cookies
/// (docs/security.md); the store redacts them again before writing.
void setupLogging({LogStore? store}) {
  Logger.root.level = kReleaseMode ? Level.WARNING : Level.ALL;
  Logger.root.onRecord.listen((record) {
    developer.log(
      record.message,
      time: record.time,
      level: record.level.value,
      name: record.loggerName,
      error: record.error,
      stackTrace: record.stackTrace,
    );
    if (store != null && record.level >= Level.INFO) {
      store.add(entryFromRecord(record)).ignore();
    }
  });
}
