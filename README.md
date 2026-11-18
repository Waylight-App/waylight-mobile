# Waylight for Android and iOS

[![CI](https://github.com/Waylight-App/waylight-mobile/actions/workflows/ci.yml/badge.svg)](https://github.com/Waylight-App/waylight-mobile/actions/workflows/ci.yml)

The companion app of [Waylight](https://github.com/Waylight-App/waylight),
the self-hosted start page. It connects to your own Waylight server and
brings your dashboard, to-dos and quick capture to your phone — with
nothing in between: no account at us, no telemetry, no requests to anyone
but your server.

> **Status:** early development (phase 0 of the [roadmap](ROADMAP.md)). The
> app connects to a server; sign-in and the dashboard follow in the next
> releases. Until then, Waylight can be [installed as a web app](https://github.com/Waylight-App/waylight/blob/main/docs/apps-and-offline.md)
> on your phone.

## Features

| | Status |
| --- | --- |
| Connect to your Waylight server, checked before it is saved | ✅ |
| English and German, light and dark mode | ✅ |
| Sign-in with password and two-factor code | Phase 1 |
| Your tabs and widgets | Phase 2 |
| To-dos, share sheet, smart search | Phase 3 |
| Offline use and notifications | Phase 4 |
| Google Play, App Store | Phase 5 |

## Requirements

- A Waylight server the phone can reach (same network or VPN), over HTTPS
  for now ([#9](https://github.com/Waylight-App/waylight-mobile/issues/9))
- Android 7 (API 24) or newer, iOS 15 or newer (the Flutter defaults; to be reviewed
  before 1.0)

## Install

There are no store releases yet. Every [release](https://github.com/Waylight-App/waylight-mobile/releases)
has an APK for testers; it is signed with a development key until store
signing is set up.

## Documentation

- **Developing:** [development setup](docs/development.md),
  [architecture](docs/architecture.md), [adding a feature](docs/adding-a-feature.md),
  [coding guidelines](docs/coding-guidelines.md), [testing](docs/testing.md)
- **Working together:** [workflow](docs/workflow.md),
  [releasing](docs/releasing.md), [decision records](docs/adr/README.md)
- **Trust:** [security and privacy](docs/security.md), [SECURITY.md](SECURITY.md)

The [documentation index](docs/index.md) lists everything.

## Contributing

Contributions are welcome. [CONTRIBUTING.md](CONTRIBUTING.md) covers the
setup and the rules for pull requests; planned work is on the
[roadmap](ROADMAP.md). Please follow the [Code of Conduct](CODE_OF_CONDUCT.md)
and report security problems as described in [SECURITY.md](SECURITY.md).

## Licence

[MIT](LICENSE), like the core of the server.
