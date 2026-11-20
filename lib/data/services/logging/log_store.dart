import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';

import 'package:waylight_mobile/domain/models/diagnostics.dart';
import 'package:waylight_mobile/utils/redact.dart';

/// Keeps the last log records on the device for a diagnostic report
/// (#197). Messages are redacted before they are stored.
abstract interface class LogStore {
  /// Stores one record.
  Future<void> add(LogEntry entry);

  /// The stored records, oldest first.
  Future<List<LogEntry>> entries();

  /// Deletes all records, e.g. when signing out.
  Future<void> clear();
}

/// Maps a record of the `logging` package to a [LogEntry]; the error's
/// type and text are appended to the message.
LogEntry entryFromRecord(LogRecord record) {
  final error = record.error;
  return LogEntry(
    time: record.time,
    level: record.level.name,
    logger: record.loggerName,
    message: error == null
        ? record.message
        : '${record.message} (${error.runtimeType}: $error)',
  );
}

/// A [LogStore] in a file of JSON lines with a fixed number of records:
/// when it is full, the oldest half is dropped.
class FileLogStore implements LogStore {
  /// Creates the store; the function resolves the file lazily.
  FileLogStore(this._file, {this.maxEntries = 300});

  final Future<File> Function() _file;

  /// How many records the file keeps at most.
  final int maxEntries;

  // Writes are chained, so records keep their order and never interleave.
  Future<void> _queue = Future.value();

  @override
  Future<void> add(LogEntry entry) => _queue = _queue
      .then((_) async {
        final redacted = LogEntry(
          time: entry.time,
          level: entry.level,
          logger: entry.logger,
          message: redact(entry.message),
        );
        final file = await _file();
        final lines = await file.exists()
            ? await file.readAsLines()
            : <String>[];
        lines.add(jsonEncode(_toJson(redacted)));
        final keep = lines.length > maxEntries
            ? lines.sublist(lines.length - maxEntries ~/ 2)
            : lines;
        await file.parent.create(recursive: true);
        await file.writeAsString('${keep.join('\n')}\n', flush: true);
      })
      .catchError((Object _) {
        // A full disk must not break the app; the record is lost.
      });

  @override
  Future<List<LogEntry>> entries() async {
    await _queue;
    final file = await _file();
    if (!await file.exists()) return const [];
    return [for (final line in await file.readAsLines()) ?_fromJson(line)];
  }

  @override
  Future<void> clear() => _queue = _queue.then((_) async {
    final file = await _file();
    if (await file.exists()) await file.delete();
  });

  static Map<String, Object?> _toJson(LogEntry e) => {
    't': e.time.toUtc().toIso8601String(),
    'l': e.level,
    'n': e.logger,
    'm': e.message,
  };

  static LogEntry? _fromJson(String line) {
    try {
      if (jsonDecode(line) case {
        't': final String t,
        'l': final String l,
        'n': final String n,
        'm': final String m,
      }) {
        final time = DateTime.tryParse(t);
        if (time != null) {
          return LogEntry(time: time, level: l, logger: n, message: m);
        }
      }
    } on FormatException {
      // A line cut off by a crash is skipped.
    }
    return null;
  }
}
