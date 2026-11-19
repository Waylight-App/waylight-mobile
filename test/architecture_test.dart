// Enforces the layers of docs/architecture.md: every import in lib/ must be
// allowed by the rules below. A failing test names the file, the import and
// the rule; fix the code, not the rule. Changing a rule needs an ADR.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _package = 'package:waylight_mobile/';

/// A layer: the files under [path] and what they may import.
final class _Layer {
  const _Layer(
    this.path, {
    this.mayImport = const [],
    this.packages = const [],
  });

  /// Directory or file below lib/.
  final String path;

  /// Other layers (paths below lib/) this layer may import.
  final List<String> mayImport;

  /// Third-party and Flutter packages this layer may import.
  final List<String> packages;
}

const _flutterBase = ['flutter/foundation.dart'];

const _layers = <_Layer>[
  _Layer('utils/', packages: _flutterBase),
  _Layer('domain/', mayImport: ['utils/']),
  _Layer(
    'data/services/',
    mayImport: ['utils/', 'domain/'],
    packages: [
      ..._flutterBase,
      'flutter/services.dart',
      'http/',
      'flutter_secure_storage/',
      'logging/',
    ],
  ),
  _Layer(
    'data/repositories/',
    mayImport: ['utils/', 'domain/', 'data/services/'],
    packages: [..._flutterBase, 'logging/'],
  ),
  _Layer(
    'ui/core/',
    mayImport: ['utils/', 'domain/', 'l10n/'],
    // url_launcher only behind LinkOpener, so features open links one way.
    packages: [
      ..._flutterBase,
      'material_ui/',
      'flutter/widgets.dart',
      'url_launcher/',
    ],
  ),
  _Layer(
    'ui/',
    mayImport: [
      'utils/',
      'domain/',
      'data/repositories/',
      'ui/core/',
      'l10n/',
      'routing/routes.dart',
    ],
    packages: [
      ..._flutterBase,
      'material_ui/',
      'flutter/widgets.dart',
      'intl/',
      'timezone/',
      'package_info_plus/',
      'go_router/',
      'provider/',
      'logging/',
    ],
  ),
  _Layer(
    'routing/',
    mayImport: ['data/repositories/', 'ui/', 'routing/'],
    // foundation for Listenable: the redirects follow several repositories.
    packages: [..._flutterBase, 'go_router/', 'provider/'],
  ),
  _Layer('l10n/', packages: ['flutter/', 'flutter_localizations/', 'intl/']),
  _Layer(
    'app.dart',
    mayImport: ['l10n/', 'ui/core/', 'domain/models/'],
    packages: ['material_ui/', 'go_router/'],
  ),
  _Layer(
    'config/',
    mayImport: ['data/', 'utils/'],
    packages: [
      ..._flutterBase,
      'http/',
      'provider/',
      'logging/',
      'path_provider/',
    ],
  ),
  _Layer(
    'main.dart',
    mayImport: ['app.dart', 'config/', 'routing/'],
    packages: ['material_ui/', 'provider/'],
  ),
];

final _import = RegExp(r'''^(?:import|export)\s+'([^']+)';''', multiLine: true);

_Layer _layerOf(String path) => _layers.firstWhere(
  (layer) => path.startsWith(layer.path),
  orElse: () =>
      throw StateError('$path belongs to no layer; add it to the rules.'),
);

String? _featureOf(String path) {
  final match = RegExp(r'^ui/([^/]+)/').firstMatch(path);
  final feature = match?.group(1);
  return feature == 'core' ? null : feature;
}

/// Why [target] may not be imported from [file], or `null` if it may.
String? _violation(String file, String target) {
  if (target.startsWith('dart:')) return null;
  final layer = _layerOf(file);

  if (target.startsWith(_package)) {
    final path = target.substring(_package.length);
    final feature = _featureOf(file);
    if (feature != null && path.startsWith('ui/$feature/')) return null;
    if (path.startsWith(layer.path) && _featureOf(path) == null) return null;
    final otherFeature = _featureOf(path);
    if (feature != null && otherFeature != null && otherFeature != feature) {
      return 'features never import each other (ui/$feature → ui/$otherFeature)';
    }
    if (layer.mayImport.any(path.startsWith)) return null;
    return '${layer.path} may not import $path';
  }

  if (target.startsWith('package:')) {
    final package = target.substring('package:'.length);
    if (package == 'flutter/material.dart' ||
        package == 'flutter/cupertino.dart') {
      return 'use package:material_ui (Flutter 3.50+), not $package';
    }
    if (layer.packages.any(package.startsWith)) return null;
    return '${layer.path} may not import $package';
  }
  return 'use package imports, not the relative import $target';
}

void main() {
  final files = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !f.path.contains('/generated/'))
      .toList();

  test('lib/ contains Dart files', () => expect(files, isNotEmpty));

  test('every import follows the layer rules (docs/architecture.md)', () {
    final violations = <String>[];
    for (final file in files) {
      final path = file.path.replaceAll(r'\', '/').substring('lib/'.length);
      for (final match in _import.allMatches(file.readAsStringSync())) {
        final reason = _violation(path, match.group(1)!);
        if (reason != null) {
          violations.add('lib/$path: ${match.group(1)} ($reason)');
        }
      }
    }
    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  group('the rules themselves', () {
    test('forbid imports between features', () {
      expect(
        _violation(
          'ui/home/widgets/a.dart',
          '${_package}ui/connect_server/widgets/b.dart',
        ),
        contains('features never import each other'),
      );
    });

    test('forbid services in the UI', () {
      expect(
        _violation(
          'ui/home/widgets/a.dart',
          '${_package}data/services/api/api_client.dart',
        ),
        isNotNull,
      );
    });

    test('keep the domain free of Flutter', () {
      expect(
        _violation('domain/models/a.dart', 'package:flutter/foundation.dart'),
        isNotNull,
      );
    });

    test('forbid package:flutter/material.dart', () {
      expect(
        _violation('ui/home/widgets/a.dart', 'package:flutter/material.dart'),
        contains('material_ui'),
      );
    });

    test('allow the own feature, ui/core and repositories', () {
      for (final target in [
        'ui/home/view_models/home_view_model.dart',
        'ui/core/themes/dimens.dart',
        'data/repositories/server/server_repository.dart',
      ]) {
        expect(
          _violation('ui/home/widgets/a.dart', '$_package$target'),
          isNull,
          reason: target,
        );
      }
    });
  });
}
