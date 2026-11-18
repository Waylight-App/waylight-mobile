# Coding guidelines

Code is read far more often than written. These rules keep every file of
the app looking as if one person wrote it. Most are enforced by
`make ci`; the rest are checked in review.

## Language

Code, comments, commit messages, issues and documentation are in English.
User-facing texts live in the ARB files, in every supported language.

## Formatting and analysis

- `dart format` (tall style, 80 columns) decides formatting. Never fight it;
  trailing commas are managed by the formatter.
- `flutter analyze --fatal-infos` must be clean. Do not silence a lint with
  `// ignore:` unless the comment next to it explains why, and never for a
  whole file.
- The analyzer runs with `strict-casts`, `strict-inference` and
  `strict-raw-types`: no implicit `dynamic`.

## Files and names

| Thing | Convention | Example |
| --- | --- | --- |
| Files | `snake_case.dart`, one public type per file, named after it | `server_repository.dart` |
| Screens | `<Name>Screen` in `ui/<feature>/widgets/` | `ConnectServerScreen` |
| View models | `<Name>ViewModel` in `ui/<feature>/view_models/` | `ConnectServerViewModel` |
| Repositories | abstract `<Name>Repository`, implementation `<Name>Repository<Source>` | `ServerRepositoryRemote` |
| Services | `<Name>Api` for HTTP, `<Name>Store` for storage | `PlatformApi`, `KeyValueStore` |
| API models | `<Name>ApiModel` | `AuthStatusApiModel` |
| Commands | verbs | `connect`, `load`, `disconnect` |
| Booleans | read as a statement | `isSecure`, `setupRequired`, `running` |
| Keys for tests | `ValueKey('<feature>.<element>')` | `ValueKey('connect.submit')` |

Avoid abbreviations except well-known ones (`id`, `url`, `api`, `l10n`).

## Dart

- Prefer `final` everywhere; `var` only for values that change.
- Classes are `final class` unless they are meant to be extended or
  implemented; interfaces are `abstract interface class`, base classes with
  shared behaviour `abstract class`.
- Use named parameters for constructors with more than one argument;
  private named parameters (`required this._repository`) for injected
  dependencies.
- Use patterns and exhaustive `switch` expressions for `Result`, sealed types
  and JSON (`case {'title': final String title}`), not `is` chains and casts.
- No `dynamic`. JSON is `Object?` and is narrowed with patterns.
- Every `Future` is awaited, returned or explicitly `.ignore()`d — the
  `unawaited_futures` and `discarded_futures` lints catch the rest.
- Do not throw for expected failures; return `Result.error`. Catch only
  specific types (`on SocketException`), never bare `catch (e)`.

## Widgets

- Prefer small `StatelessWidget`s and `const` constructors. Extract a widget
  class instead of a method that returns a widget.
- Views get their view model through the constructor, not from
  `context.read` inside the widget tree (the router creates it). This keeps
  screens easy to test.
- Rebuild only what changes: `ListenableBuilder` around the part that listens.
- No hard-coded colours, text styles or paddings: use `Theme.of(context)`,
  `Dimens` and the shared widgets in `ui/core`.
- Every interactive element has a label for screen readers (text or
  `Semantics`/`tooltip`) and a tap target of at least 48 × 48 dp.
- Import `package:material_ui/material_ui.dart`, not
  `package:flutter/material.dart` (Material lives in its own package since
  Flutter 3.50).

## Comments and documentation

- Every public member has a doc comment (`public_member_api_docs`). The first
  sentence says what it is or does, in the third person: "Checks that …".
- Comments explain *why*, not *what*. Link the issue or ADR behind a
  non-obvious decision (`(#12)`, `(docs/adr/0002-flutter-stack.md)`).
- No commented-out code and no `TODO` without an issue number.

## Logging

- Use one `Logger('<ClassName>')` per class from `package:logging`; never
  `print` or `debugPrint`.
- `info` for expected events, `warning` for unexpected but handled ones,
  `severe` for failures the user will notice.
- **Never log** passwords, tokens, cookies, CSRF tokens or full URLs with
  query parameters. Log paths, not bodies.

## Dependencies

Every new runtime dependency needs a justification in the pull request
([ADR 0003](adr/0003-dependency-policy.md)). Dev dependencies are cheaper but
still need a reason.
