# Roadmap

The app is planned in public, like the server. Every phase is an **epic**
(a parent issue labelled `epic`) whose sub-issues are the actual work; the
progress bar of an epic shows how far the phase is. The order inside a
phase is a guideline, not a promise. Each phase ends with a release.

| Phase | Theme | Release | Status |
| --- | --- | --- | --- |
| [Phase 0 – Foundation](https://github.com/Waylight-App/waylight-mobile/issues/1) | Architecture, CI, workflow, docs; connect to a server | v0.1 | in progress |
| [Phase 1 – Sign-in](https://github.com/Waylight-App/waylight-mobile/issues/2) | Password and two-factor sign-in, sessions, settings | v0.2 | planned |
| [Phase 2 – Dashboard](https://github.com/Waylight-App/waylight-mobile/issues/3) | Tabs, native widgets, fallback, refresh | v0.3 | planned |
| [Phase 3 – Everyday actions](https://github.com/Waylight-App/waylight-mobile/issues/4) | To-dos, share sheet, smart search | v0.4 | planned |
| [Phase 4 – Offline and notifications](https://github.com/Waylight-App/waylight-mobile/issues/5) | Offline cache and queue, notifications | v0.5 | planned |
| [Phase 5 – Release 1.0](https://github.com/Waylight-App/waylight-mobile/issues/6) | Signed builds, stores, accessibility audit | v1.0 | planned |

## Phase 0 – Foundation (v0.1)

- [#8](https://github.com/Waylight-App/waylight-mobile/issues/8) Project setup: Flutter app, architecture, CI and documentation
- [#7](https://github.com/Waylight-App/waylight-mobile/issues/7) Connect to a Waylight server (reference implementation of the architecture)
- [#9](https://github.com/Waylight-App/waylight-mobile/issues/9) Transport security: decide how plain HTTP to local servers is allowed
- [#10](https://github.com/Waylight-App/waylight-mobile/issues/10) App icon, splash screen and the Waylight look
- [#11](https://github.com/Waylight-App/waylight-mobile/issues/11) Integration tests on an emulator against a demo server

## Phase 1 – Sign-in (v0.2)

- [#12](https://github.com/Waylight-App/waylight-mobile/issues/12) Sign in with password and two-factor code
- [#13](https://github.com/Waylight-App/waylight-mobile/issues/13) Stay signed in: keep the session securely, handle expiry, sign out
- [#14](https://github.com/Waylight-App/waylight-mobile/issues/14) Settings screen: server, account, language, theme and about
- [#15](https://github.com/Waylight-App/waylight-mobile/issues/15) Use app sessions once the server offers them — needs [Waylight-App/waylight#559](https://github.com/Waylight-App/waylight/issues/559)

## Phase 2 – Dashboard (v0.3)

- [#16](https://github.com/Waylight-App/waylight-mobile/issues/16) Show the tabs of the dashboard
- [#17](https://github.com/Waylight-App/waylight-mobile/issues/17) Native widgets: clock, weather, to-dos, notes and bookmarks
- [#18](https://github.com/Waylight-App/waylight-mobile/issues/18) Fallback for widgets without a native renderer
- [#19](https://github.com/Waylight-App/waylight-mobile/issues/19) Pull to refresh and the age of the data

## Phase 3 – Everyday actions (v0.4)

- [#20](https://github.com/Waylight-App/waylight-mobile/issues/20) Add, tick off and edit to-dos
- [#21](https://github.com/Waylight-App/waylight-mobile/issues/21) Save to Waylight from the share sheet
- [#22](https://github.com/Waylight-App/waylight-mobile/issues/22) Smart search

## Phase 4 – Offline and notifications (v0.5)

- [#23](https://github.com/Waylight-App/waylight-mobile/issues/23) Keep the last dashboard for offline use
- [#24](https://github.com/Waylight-App/waylight-mobile/issues/24) Offline queue for to-dos with conflict resolution
- [#27](https://github.com/Waylight-App/waylight-mobile/issues/27) Notifications from Waylight on the phone

## Phase 5 – Release 1.0 in the stores

- [#25](https://github.com/Waylight-App/waylight-mobile/issues/25) Signed release builds for Google Play and the App Store
- [#26](https://github.com/Waylight-App/waylight-mobile/issues/26) Store listings, screenshots and privacy policy
- [#28](https://github.com/Waylight-App/waylight-mobile/issues/28) Accessibility audit with TalkBack and VoiceOver

## Later

Ideas without a phase: home-screen widgets (Android App Widgets, iOS
WidgetKit), tablet layout with the desktop grid, passkeys and single
sign-on in the app, Wear OS / watchOS glances, kiosk mode on tablets.
Propose more with the feature form.

## Principles that do not change

1. **Private by default:** the app talks to your server and nothing else.
   No telemetry, no analytics, no crash reporting service.
2. **The server decides:** permissions, roles, lockouts and the network
   allow-list of the server apply to the app unchanged.
3. **Lean:** few dependencies, each with a reason ([ADR 0003](docs/adr/0003-dependency-policy.md)).
4. **One way to do things:** the architecture of the Flutter team,
   enforced in CI ([ADR 0001](docs/adr/0001-app-architecture.md)).
