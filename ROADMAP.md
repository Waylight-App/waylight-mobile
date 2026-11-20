# Roadmap

The app is planned in public, like the server. Every phase is an **epic**
(a parent issue labelled `epic`) whose sub-issues are the actual work; the
progress bar of an epic shows how far the phase is. The order inside a
phase is a guideline, not a promise. Versions and the changelog come from
release-please ([releasing](docs/releasing.md)).

| Phase | Theme | Status |
| --- | --- | --- |
| [Phase 0 – Foundation](https://github.com/Waylight-App/waylight-mobile/issues/1) | Architecture, CI, workflow, docs, design system | done |
| [Phase 1 – Sign-in](https://github.com/Waylight-App/waylight-mobile/issues/2) | Password and two-factor code, QR pairing, sign-in through the browser, app lock, deep links | done |
| [Phase 2 – Dashboard](https://github.com/Waylight-App/waylight-mobile/issues/3) | Tabs, native widgets, fallback, refresh, several servers, tablets, editing the dashboard | done |
| [Phase 3 – Everyday actions](https://github.com/Waylight-App/waylight-mobile/issues/4) | To-dos, share sheet, smart search, home screen widgets, app shortcuts | done |
| [Phase 4 – Offline and notifications](https://github.com/Waylight-App/waylight-mobile/issues/5) | Offline copy and queue, background refresh, end-to-end encrypted push | done |
| [Phase 5 – Release](https://github.com/Waylight-App/waylight-mobile/issues/6) | Signed builds, store listings, accessibility audit; for now without store accounts | in progress |
| [Phase 6 – Every Waylight widget and feature](https://github.com/Waylight-App/waylight-mobile/issues/99) | A native renderer for every widget kind, and the screens behind them | done |
| [Phase 7 – The app in everyday phone use](https://github.com/Waylight-App/waylight-mobile/issues/187) | Home and away addresses, reminders, Quick Settings, kiosk mode, NFC, Wear OS | planned |
| [Phase 8 – Team features](https://github.com/Waylight-App/waylight-mobile/issues/188) | Presence, absences, announcements | planned |
| [iOS release](https://github.com/Waylight-App/waylight-mobile/issues/185) | Share extension, WidgetKit, background refresh, push through APNs, TestFlight | blocked: no Apple Developer account yet |

## Done

Phases 0–4 and 6 are complete; their epics list every issue. In short: the
Android app signs in like the web interface (password, two-factor code, QR
code, passkeys and single sign-on through the browser), shows every tab and
every widget of the server natively, works offline, captures from the share
sheet, has home screen widgets and receives end-to-end encrypted push
notifications.

## Phase 5 – Release

Until the app has users, it is distributed without paid store accounts:
APKs in GitHub Releases, kept up to date with Obtainium
([#180](https://github.com/Waylight-App/waylight-mobile/issues/180), ADR 0010).

- [#25](https://github.com/Waylight-App/waylight-mobile/issues/25) Signed release builds for Google Play and the App Store
- [#26](https://github.com/Waylight-App/waylight-mobile/issues/26) Store listings, screenshots and privacy policy (blocked by the store accounts)
- [#28](https://github.com/Waylight-App/waylight-mobile/issues/28) Accessibility audit with TalkBack and VoiceOver

## Phase 7 – The app in everyday phone use

Android first; the iOS parts follow with the iOS release.

- [#189](https://github.com/Waylight-App/waylight-mobile/issues/189) Home and away: use the address at home and the address on the go
- [#190](https://github.com/Waylight-App/waylight-mobile/issues/190) Reminders on the device for to-dos, events and birthdays
- [#191](https://github.com/Waylight-App/waylight-mobile/issues/191) Focus timer keeps running when the app is closed
- [#192](https://github.com/Waylight-App/waylight-mobile/issues/192) Quick Settings tiles: capture, a smart home device, my status
- [#193](https://github.com/Waylight-App/waylight-mobile/issues/193) Kiosk mode for wall tablets
- [#194](https://github.com/Waylight-App/waylight-mobile/issues/194) Smart home in Android's device controls
- [#195](https://github.com/Waylight-App/waylight-mobile/issues/195) NFC tags that run a Waylight action
- [#196](https://github.com/Waylight-App/waylight-mobile/issues/196) Scan tracking numbers into the parcels widget — needs a decision
- [#197](https://github.com/Waylight-App/waylight-mobile/issues/197) Diagnostic report for bug reports
- [#198](https://github.com/Waylight-App/waylight-mobile/issues/198) Use the wallpaper colours (Material You) as a theme option
- [#199](https://github.com/Waylight-App/waylight-mobile/issues/199) Glances on Wear OS watches — needs a decision

## Phase 8 – Team features

For servers built with the `ee` features and a licence key that includes
the module; the app hides them otherwise.

- [#200](https://github.com/Waylight-App/waylight-mobile/issues/200) Presence: who is where today, and set my status
- [#201](https://github.com/Waylight-App/waylight-mobile/issues/201) Absences: who is away, and enter my own
- [#202](https://github.com/Waylight-App/waylight-mobile/issues/202) Announcements: read, mark as read and write — needs a decision

## iOS release

The iOS code stays in the repository and is built locally
([#171](https://github.com/Waylight-App/waylight-mobile/issues/171)); the release waits for an Apple Developer account. Until
then, iPhone users use Waylight as a web app with Web Push.

- [#181](https://github.com/Waylight-App/waylight-mobile/issues/181) Share extension for *Save to Waylight*
- [#182](https://github.com/Waylight-App/waylight-mobile/issues/182) Home screen widgets with WidgetKit
- [#183](https://github.com/Waylight-App/waylight-mobile/issues/183) Background refresh with BGAppRefreshTask
- [#184](https://github.com/Waylight-App/waylight-mobile/issues/184) Push notifications through APNs

## Later

Ideas without an issue yet: watchOS glances (with the iOS release), lock
screen widgets, more languages as soon as the web interface has them.
Propose more with the feature form.

## Principles that do not change

1. **Private by default:** the app talks to your server and nothing else.
   No telemetry, no analytics, no crash reporting service. Push
   notifications, if you switch them on, travel end-to-end encrypted
   through the Waylight relay ([ADR 0008](docs/adr/0008-push-notifications.md)).
2. **The server decides:** permissions, roles, lockouts and the network
   allow-list of the server apply to the app unchanged.
3. **Lean:** few dependencies, each with a reason ([ADR 0003](docs/adr/0003-dependency-policy.md)).
4. **One way to do things:** the architecture of the Flutter team,
   enforced in CI ([ADR 0001](docs/adr/0001-app-architecture.md)).
