import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/data/repositories/widget_data/widget_data_repository.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/ui/core/widget_size_scope.dart';
import 'package:waylight_mobile/ui/core/widgets/compact_lines.dart';
import 'package:waylight_mobile/ui/widgets/registry.dart';

import '../../../testing/fakes/fake_server_repository.dart';
import '../../../testing/fakes/fake_widget_data_repository.dart';
import '../../../testing/pump_app.dart';

void main() {
  setUpAll(initializeDateFormatting);

  // Recorded from https://demo.getwaylight.app.
  const endpoints = {
    'briefing': ('/api/briefing', 'briefing_demo'),
    'arr': ('/api/arr/overview', 'arr_overview_demo'),
    'media': ('/api/media/overview', 'media_overview_demo'),
    'releases': ('/api/releases', 'releases_demo'),
    'gamedeals': ('/api/gamedeals/overview', 'gamedeals_overview_demo'),
    'mail': ('/api/mail/inbox', 'mail_inbox_example'),
    'holidays': ('/api/holidays', 'holidays_demo'),
    'timeline': ('/api/timeline', 'timeline_demo'),
    'fritzbox': ('/api/fritzbox/status', 'fritzbox_status_demo'),
    'immich': ('/api/immich/overview', 'immich_overview_demo'),
    'nextcloud': ('/api/nextcloud/status', 'nextcloud_status_demo'),
  };

  test('list kinds without a compact tile start at medium', () {
    for (final kind in ['notes', 'bookmarks', 'phonelist']) {
      expect(nativeWidgets.sizesFor(kind).supported, [
        WidgetSize.medium,
        WidgetSize.large,
      ], reason: kind);
      expect(nativeWidgets.sizesFor(kind).defaultSize, WidgetSize.medium);
    }
  });

  test('picture widgets offer medium and large tiles', () {
    for (final kind in ['space', 'grafana-panel']) {
      expect(nativeWidgets.sizesFor(kind).supported, [
        WidgetSize.medium,
        WidgetSize.large,
      ], reason: kind);
      expect(nativeWidgets.sizesFor(kind).defaultSize, WidgetSize.large);
    }
  });

  for (final MapEntry(key: kind, value: (path, file)) in endpoints.entries) {
    for (final (size, pixels) in [
      (WidgetSize.small, const Size(150, 150)),
      (WidgetSize.strip, const Size(328, 70)),
    ]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('$kind fits a ${size.name} tile at ${scale}x text (#211)', (
          tester,
        ) async {
          final data = FakeWidgetDataRepository()
            ..json[path] = jsonDecode(
              File('test/fixtures/$file.json').readAsStringSync(),
            );
          await tester.pumpScreen(
            MultiProvider(
              providers: [
                ChangeNotifierProvider<ServerRepository>.value(
                  value: FakeServerRepository(current: testServer()),
                ),
                Provider<WidgetDataRepository>.value(value: data),
              ],
              child: Builder(
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(scale)),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: SizedBox.fromSize(
                      size: pixels,
                      child: WidgetSizeScope(
                        size: size,
                        child: nativeWidgets.builderFor(kind)!(
                          context,
                          WidgetPlacement(id: kind, kind: kind),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          // An overflow would have failed the test with an exception.
          expect(find.byType(CompactLines), findsOneWidget);
        });
      }
    }
  }
}
