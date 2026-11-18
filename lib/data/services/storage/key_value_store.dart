import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores small strings on the device, such as the server address.
///
/// An interface, so repositories can be tested with an in-memory fake.
abstract interface class KeyValueStore {
  /// The value of [key], or `null` if nothing is stored.
  Future<String?> read(String key);

  /// Stores [value] under [key], replacing an earlier value.
  Future<void> write(String key, String value);

  /// Removes [key]; does nothing if it is not stored.
  Future<void> delete(String key);
}

/// A [KeyValueStore] in the iOS Keychain and the Android Keystore, through
/// [FlutterSecureStorage].
///
/// Used for everything the app keeps, because sessions and tokens belong
/// there and one store is easier to reason about than two
/// (docs/security.md).
final class SecureKeyValueStore implements KeyValueStore {
  /// Creates a store backed by the given storage.
  const SecureKeyValueStore([this._storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}
