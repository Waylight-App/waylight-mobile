import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:waylight_mobile/data/repositories/bookmarks/bookmarks_repository.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/data/services/api/bookmarks_api.dart';
import 'package:waylight_mobile/domain/models/bookmark.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/ui/core/link_opener.dart';
import 'package:waylight_mobile/ui/widgets/bookmarks/bookmarks_view_model.dart';
import 'package:waylight_mobile/ui/widgets/bookmarks/bookmarks_widget.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../../testing/fakes/fake_bookmarks_repository.dart';
import '../../../testing/fakes/fake_link_opener.dart';
import '../../../testing/fakes/fake_server_repository.dart';
import '../../../testing/pump_app.dart';

void main() {
  // Recorded from https://demo.getwaylight.app (GET /api/bookmarks).
  final demo = jsonDecode(
    File('test/fixtures/bookmarks_demo.json').readAsStringSync(),
  );

  test('reads the bookmarks of the demo', () {
    final bookmarks = parseBookmarks(demo)!;

    expect(bookmarks.folders.map((f) => f.name), ['Self-hosting', 'Everyday']);
    expect(bookmarks.bookmarks, hasLength(6));
    expect(bookmarks.bookmarks.first.url.host, 'github.com');
  });

  test('leaves out links that are not http or https', () {
    final bookmarks = parseBookmarks({
      'folders': <Object?>[],
      'bookmarks': [
        {'id': '1', 'title': 'Bad', 'url': 'javascript:alert(1)'},
        {'id': '2', 'title': '', 'url': 'https://example.org'},
      ],
    })!;

    expect(bookmarks.bookmarks.single.title, 'https://example.org');
  });

  test('groups by folder in the folders order, loose links last', () {
    final groups = BookmarksViewModel.group(
      Bookmarks(
        folders: const [
          BookmarkFolder(id: 'a', name: 'A'),
          BookmarkFolder(id: 'empty', name: 'Empty'),
        ],
        bookmarks: [
          Bookmark(
            id: '1',
            title: 'zeta',
            url: Uri.parse('https://z.org'),
            folderId: 'a',
          ),
          Bookmark(
            id: '2',
            title: 'Alpha',
            url: Uri.parse('https://a.org'),
            folderId: 'a',
          ),
          Bookmark(id: '3', title: 'Loose', url: Uri.parse('https://l.org')),
        ],
      ),
      BookmarkSort.az,
    );

    expect(groups.map((g) => g.name), ['A', '']);
    expect(groups.first.links.map((b) => b.title), ['Alpha', 'zeta']);
  });

  test('sorts newest first', () {
    final older = Bookmark(
      id: '1',
      title: 'Old',
      url: Uri.parse('https://o.org'),
      createdAt: DateTime(2026),
    );
    final newer = Bookmark(
      id: '2',
      title: 'New',
      url: Uri.parse('https://n.org'),
      createdAt: DateTime(2026, 6),
    );
    expect(BookmarkSort.newest.apply([older, newer]), [newer, older]);
    expect(
      BookmarksConfig.fromJson({'sort': 'nope'}).sort,
      BookmarkSort.manual,
    );
  });

  testWidgets('opens a link in the browser', (tester) async {
    final repo = FakeBookmarksRepository()
      ..result = Result.ok(parseBookmarks(demo)!);
    final opener = FakeLinkOpener();
    await tester.pumpScreen(
      LinkOpenerScope(
        opener: opener,
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider<ServerRepository>.value(
              value: FakeServerRepository(current: testServer()),
            ),
            Provider<BookmarksRepository>.value(value: repo),
          ],
          child: const SingleChildScrollView(
            child: BookmarksWidget(
              widget: WidgetPlacement(
                id: 'w',
                kind: 'bookmarks',
                config: {'tag': 'docker'},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(repo.calls.single, ('', 'docker'));
    expect(find.text('Self-hosting'), findsOneWidget);
    await tester.tap(find.text('AdGuard Home'));
    await tester.pump();

    expect(opener.opened.single.host, 'github.com');
  });

  testWidgets('tells when a link could not be opened', (tester) async {
    await tester.pumpScreen(
      LinkOpenerScope(
        opener: FakeLinkOpener(succeeds: false),
        child: Builder(
          builder: (context) => TextButton(
            onPressed: () =>
                openLink(context, Uri.parse('https://x.org'), 'failed'),
            child: const Text('go'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('go'));
    await tester.pump();

    expect(find.text('failed'), findsOneWidget);
  });
}
