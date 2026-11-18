// Fails when the line coverage of lib/ (without generated code) is below a
// minimum. Usage: dart run tool/check_coverage.dart [coverage/lcov.info] [80]
//
// Kept as a small script instead of lcov or a package, so `make ci` works
// the same on every machine (docs/testing.md).
import 'dart:io';

void main(List<String> args) {
  final file = File(args.isNotEmpty ? args[0] : 'coverage/lcov.info');
  final minimum = args.length > 1 ? double.parse(args[1]) : 80.0;
  if (!file.existsSync()) {
    stderr.writeln('${file.path} not found; run `flutter test --coverage`.');
    exit(2);
  }

  var found = 0;
  var hit = 0;
  var skip = false;
  for (final line in file.readAsLinesSync()) {
    if (line.startsWith('SF:')) {
      skip = line.contains('/generated/') || line.endsWith('.g.dart');
    } else if (!skip && line.startsWith('DA:')) {
      found++;
      if (!line.endsWith(',0')) hit++;
    }
  }

  final percent = found == 0 ? 100.0 : hit * 100 / found;
  final summary =
      'Line coverage: ${percent.toStringAsFixed(1)} % '
      '($hit of $found lines, minimum $minimum %)';
  if (percent < minimum) {
    stderr.writeln(summary);
    exit(1);
  }
  stdout.writeln(summary);
}
