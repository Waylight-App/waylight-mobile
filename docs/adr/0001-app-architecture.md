# ADR 0001: App architecture

- Status: Accepted
- Date: 2026-11-18

## Context

The Waylight server follows a strict Clean Architecture with four rings per
module, enforced in CI (server ADR 0001). The app should be just as
predictable: every screen built the same way, testable without device or
network, and readable for contributors who know Flutter but not Waylight.

The Flutter team publishes an official
[architecture guide](https://docs.flutter.dev/app-architecture) with a
reference app: a UI layer of views and view models (MVVM), a data layer of
repositories and services, an optional domain layer, unidirectional data
flow, `Result` objects and commands. It is what Flutter developers learn
today.

## Decision

1. The app follows the Flutter architecture guide:
   - **Views** (widgets) render a **view model** and forward input to its
     commands.
   - **View models** (`ChangeNotifier`) hold the state of one screen and
     depend on abstract **repositories** only.
   - **Repositories** are the single source of truth for one kind of data;
     they use **services**, which wrap exactly one external system (the
     Waylight HTTP API, the secure storage).
   - **Domain models** are immutable pure Dart and carry their own rules.
2. The folder structure of the guide: `ui/<feature>/{view_models,widgets}`,
   `ui/core`, `data/{repositories,services}`, `domain/models`, `routing`,
   `config`, `utils`. The UI is grouped by feature, the data layer by type,
   because several features share repositories.
3. Features never import each other.
4. Expected failures are returned as `Result`; asynchronous actions of view
   models are `Command`s.
5. The rules are enforced by `test/architecture_test.dart`, which checks
   every import in `lib/` against a matrix of allowed layers.
6. A separate use-case layer is not introduced up front. A use case is added
   in `domain/use_cases` only when logic combines several repositories and
   would otherwise be duplicated in view models.

## Consequences

- Every screen has the same shape; reviewers and contributors know where
  things go.
- View models and repositories are tested with small fakes, without
  widgets, network or storage.
- More files per feature than a "widget calls API" approach; accepted for
  uniformity, as on the server.
- The rules are executable: a violation fails CI with the file, the import
  and the rule.

## Alternatives considered

- **Clean Architecture with use cases for everything** (as on the server):
  for an app that mostly shows server data, most use cases would just
  forward to a repository. The guide's optional domain layer gives the same
  dependency direction with less ceremony.
- **Feature-first with data per feature:** duplicates repositories that
  several features need (server, session, dashboard).
- **BLoC:** a sound pattern with more boilerplate (events, states) and a
  vocabulary the official guide does not use.
