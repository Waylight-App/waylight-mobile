import 'package:waylight_mobile/data/services/storage/key_value_store.dart';

/// A [KeyValueStore] in memory for tests.
class InMemoryKeyValueStore implements KeyValueStore {
  /// The stored values; tests may read and prefill them.
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}
