# Development setup

This page gets a development copy running and lists the everyday commands.
The rules for pull requests are in [CONTRIBUTING.md](../CONTRIBUTING.md).

## Requirements

- **Flutter** in the version pinned in [`.fvmrc`](../.fvmrc) (currently
  3.50.0, stable). We recommend [FVM](https://fvm.app): `fvm install` in the
  repository picks the right version, and the `Makefile` uses it
  automatically. Without FVM, install that version by hand.
- `make`
- For Android: Android Studio or the command-line tools with an emulator,
  and Java 17.
- For iOS: a Mac with Xcode and CocoaPods / Swift Package Manager.
- A Waylight server to talk to. The quickest is the demo mode of the server:
  `DEMO_MODE=true` in its `.env` ([server docs](https://github.com/Waylight-App/waylight/blob/main/docs/demo.md)).

## First run

```sh
git clone https://github.com/Waylight-App/waylight-mobile.git
cd waylight-mobile
fvm install          # optional, picks the pinned Flutter version
make deps
make ci              # format, analysis, tests: everything CI checks
make run             # starts on the running emulator or connected phone
```

The emulator reaches a server on your computer at `http://10.0.2.2:8090`
(Android) or `http://localhost:8090` (iOS simulator). Both are
private addresses, so plain HTTP works
([ADR 0006](adr/0006-plain-http-in-the-home-network.md)).

## Links into the app

The app opens `waylight://<route>` links, e.g. `waylight://settings`
(`lib/routing/router.dart`, #47). Unknown routes open the dashboard; when
signed out, the app asks to sign in and continues to the link. Try one on
the emulator or simulator:

```sh
adb shell am start -a android.intent.action.VIEW -d "waylight://settings"
xcrun simctl openurl booted "waylight://settings"
```

## Everyday commands

| Command | What it does |
| --- | --- |
| `make deps` | `flutter pub get` |
| `make gen` | Generates the translations from the ARB files; commit the result |
| `make format` | Formats `lib/`, `test/` and `tool/` |
| `make lint` | `flutter analyze` with every info as an error |
| `make test` | Unit, widget, architecture and translation tests |
| `make coverage` | Tests with coverage; fails below 80 % |
| `make ci` | All of the above, exactly as CI runs it. Run it before every push |
| `make run` | Starts the app |

`make help` lists all targets.

## Editor

The repository ships settings for VS Code in `.vscode/` (format on save,
fix-all and organise imports on save, recommended extensions, launch
configurations). In Android Studio / IntelliJ enable *Format code on save*
and *Optimize imports on save* in the Dart settings; `.editorconfig` covers
the rest.

## Translations

The app is in English and German, like the web interface.

1. Add the key with a description to `lib/l10n/app_en.arb`:
   ```json
   "todosEmpty": "Nothing to do.",
   "@todosEmpty": { "description": "Shown when the to-do list is empty." }
   ```
2. Add the German text to `lib/l10n/app_de.arb`.
3. `make gen` and commit `lib/l10n/generated/`.
4. Use it as `context.l10n.todosEmpty`.

`test/l10n_test.dart` fails when a key is missing in a language, has no
description or uses different placeholders.

Adding a language: copy `app_de.arb` to `app_<code>.arb`, translate, run
`make gen`. The test picks the new file up by itself.

## Troubleshooting

- **"Run 'make gen' and commit the result"** in CI: the generated
  translations are out of date. Run `make gen` and commit.
- **`No MaterialLocalizations found`** in a test: pump screens with
  `tester.pumpScreen` from `test/testing/pump_app.dart`, which sets up the
  delegates of `lib/ui/core/localization.dart`.
