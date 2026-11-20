import 'package:waylight_mobile/data/services/logging/log_store.dart';
import 'package:waylight_mobile/domain/models/diagnostics.dart';

/// A [LogStore] in memory for tests.
class FakeLogStore implements LogStore {
  /// The stored records.
  final List<LogEntry> stored = [];

  @override
  Future<void> add(LogEntry entry) async => stored.add(entry);

  @override
  Future<List<LogEntry>> entries() async => List.of(stored);

  @override
  Future<void> clear() async => stored.clear();
}
