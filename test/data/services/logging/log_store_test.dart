import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:waylight_mobile/data/services/logging/log_store.dart';
import 'package:waylight_mobile/domain/models/diagnostics.dart';

void main() {
  late Directory dir;
  late File file;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('logstore');
    file = File('${dir.path}/diagnostics.log');
  });
  tearDown(() => dir.delete(recursive: true));

  LogEntry entry(int i, [String message = 'event']) => LogEntry(
    time: DateTime.utc(2026, 11, 20, 12, 0, i),
    level: 'WARNING',
    logger: 'Test',
    message: '$message $i',
  );

  test('stores records redacted and in order', () async {
    final store = FileLogStore(() async => file);
    await store.add(entry(1, 'GET https://nas.home/api failed'));
    await store.add(entry(2));
    final got = await store.entries();
    expect(got.map((e) => e.message), ['GET <address> failed 1', 'event 2']);
    expect(await file.readAsString(), isNot(contains('nas.home')));
  });

  test('drops the oldest half when full', () async {
    final store = FileLogStore(() async => file, maxEntries: 10);
    for (var i = 0; i < 11; i++) {
      store.add(entry(i)).ignore();
    }
    final got = await store.entries();
    expect(got.length, 5);
    expect(got.last.message, 'event 10');
  });

  test('skips broken lines and clears the file', () async {
    final store = FileLogStore(() async => file);
    await store.add(entry(1));
    await file.writeAsString('{"t": broken\n', mode: FileMode.append);
    expect((await store.entries()).length, 1);
    await store.clear();
    expect(await store.entries(), isEmpty);
    expect(await file.exists(), isFalse);
  });
}
