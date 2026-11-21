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

### Settings areas

The settings open on a start page with one row per area (#231). Each area
is its own screen and has a link of its own; back from an area opened by
a link leads to the start page. The areas are defined in
`lib/ui/settings/view_models/settings_area.dart` and routed in
`lib/routing/router.dart`.

| Area | Link | Holds |
| --- | --- | --- |
| Account & security | `waylight://settings/account` | who is signed in, password and sign-in methods (`/settings/security`), sign out |
| Server & connection | `waylight://settings/server` | address and version, addresses in the order they are tried, other servers, checking the addresses again, disconnecting |
| Appearance | `waylight://settings/appearance` | theme, wallpaper colours, language |
| Notifications & reminders | `waylight://settings/notifications` | push notifications with the battery hint, reminders on the phone |
| This phone | `waylight://settings/phone` | app lock, home screen widgets, Quick Settings tiles, pairing a watch, wall display |
| About & help | `waylight://settings/about` | app version, licences, source code, privacy, diagnostic report |

The start page hides *Notifications & reminders* on phones that have
neither push nor reminders; its link still opens and says so.

## Icons, launch screen and font

The sources are in `assets/`:

- `assets/icon/icon.svg` (full icon), `foreground.svg` (adaptive icon on
  Android, inside the safe zone) and `monochrome.svg` (themed icons), drawn
  after the favicon of the web interface. The PNGs next to them are the SVGs
  rendered at 1024 × 1024 with any SVG renderer, e.g.
  `rsvg-convert -w 1024 -h 1024 icon.svg -o icon.png`.
- `assets/fonts/Fraunces-SemiBold.ttf`: the wordmark, an instance of the
  Fraunces variable font (weight 600) reduced to Latin; licence in
  `Fraunces-OFL.txt`.

After changing an icon or the launch screen colours in `pubspec.yaml`:

```sh
dart run flutter_launcher_icons
dart run flutter_native_splash:create
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

### Push notifications

There is one Android build. Push notifications come over a Server-Sent
Events stream from the relay at `push.getwaylight.app` (ADR 0011, server
ADR 0027); a foreground service holds it while push is on. Nothing needs to
be configured to build; to try push, sign in to an instance that has the
channel *Waylight app* turned on and switch on notifications in the app's
settings.

### What CI builds

Every pull request runs `make ci`, builds the Android app and builds and
tests the Wear OS app in `wear/` ([Waylight on Wear OS](wear-os.md#build-it)). GitHub
Actions never builds the iOS app (#171): the maintainer builds it locally on
a Mac and confirms before each release that it builds. If you change native
iOS code, build it locally with `flutter build ios --debug --no-codesign` and
say in the pull request that you did.

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
