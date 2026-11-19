import 'dart:convert';
import 'dart:io';

/// A stored answer of the server and when it was received.
typedef CachedResponse = ({String body, DateTime storedAt});

/// The last answers of read endpoints, for offline use (#23, ADR 0007).
abstract interface class ResponseCache {
  /// The stored answer for [uri], or `null`.
  Future<CachedResponse?> read(Uri uri);

  /// Stores [body] as the answer for [uri].
  Future<void> write(Uri uri, String body, DateTime storedAt);

  /// Deletes every stored answer, e.g. when signing out.
  Future<void> clear();
}

/// A [ResponseCache] with one file per address in a private directory.
///
/// The file name is a hash of the address, so addresses with tokens or
/// names never appear in file names. When the files exceed `maxBytes`, the
/// oldest are deleted.
final class FileResponseCache implements ResponseCache {
  /// Creates the cache in the directory the given function returns.
  FileResponseCache(this._directory, {this.maxBytes = 5 * 1024 * 1024});

  final Future<Directory> Function() _directory;

  /// The most the cache may use on the device.
  final int maxBytes;

  Future<File> _file(Uri uri) async {
    final dir = await _directory();
    final name = _fnv1a(uri.toString()).toRadixString(16);
    return File('${dir.path}/$name.json');
  }

  @override
  Future<CachedResponse?> read(Uri uri) async {
    try {
      final file = await _file(uri);
      if (!file.existsSync()) return null;
      final json = jsonDecode(await file.readAsString());
      if (json case {'storedAt': final String at, 'body': final String body}) {
        final storedAt = DateTime.tryParse(at);
        if (storedAt != null) return (body: body, storedAt: storedAt);
      }
    } on Exception {
      // A damaged file is a miss; it is overwritten with the next answer.
    }
    return null;
  }

  @override
  Future<void> write(Uri uri, String body, DateTime storedAt) async {
    try {
      final file = await _file(uri);
      await file.parent.create(recursive: true);
      await file.writeAsString(
        jsonEncode({'storedAt': storedAt.toIso8601String(), 'body': body}),
        flush: true,
      );
      await _trim(file.parent);
    } on Exception {
      // Without space the app works on, just without an offline copy.
    }
  }

  Future<void> _trim(Directory dir) async {
    final files = dir.listSync().whereType<File>().toList()
      ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    var total = 0;
    for (final file in files) {
      total += file.lengthSync();
      if (total > maxBytes) file.deleteSync();
    }
  }

  @override
  Future<void> clear() async {
    try {
      final dir = await _directory();
      if (dir.existsSync()) await dir.delete(recursive: true);
    } on Exception {
      // Nothing to delete.
    }
  }
}

// FNV-1a, 64 bit: a short, stable name for a file per address, so the
// address itself is not visible in the directory listing.
int _fnv1a(String text) {
  var hash = 0xcbf29ce484222325;
  for (final byte in utf8.encode(text)) {
    hash ^= byte;
    hash *= 0x100000001b3;
  }
  return hash.toUnsigned(64);
}
