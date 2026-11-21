# Waylight for Android and iOS

[![CI](https://github.com/Waylight-App/waylight-mobile/actions/workflows/ci.yml/badge.svg)](https://github.com/Waylight-App/waylight-mobile/actions/workflows/ci.yml)

The companion app of [Waylight](https://github.com/Waylight-App/waylight),
the self-hosted start page. It connects to your own Waylight server and
brings your dashboard, to-dos and quick capture to your phone — with
nothing in between: no account at us, no telemetry, no requests to anyone
but your server. Push notifications, if you switch them on, come end-to-end
encrypted through the Waylight relay; no Google service is involved.

> **Status:** Android app with every widget of the web interface, push
> notifications, home screen widgets and the share sheet, distributed through
> GitHub Releases. No store release yet; on the iPhone, use the
> [web interface](https://github.com/Waylight-App/waylight/blob/main/docs/apps-and-offline.md)
> for now ([ADR 0010](docs/adr/0010-distribution-without-store-accounts.md)).

## Features

| | Android | iOS |
| --- | --- | --- |
| Sign-in with password, two-factor code or QR code | ✅ | built locally |
| Your tabs and every widget of the web interface | ✅ | built locally |
| To-dos, notes, smart search with answers, quick capture | ✅ | built locally |
| Offline copy of the dashboard | ✅ | built locally |
| Wall display for an old tablet, with a kiosk link from the server | ✅ | later |
| Quick Settings tiles: add a to-do, switch a device, set your status | ✅ | – |
| Up to three server addresses, e.g. home network and on the go; the one that answers is used | ✅ | built locally |
| Push notifications, end-to-end encrypted, without Google | ✅ | waits for the Apple account |
| Reminders for to-dos, events and birthdays, shown by the phone itself, also offline | ✅ | later |
| Home screen widgets, share sheet, background refresh | ✅ | waits for the Apple account |
| Store release | later | later |

## Requirements

- A Waylight server the phone can reach (same network or VPN), over HTTPS
  for now ([#9](https://github.com/Waylight-App/waylight-mobile/issues/9))
- Android 7 (API 24) or newer, iOS 15 or newer (the Flutter defaults; to be reviewed
  before 1.0)

## Install

Download `waylight-vX.Y.Z.apk` from the latest
[release](https://github.com/Waylight-App/waylight-mobile/releases). It contains
no Google services. [Obtainium](https://github.com/ImranR98/Obtainium) installs
it and keeps it up to date: add `https://github.com/Waylight-App/waylight-mobile`
as an app.

## Documentation

- **Developing:** [development setup](docs/development.md),
  [architecture](docs/architecture.md), [adding a feature](docs/adding-a-feature.md),
  [code conventions](docs/code-conventions.md),
  [UI components](docs/ui-components.md), [design](docs/design/README.md), [testing](docs/testing.md)
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
