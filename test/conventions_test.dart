// Enforces the code conventions that the analyzer cannot check
// (docs/code-conventions.md). A failure names the file, the line and the
// rule; fix the code, not the rule.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A rule: lines matching [pattern] are not allowed outside [allowedIn].
final class _Rule {
  const _Rule(this.name, this.pattern, {this.allowedIn = const []});

  final String name;
  final RegExp pattern;

  /// Paths below lib/ where the pattern is allowed.
  final List<String> allowedIn;
}

final _rules = [
  _Rule(
    'colours come from the theme (Theme.of, StatusColors.of), not literals',
    RegExp(r'\bColor\(0x|\bColors\.(?!transparent\b)'),
    allowedIn: ['ui/core/themes/'],
  ),
  _Rule(
    'text sizes come from the text theme, not fontSize',
    RegExp(r'\bfontSize\s*:'),
    allowedIn: ['ui/core/themes/'],
  ),
  _Rule(
    'log with package:logging, never print or debugPrint',
    RegExp(r'\b(print|debugPrint)\('),
  ),
  _Rule('TODOs name their issue: TODO(#12)', RegExp(r'//\s*TODO(?!\(#\d+\))')),
  _Rule(
    'navigate with the route constants in routing/routes.dart',
    RegExp(r'''context\.(go|push)\(\s*['"]'''),
  ),
];

void main() {
  final files = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !f.path.contains('/generated/'));

  for (final rule in _rules) {
    test(rule.name, () {
      final violations = <String>[];
      for (final file in files) {
        final path = file.path.replaceAll(r'\', '/').substring('lib/'.length);
        if (rule.allowedIn.any(path.startsWith)) continue;
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (line.trimLeft().startsWith('///')) continue;
          if (rule.pattern.hasMatch(line)) {
            violations.add('lib/$path:${i + 1}: ${line.trim()}');
          }
        }
      }
      expect(violations, isEmpty, reason: violations.join('\n'));
    });
  }
}
