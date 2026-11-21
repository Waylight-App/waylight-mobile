# ADR 0015: A standalone Wear OS app with its own app session

- Status: Accepted
- Date: 2026-11-21
- Issue: [#199](https://github.com/Waylight-App/waylight-mobile/issues/199)

## Context

A glance at the wrist is quicker than one at the phone: the next event, how
many to-dos are open, my presence status, the short states the server
already prepares for small surfaces (`GET /api/<module>/compact`, the
`CompactState` of the server's OpenAPI description). Wear OS shows such
glances in an app and in tiles.

A watch app can get its data in two ways. The usual one is the Wearable
Data Layer: the phone app fetches the data and sends it over Bluetooth.
That API is part of Google Play services, which the app does not use
(ADR 0011). The other way is to let the watch talk to the Waylight server
itself, over Wi-Fi, LTE or the connection the phone shares with it.

Flutter does not run well on watches, and tiles are built with a native
layout library anyway.

## Decision

1. **Standalone app.** The watch app in `wear/` talks to the user's
   Waylight server directly. It works when the phone app is closed or not
   installed; the manifest marks it as standalone. The Wearable Data Layer
   is not used.
2. **Native Kotlin, AndroidX only.** The app is written in Kotlin with
   Compose for Wear OS and the Wear Tiles and ProtoLayout libraries from
   AndroidX. Nothing from Google Play services or Firebase is allowed; CI
   checks the watch APK's dex for `com/google/firebase` and
   `com/google/android/gms`, as for the phone APK. HTTP goes through the
   platform's `HttpURLConnection`, JSON through `org.json`. The pairing QR
   code is drawn with the ZXing core, the offline library the phone app
   already uses for scanning (ADR 0014).
3. **Own Gradle build.** `wear/` is a Gradle build of its own with its own
   wrapper. It needs no Flutter SDK; a CI job builds it on Linux and runs
   its unit tests. It uses the same Android Gradle Plugin and Kotlin
   versions as `android/` and takes its version from `pubspec.yaml`, so
   release-please versions both apps together. It shares the phone app's
   application ID, which keeps a later store listing for both possible.
4. **Own app session, paired from the phone.** The watch gets its own app
   session (server #559), so it shows up and can be revoked on its own
   under Settings → Apps. To pair, the watch shows a QR code with its
   address in the local network and a fresh 256-bit key. The phone app
   scans it, creates a pairing code with its own session
   (`POST /api/auth/app-sessions/pairing-code`) and sends the server
   address and the code to the watch, encrypted with AES-256-GCM under that
   key. The watch redeems the code with `POST /api/auth/app-sessions`. As a
   fallback the server address and a pairing code can be typed on the
   watch. Pairing codes are single-use and valid for five minutes.
5. **Secrets in the watch's keystore.** The bearer token is encrypted with
   an AES key that lives in the watch's Android Keystore and never leaves
   it; only the ciphertext is stored in the app's private files. Backups
   are off. Signing out ends the session on the server and deletes the
   token.
6. **Glances from existing endpoints.** The app reads the next event
   (`/api/calendar/events`), the open to-dos (`/api/todos/compact`), the
   own presence status (`/api/presence`) and the compact states of the
   modules that offer one. Modules that are switched off or unknown to an
   older server answer 404 and are left out. The same snapshot feeds the
   app's screen and a tile, which shows the age of the data.
7. **Refresh without the phone.** A periodic WorkManager job refreshes the
   snapshot every 30 minutes while the watch is on a network, and the tile
   asks for an update when it becomes visible. Plain HTTP follows ADR 0006.
8. **Distribution.** The watch APK is attached to the same GitHub release
   as the phone APK and installed with `adb` or a sideloading tool; it is
   signed like the phone APK until release signing exists (#25).

## Consequences

- The watch needs its own network path to the server. A server that is only
  reachable in the home network is only reachable from the watch there, or
  over the phone's connection when that one is in the home network.
- Pairing through the phone needs both devices in the same Wi-Fi once. The
  phone side is a separate change in the Flutter app. The typed fallback
  needs the pairing code as text, which the web interface only shows as a
  QR code so far.
- The watch polls instead of receiving pushes; the data is up to 30 minutes
  old when the tile is not looked at, and the tile says how old.
- A second code base in another language. It stays small: a thin HTTP
  client, a snapshot, one screen list and one tile.
- Users of the Google Play store cannot get the watch app there yet; the
  shared application ID keeps that door open.

## Alternatives considered

- **Wearable Data Layer through the phone:** the usual design and kinder to
  the watch's battery, but it requires Google Play services on both
  devices (excluded by ADR 0011) and the phone app running in the
  background.
- **Flutter on the watch:** large binary, no tiles, round screens poorly
  supported.
- **Signing in on the watch with username and password:** typing a password
  on a watch is error-prone, and accounts with passkeys or two factors
  could not sign in at all.
- **A new device-code flow on the server (watch shows a short code, the
  user confirms it in the web interface):** convenient, but needs a server
  change; the handover from the phone works with the endpoints that exist.
