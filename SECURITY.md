# Security policy

## Reporting a vulnerability

Please do **not** open a public issue. Use GitHub's
[private vulnerability reporting](https://github.com/Waylight-App/waylight-mobile/security/advisories/new)
on this repository instead. You will get an answer as soon as possible.

Vulnerabilities of the server or the web interface belong to the
[server repository](https://github.com/Waylight-App/waylight/security/advisories/new).

## Supported versions

Only the latest release receives security fixes.

## What the app keeps on the device

- The address of your Waylight server and, once sign-in exists, the session
  of the app. Both are stored in the iOS Keychain or the Android Keystore,
  never in plain files or logs.
- Signing out deletes the session; *Use another server* deletes everything
  the app stored.

The app has no telemetry, no analytics and no crash reporting service. It
sends requests only to the server you entered. The details are in
[docs/security.md](docs/security.md).
