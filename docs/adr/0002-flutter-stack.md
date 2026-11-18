# ADR 0002: Flutter stack

- Status: Accepted
- Date: 2026-11-18

## Context

There are many ways to do state, navigation, HTTP and translations in
Flutter. A consistent code base needs exactly one of each, chosen once.

## Decision

| Concern | Choice | Why |
| --- | --- | --- |
| SDK | Flutter stable, pinned in `.fvmrc` (3.50.0 at the start), Dart 3.14 | Reproducible builds; CI reads the same file |
| Widgets | `package:material_ui` | Material is decoupled from the framework since Flutter 3.50; `package:flutter/material.dart` is the deprecated path |
| Dependency injection | `provider` | Recommended by the architecture guide; simple, maintained, small |
| State | `ChangeNotifier` view models with `Command`s (`lib/utils/command.dart`) | From the guide; no extra package; works with `ListenableBuilder` |
| Navigation | `go_router` | Maintained by the Flutter team; declarative routes, redirects from state, deep links |
| HTTP | `package:http` | From the Dart team; enough for a JSON API without interceptors; `MockClient` for tests |
| Secrets | `flutter_secure_storage` | Keychain and Keystore behind one API |
| Translations | `flutter gen-l10n` with ARB files, English and German | Official tool, typed getters, plurals and placeholders |
| Logging | `package:logging` | Hierarchical loggers from the Dart team, no output in release builds below warning |
| Models | Hand-written immutable classes, JSON parsed with patterns | Dart 3 patterns make `fromJson` short and type-safe; no code generation step |
| Lints | `flutter_lints` + strict analyzer modes + extra rules in `analysis_options.yaml` | Official base, stricter where it prevents bugs |

The generated localisation code still names the Material localisations of
the framework, which `material_ui` widgets do not find. The app therefore
uses `appLocalizationsDelegates` from `lib/ui/core/localization.dart`
instead of `AppLocalizations.localizationsDelegates`. Revisit when
`gen-l10n` catches up.

## Consequences

- One way to do each thing; reviews can point to this table.
- Six runtime packages besides the SDK, all from the Dart or Flutter teams
  except `provider` and `flutter_secure_storage`, which are among the most
  used Flutter packages.
- Code generation is limited to translations, so `make ci` stays fast and
  there is no `build_runner` step.

## Alternatives considered

- **Riverpod:** powerful and popular, but a second concept of providers next
  to `ChangeNotifier`, code generation in its recommended form, and not what
  the official guide teaches.
- **BLoC / flutter_bloc:** see ADR 0001.
- **dio:** interceptors and cancellation are not needed yet; `http` is
  smaller. Revisit if retries and upload progress become necessary.
- **freezed / json_serializable:** less hand-written code per model, but a
  `build_runner` step, generated files and a slower feedback loop. Revisit
  when models become numerous.
- **OpenAPI client generation:** the server's OpenAPI fragments are not
  detailed enough for generated models yet; revisit once they are.
