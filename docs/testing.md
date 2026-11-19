# Testing

Every change comes with tests for every layer it touches. Tests are fast:
the whole suite runs in seconds without device, network or storage.

## What is tested where

| Layer | Test file | Tools | What to test |
| --- | --- | --- | --- |
| Domain | `test/domain/models/*_test.dart` | `test` | Rules and normalisation, table-driven |
| Services | `test/data/services/**` | `MockClient` from `package:http/testing.dart` | Requests sent (method, path, headers, body), JSON parsing, error mapping |
| Repositories | `test/data/repositories/**` | `MockClient`, `InMemoryKeyValueStore` | Mapping to domain models, what is stored, when listeners are notified |
| View models | `test/ui/<feature>/*_view_model_test.dart` | fake repositories | Command results, state changes, that invalid input never reaches the repository |
| Views | `test/ui/<feature>/*_screen_test.dart` | `testWidgets`, `pumpScreen` | Main states, one interaction per command, German texts, accessibility guidelines |
| Routing | `test/routing/router_test.dart` | full app with fakes | Redirects |
| Shared components | `test/ui/core/*_test.dart` | `testWidgets`, `pumpScreen` | Every variant, the interaction, contrast in light and dark |
| Architecture | `test/architecture_test.dart` | — | Import rules ([architecture](architecture.md#enforcement)) |
| Conventions | `test/conventions_test.dart` | — | No colour literals or font sizes outside the theme, no `print`, TODOs with issue ([code conventions](code-conventions.md#16-enforcement)) |
| Translations | `test/l10n_test.dart` | — | Every key in every language, same placeholders |

## Fakes, not mocks

Dependencies are replaced by small hand-written fakes in
`test/testing/fakes/` (`FakeServerRepository`, `InMemoryKeyValueStore`), as
the Flutter architecture guide recommends. A fake is a working, simple
implementation of the abstract class: tests read like real use, survive
refactorings and need no mocking library. Add a fake for every new
repository next to the existing ones.

For HTTP, `MockClient` from `package:http/testing.dart` answers with recorded
JSON; copy real responses of a demo server, shortened to what matters.

## Style

- One behaviour per test; the name says it as a sentence:
  `test('rejects an answer that is not from Waylight', …)`.
- Arrange, act, assert, separated by blank lines.
- Find widgets by `ValueKey` or by the translated text (`l10nEn.connectButton`),
  never by hard-coded English strings.
- No `sleep`, no real timers: `tester.pump`, `pumpAndSettle` and
  `Completer`s control time.

## Accessibility

`pumpScreen(screen, brightness: Brightness.dark)` shows a screen in dark
mode; check contrast in both. Screen tests call the guidelines of
`flutter_test`:

```dart
await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
await expectLater(tester, meetsGuideline(textContrastGuideline));
```

## Coverage

`make coverage` writes `coverage/lcov.info` and fails below 80 % line
coverage of `lib/` without generated code (`tool/check_coverage.dart`). CI
keeps the report as an artifact of every run. Coverage is a floor, not a
goal: a test that executes code without checking anything does not count in
review.

## Integration tests

End-to-end tests in `integration_test/` run the real app on a device or
emulator against a real Waylight server: connect, then (as the app grows)
sign in and open the dashboard. They find steps through the widget keys
(`connect.address`, `signIn.password`, `dashboard.settings`, …).

- **Locally:** start an emulator or connect a phone, then `make integration`.
  It tests against the public demo and signs in with the demo's public
  password; another server with
  `make integration WAYLIGHT_URL=https://home.example.org WAYLIGHT_PASSWORD=…`.
- **In CI:** the *Integration* workflow runs nightly and on demand on an
  Android emulator, against the public demo by default or the address given
  when it is started by hand; for another server the owner's password comes
  from the repository secret `WAYLIGHT_PASSWORD`, never from an input, which
  would appear in the log. It does not run on pull requests: it takes
  minutes and depends on a server outside the repository.

The public demo is served over HTTPS, so the tests need no exception for
plain HTTP. Its data is reset every hour; tests must not depend on changes
made by an earlier run.
