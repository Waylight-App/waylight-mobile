import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:waylight_mobile/utils/command.dart';
import 'package:waylight_mobile/utils/result.dart';

void main() {
  group('Command0', () {
    test('reports running, then the successful result', () async {
      final gate = Completer<Result<int>>();
      final command = Command0(() => gate.future);

      final run = command.execute();
      expect(command.running, isTrue);
      expect(command.result, isNull);

      gate.complete(const Result.ok(42));
      await run;
      expect(command.running, isFalse);
      expect(command.completed, isTrue);
      expect(command.error, isFalse);
      expect((command.result! as Ok<int>).value, 42);
    });

    test('reports a failure as error', () async {
      final command = Command0<int>(
        () async => Result.error(Exception('boom')),
      );

      await command.execute();

      expect(command.error, isTrue);
      expect(command.completed, isFalse);
    });

    test('ignores a second run while the first is in progress', () async {
      var calls = 0;
      final gate = Completer<Result<void>>();
      final command = Command0(() {
        calls++;
        return gate.future;
      });

      final first = command.execute();
      await command.execute();
      gate.complete(const Result.ok(null));
      await first;

      expect(calls, 1);
    });

    test('clearResult forgets the last result', () async {
      final command = Command0(() async => const Result.ok(1));
      await command.execute();

      command.clearResult();

      expect(command.result, isNull);
    });
  });

  test('Command1 passes its argument to the action', () async {
    final command = Command1<String, int>(
      (value) async => Result.ok('got $value'),
    );

    await command.execute(7);

    expect((command.result! as Ok<String>).value, 'got 7');
  });
}
