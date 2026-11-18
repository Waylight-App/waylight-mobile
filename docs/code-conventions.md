# Code conventions

These conventions are binding for every line in this repository. They
follow [Effective Dart](https://dart.dev/effective-dart), the
[Flutter style guide](https://github.com/flutter/flutter/blob/main/docs/contributing/Style-guide-for-Flutter-repo.md)
and the [Flutter architecture guide](https://docs.flutter.dev/app-architecture),
and add what makes this code base uniform. Most rules are enforced by
`make ci` ([enforcement](#16-enforcement)); the rest are checked in review.

When a rule and readability disagree in a specific case, readability wins —
say why in the pull request. When a rule turns out wrong in general, change
this document in its own pull request.

Contents: [Principles](#1-principles) · [Structure and names](#2-structure-and-names) ·
[Dart](#3-dart) · [Widgets](#4-widgets) · [Reusable components](#5-reusable-components) ·
[View models and state](#6-view-models-and-state) · [Data layer](#7-data-layer) ·
[Errors](#8-errors) · [Asynchronous code](#9-asynchronous-code) ·
[Texts](#10-texts) · [Comments](#11-comments-and-documentation) ·
[Logging](#12-logging) · [Tests](#13-tests) · [Dependencies](#14-dependencies) ·
[Language](#15-language) · [Enforcement](#16-enforcement)

## 1. Principles

The principles are tools, not goals. Each one below says what it means in
*this* code base.

### KISS — keep it simple

The simplest code that solves today's problem and reads clearly wins. A
plain `ChangeNotifier` beats a state-management framework, a `switch`
beats a strategy hierarchy, a function beats a class with one method and no
state.

```dart
// Good: says what it does.
bool get isSecure => uri.scheme == 'https';

// Bad: an abstraction for a one-liner.
abstract class SchemePolicy { bool accepts(Uri uri); }
class HttpsOnlyPolicy implements SchemePolicy { … }
```

### YAGNI — you aren't gonna need it

Build what an issue asks for, not what a later issue might. No parameters
"for flexibility", no base classes for a single implementation, no generic
helpers before the second use. The roadmap tells what comes next; when it
comes, refactor.

### DRY — but only for knowledge, not for look-alike code

One piece of knowledge lives in one place: the address rules in
`ServerAddress.parse`, the error texts in `ui/core/error_messages.dart`,
spacing in `Dimens`. Two pieces of code that merely look alike but change
for different reasons stay separate. Extract on the **third** use, not the
second ([rule of three](#when-to-create-a-component)).

### SOLID

| Principle | Here |
| --- | --- |
| **S**ingle responsibility | One reason to change per class: `ApiClient` speaks HTTP, `PlatformApi` knows endpoints, `ServerRepositoryRemote` owns the server state, `ConnectServerViewModel` owns one screen. A widget renders; it does not fetch, parse or decide navigation. |
| **O**pen/closed | Add behaviour by adding code, not by editing switches all over: a new widget kind registers a renderer in the composition root ([architecture](architecture.md#dashboard-widgets)); a new endpoint is a new method in its `…Api`. |
| **L**iskov substitution | Every implementation honours the contract of its abstract class, including errors: a fake repository returns `Result.error` where the real one would, never throws instead. Tests run against fakes because of this. |
| **I**nterface segregation | Small, focused interfaces: `KeyValueStore` has three methods. A view model depends on the one repository it needs, not on a "service locator". |
| **D**ependency inversion | View models depend on abstract repositories; only `config/dependencies.dart` knows the implementations. The domain depends on nothing. |

### Composition over inheritance

Build widgets by combining widgets (`SectionCard` wraps `Card`, `Padding`,
`Text`), never by extending a concrete widget. Share behaviour between
classes with small collaborators passed to the constructor, not with deep
class hierarchies. Inheritance is fine for framework contracts
(`StatelessWidget`, `ChangeNotifier`) and for an abstract repository with
its implementations.

### Separation of concerns and explicit flow

Layers have one job each ([architecture](architecture.md)). Data flows one
way: repository → view model → view; events flow back as command calls.
Navigation follows state. Nothing reaches around a layer.

### Fail explicitly

Expected failures are values (`Result`), unexpected ones crash in debug and
are logged in release. Never swallow an error, never return a "magic"
default that hides it.

## 2. Structure and names

The folder layout is fixed by the [architecture](architecture.md#folder-structure).

| Thing | Convention | Example |
| --- | --- | --- |
| Files | `snake_case.dart`, one public type per file, named after it | `server_repository.dart` |
| Screens | `<Name>Screen` in `ui/<feature>/widgets/` | `ConnectServerScreen` |
| Feature widgets | noun phrase in `ui/<feature>/widgets/` | `TodoTile` |
| Shared components | noun phrase in `ui/core/widgets/` | `MessageBanner`, `CommandButton` |
| View models | `<Name>ViewModel` in `ui/<feature>/view_models/` | `ConnectServerViewModel` |
| Repositories | abstract `<Name>Repository`, implementation `<Name>Repository<Source>` | `ServerRepositoryRemote` |
| Services | `<Name>Api` for HTTP, `<Name>Store` for storage | `PlatformApi`, `KeyValueStore` |
| API models | `<Name>ApiModel` | `AuthStatusApiModel` |
| Domain errors | `<What>Exception` or a descriptive noun, `implements Exception` | `InvalidServerAddress` |
| Commands | verbs | `connect`, `load`, `disconnect` |
| Booleans | read as a statement | `isSecure`, `setupRequired`, `running` |
| Event callbacks | `on<Event>` | `onAddressChanged`, `onPressed` |
| Private members | leading `_`; private named parameters for injected fields | `required this._repository` |
| Test keys | `ValueKey('<feature>.<element>')` | `ValueKey('connect.submit')` |
| Routes | constants in `Routes` | `Routes.connect` |

Avoid abbreviations except well-known ones (`id`, `url`, `api`, `l10n`,
`http`). Name by role, not by type: `server`, not `serverAddressObject`.

## 3. Dart

- **Immutable by default.** `final` fields and locals, `const` constructors
  and literals wherever possible. Domain models are immutable and implement
  `==`, `hashCode` and `toString`.
- **Class modifiers say intent.** `final class` unless a class is meant to
  be extended or implemented; `abstract interface class` for pure
  interfaces (`KeyValueStore`); `abstract class` for base classes with
  shared behaviour (`ServerRepository extends ChangeNotifier`);
  `sealed class` for closed hierarchies (`Result`, `Command`);
  `abstract final class` for namespaces of constants (`Dimens`, `Routes`).
- **Named parameters** for every constructor with more than one argument,
  `required` instead of nullable-with-default when there is no sensible
  default.
- **Patterns and exhaustive `switch`** for `Result`, sealed types, enums
  and JSON:
  ```dart
  return switch (result) {
    Ok(:final value) => Result.ok(ServerStatus(setupRequired: value.setupRequired)),
    Error(:final error) => Result.error(error),
  };
  ```
  No `is` chains, no `as` casts on data from outside.
- **No `dynamic`.** JSON is `Object?` and is narrowed with patterns
  (`case {'title': final String title}`).
- **Records** for small, local groupings (`final (background, icon) = …`);
  a class as soon as the value crosses a file boundary or needs a name.
- **Extensions** for convenience on types we do not own
  (`context.l10n`, `AppLocalizations.errorMessage`), never to hide logic.
- **Null safety:** avoid `!`; prefer a local variable, a pattern
  (`if (x case final x?)`) or `?.`. A `!` needs an obvious reason next to it.
- **Collections:** collection `if`/`for` and spread over imperative
  building; `?element` for optional items.

## 4. Widgets

- **Small and composed.** A `build` method fits on a screen. Extract a
  **widget class** — never a method returning a widget — when a part has
  its own meaning, state or rebuild boundary. Widget classes get `const`
  constructors, their own rebuilds and their own tests.
  ```dart
  // Good
  class _AddressField extends StatelessWidget { … }

  // Bad: rebuilds with the parent, cannot be const, invisible to tests.
  Widget _buildAddressField() { … }
  ```
- **`StatelessWidget` first.** `StatefulWidget` only for state that belongs
  to the widget itself: controllers, focus nodes, animations. Everything
  else lives in the view model.
- **`build` is pure and cheap.** No requests, no object creation that
  outlives the frame, no side effects.
- **Views get their view model through the constructor** — the route
  creates it in a `ViewModelHost`. Widgets do not call `context.read` for
  view models; this keeps screens testable with fakes.
- **Rebuild only what changes:** wrap exactly the listening part in
  `ListenableBuilder`, not the whole screen.
- **No styling in screens.** Colours from `Theme.of(context).colorScheme`
  and `StatusColors.of(context)`, text styles from `textTheme`, spacing and
  sizes from `Dimens`. Buttons, fields and cards get their look from the
  component themes in `AppTheme`; screens use plain Material widgets or
  shared components. A test rejects colour literals and `fontSize` outside
  `ui/core/themes`.
- **Material comes from `package:material_ui`**, never
  `package:flutter/material.dart` (Flutter 3.50+). Pure-logic files import
  `package:flutter/foundation.dart` only.
- **Accessible by construction:** every interactive element has a label
  (text, `tooltip` or `Semantics`) and a tap target of at least
  `Dimens.tapTarget`; headings use `Semantics(header: true)`; state is never
  shown by colour alone.
- **`BuildContext` across `await`:** check `context.mounted` before using a
  context after an `await` (the analyzer warns).

## 5. Reusable components

Reusable components are the design system in code. They make screens
short, consistent and accessible without each screen getting it right
again. The catalogue is in [UI components](ui-components.md).

### When to create a component

1. **Look in `ui/core/widgets` first** and use what exists.
2. **Rule of three:** the third time the same UI with the same meaning
   appears, extract it. Twice is a coincidence; duplicate and wait.
3. **A pattern from the design** (docs/design) that the next issues will
   need — a banner, a card frame — may be built with its first use, if the
   design shows it in several places.
4. Something only one feature uses stays in `ui/<feature>/widgets`; it
   moves to `ui/core/widgets` when a second feature needs it.

### How to design one

- **One job, small API.** A `MessageBanner` shows a message; it does not
  fetch, retry or decide when to appear.
- **Required, named parameters;** optional ones only with a real default.
- **Slots over flags.** Take a `Widget child` or `Widget? action` instead of
  `showRetry`, `retryLabel`, `onRetry`. The caller composes; the component
  stays closed for modification.
- **Enums over booleans** for variants (`CommandButtonVariant.outlined`,
  `MessageKind.warning`): readable at the call site, extensible, exhaustive.
- **No domain or data imports.** Components know `utils` (e.g. `Command`),
  the theme and Flutter — never repositories, services or a feature. They
  take display values (`String`, `Widget`), not domain models.
- **Theme-driven.** Colours, text styles and spacing come from the theme and
  `Dimens`; a component never hard-codes them and works in light and dark.
- **Accessible:** semantics, tap targets and contrast are the component's
  job, so every user of it gets them for free.
- **Documented with an example** in its doc comment, listed in
  [UI components](ui-components.md), and **tested**: rendering of each
  variant, interaction, and the accessibility guidelines.

```dart
// Good: composition, enum variant, slot for the action.
MessageBanner(
  kind: MessageKind.error,
  message: l10n.errorMessage(error),
  action: TextButton(onPressed: retry, child: Text(l10n.retry)),
)

// Bad: flags and domain knowledge inside the component.
ErrorBox(error: apiException, showRetry: true, isWarning: false, onRetry: retry)
```

## 6. View models and state

- One view model per screen, a `ChangeNotifier` that depends on abstract
  repositories only. No `BuildContext`, no widgets, no `material_ui`
  imports.
- **Every asynchronous user action is a `Command`** (`Command0`,
  `Command1`). The view reads `running`, `completed`, `error` and `result`
  from it; no `isLoading`/`errorMessage` fields in view models.
- **Expose read-only state** through getters; mutate only inside the view
  model, then `notifyListeners()` once per change, and only when the value
  actually changed.
- **Dispose what you create:** commands, controllers, subscriptions in
  `dispose()`. View models are created and disposed by `ViewModelHost`.
- **Shared state lives in repositories**, not in view models: the connected
  server, the session, the cached dashboard. View models read it and listen
  where needed.

## 7. Data layer

- **Services are stateless** adapters for one external system each. They
  return `Result<ApiModel>` and never throw for expected failures.
- **Repositories are the single source of truth** for their data. They
  map API models to domain models, cache, and notify listeners. An abstract
  class plus one implementation per source.
- **API models mirror the JSON exactly** and are parsed with patterns in a
  static `fromJson` that returns `null` for unexpected shapes. They never
  leave the data layer.
- **Domain models carry their rules** (`ServerAddress.parse`) and know
  nothing about JSON, HTTP or Flutter.

## 8. Errors

- Services and repositories return `Result`; `switch` on it is exhaustive.
- Network and HTTP failures are `ApiException`s with an `ApiFailure`;
  input the domain rejects is a domain exception with a reason enum.
- Catch only specific types (`on SocketException`, `on Exception`), never
  bare `catch (e)`; log, then return `Result.error`.
- **Texts for errors:** a screen handles its own errors first (an invalid
  address at the field), and passes everything else to
  `l10n.errorMessage(error)` in `ui/core/error_messages.dart`, so the same
  failure reads the same everywhere. Server messages are never shown as
  they are.
- **Where errors appear:** input errors at the field (`errorText`),
  failures of an action in a `MessageBanner` near the action, failures of a
  whole screen in place of its content.

## 9. Asynchronous code

- Every `Future` is awaited, returned, or explicitly `.ignore()`d — the
  `unawaited_futures` and `discarded_futures` lints catch the rest.
- No `async` functions returning `void`; return `Future<void>`.
- Every network call has a timeout (`ApiClient.timeout`).
- Close what you open: stream subscriptions, sinks, controllers.
- No polling in the background; refresh on resume and while visible.

## 10. Texts

- Every user-visible text is in `lib/l10n/app_en.arb` with a `@key`
  description, and in every other language file. No string literals in
  widgets except data (names, addresses).
- **Keys:** `<feature><Thing>` in lowerCamelCase (`connectButton`,
  `homeSetupRequired`); texts shared by all features start with their kind
  (`error…`).
- Placeholders are named and typed (`{server}`), never concatenated:
  `l10n.homeConnectedTo(server)`, not `'${l10n.connected} $server'`.
- Write full, friendly sentences; say what happened and what to do.

## 11. Comments and documentation

- Every public member has a `///` doc comment (`public_member_api_docs`).
  The first sentence is a summary in the third person ("Checks that …",
  "The address of …"), followed by details after a blank line.
- Reference identifiers in brackets (`[ServerAddress]`), and they must
  resolve (`comment_references`).
- Shared components show a short usage example in a ```` ```dart ```` block.
- Comments explain **why**, not what; link the issue or ADR behind a
  non-obvious decision: `(#12)`, `(docs/adr/0002-flutter-stack.md)`.
- No commented-out code. `TODO(#12): …` only with an issue number (a test
  enforces it).

## 12. Logging

- One `Logger('<ClassName>')` per class from `package:logging`; never
  `print` or `debugPrint` (a test enforces it).
- `info` for expected events, `warning` for unexpected but handled ones,
  `severe` for failures the user notices.
- **Never log** passwords, tokens, cookies, CSRF tokens, request or response
  bodies, or URLs with query parameters ([security](security.md)).

## 13. Tests

See [testing](testing.md). In short: every layer you touch gets tests;
fakes instead of mocks; one behaviour per test, named as a sentence;
arrange–act–assert; find widgets by key or translated text.

## 14. Dependencies

A new runtime dependency needs a justification in the pull request and a
comment in `pubspec.yaml` ([ADR 0003](adr/0003-dependency-policy.md)).
Prefer the SDK and a few lines of own code; then packages by the Dart and
Flutter teams.

## 15. Language

Code, comments, commit messages, issues and documentation are in English.
User-facing texts are in the ARB files, in every supported language.

## 16. Enforcement

| Check | Enforces |
| --- | --- |
| `dart format --set-exit-if-changed` | Formatting (tall style, 80 columns, trailing commas by the formatter) |
| `flutter analyze --fatal-infos` with `analysis_options.yaml` | Strict types, immutability, async rules, doc comments, import order, Flutter lints |
| `test/architecture_test.dart` | Layers, no imports between features, `material_ui` instead of `flutter/material.dart`, package imports |
| `test/conventions_test.dart` | No colour literals or `fontSize` outside the theme, no `print`, TODOs with issue, route constants |
| `test/l10n_test.dart` | Every text in every language, with description and the same placeholders |
| `tool/check_coverage.dart` | At least 80 % line coverage |
| Review | Everything else in this document |
