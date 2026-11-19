import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:waylight_mobile/data/services/api/api_client.dart';
import 'package:waylight_mobile/data/services/api/notes_api.dart';
import 'package:waylight_mobile/data/services/api/todos_api.dart';
import 'package:waylight_mobile/domain/models/note.dart';
import 'package:waylight_mobile/domain/models/todo.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../../testing/fakes/fake_server_repository.dart';

void main() {
  // Recorded from https://demo.getwaylight.app.
  final todos = File('test/fixtures/todos_demo.json').readAsStringSync();
  final notes = File('test/fixtures/notes_demo.json').readAsStringSync();

  ApiClient answering(String body, void Function(Uri) onRequest) => ApiClient(
    client: MockClient((request) async {
      onRequest(request.url);
      return http.Response.bytes(utf8.encode(body), 200);
    }),
  );

  test('reads the to-dos of the demo', () {
    final list = parseTodos(jsonDecode(todos))!;

    expect(list, hasLength(9));
    expect(list.first.overdue, isTrue);
    expect(list.first.due, DateTime(2026, 11, 18));
    expect(list.firstWhere((t) => t.title.startsWith('Choose')).due, isNull);
  });

  test('asks for open to-dos of a list', () async {
    late Uri asked;
    final api = TodosApi(answering(todos, (u) => asked = u));

    final result = await api.todos(testServer(), source: 'nc');

    expect(result, isA<Ok<List<Todo>>>());
    expect(asked.queryParameters, {'done': 'false', 'source': 'nc'});
  });

  test('reads the notes of the demo', () {
    final list = parseNotes(jsonDecode(notes))!;

    expect(list, hasLength(2));
    expect(list.every((n) => n.pinned), isTrue);
    expect(list.first.preview, isNot(contains('**')));
  });

  test('asks for pinned notes only on request', () async {
    late Uri asked;
    final api = NotesApi(answering(notes, (u) => asked = u));

    expect(await api.notes(testServer()), isA<Ok<List<Note>>>());
    expect(asked.queryParameters, isEmpty);

    await api.notes(testServer(), pinnedOnly: true);
    expect(asked.queryParameters, {'pinned': 'true'});
  });

  test('rejects other JSON', () {
    expect(parseTodos({'a': 1}), isNull);
    expect(
      parseTodos([
        {'id': 1},
      ]),
      isNull,
    );
    expect(
      parseNotes([
        {'id': 'x'},
      ]),
      isNull,
    );
  });

  test('previews the first line of text without Markdown', () {
    const note = Note(
      id: 'n',
      title: 'House',
      body: '# House\n\n**Wi-Fi:** see [router](https://r.local)\n- more',
    );
    expect(note.preview, 'Wi-Fi: see router');
    expect(const Note(id: 'n', title: 't', body: '# Only a title').preview, '');
  });
}
