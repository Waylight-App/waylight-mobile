# Adding a feature

This walks through a new screen end to end, with the to-do list as an
example. Every step has its test; together they pass `make ci`. Read
[architecture](architecture.md) first.

## 0. Issue and branch

Every change starts with an issue ([workflow](workflow.md)). Branch from
`main`: `git switch -c feat/12-todo-list`.

## 1. Domain model — `lib/domain/models/todo.dart`

Immutable, pure Dart, with `==`, `hashCode` and `toString`. Rules that belong
to the data go here (e.g. "a title is 1–500 characters").

```dart
/// A to-do of the Waylight to-do list.
final class Todo {
  /// Creates a to-do.
  const Todo({required this.id, required this.title, required this.done});

  /// The id assigned by the server.
  final String id;
  // …
}
```

Test: `test/domain/models/todo_test.dart`, table-driven where there are rules.

## 2. API model and service — `lib/data/services/api/`

- `models/todo_api_model.dart`: exactly the JSON of `GET /api/todos`
  (`api/modules/todos.yaml` in the server repository), parsed with a pattern
  in a static `fromJson` that returns `null` for unexpected shapes.
- `todos_api.dart`: one method per endpoint, built on `ApiClient`, returning
  `Result<…ApiModel>`. No caching, no state.

Test with `MockClient` from `package:http/testing.dart` and recorded JSON.

## 3. Repository — `lib/data/repositories/todos/`

- `todos_repository.dart`: the abstract class the UI depends on.
- `todos_repository_remote.dart`: the implementation; maps API models to
  domain models, caches if useful, notifies listeners if other screens must
  follow changes.

Register it in `lib/config/dependencies.dart`. Test it with fake services
or `MockClient`, and add a fake repository to `test/testing/fakes/`.

## 4. View model — `lib/ui/todos/view_models/todos_view_model.dart`

A `ChangeNotifier` with one `Command` per user action (`load`, `toggle`,
`add`). It depends on the abstract repository only. Test it with the fake
repository: no widgets, no network.

## 5. View — `lib/ui/todos/widgets/todos_screen.dart`

A widget that takes the view model in its constructor and renders it with
`ListenableBuilder`. Texts come from `context.l10n`; spacing from `Dimens`.
Give interactive widgets a `ValueKey('todos.…')` for tests.

Test it with `tester.pumpScreen(...)` from `test/testing/pump_app.dart`:
the main states (loading, list, empty, error), one interaction, the German
texts and the accessibility guidelines.

## 6. Route — `lib/routing/`

Add the path to `routes.dart` and a `GoRoute` to `router.dart` that creates
the view model with `context.read()`. Extend `test/routing/router_test.dart`
if the route has redirects.

## 7. Texts

Add every text to `lib/l10n/app_en.arb` with a `@key` description and the
German text to `app_de.arb`, then `make gen` and commit the generated files.
`test/l10n_test.dart` fails on a missing translation or placeholder.

## 8. Docs and pull request

Update the README feature list or `docs/` if users or developers need to
know, run `make ci`, push and open a pull request with `Closes #12`.
