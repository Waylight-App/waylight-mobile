# ADR 0011: Push over the relay's stream, one Android build without Google services

- Status: Accepted
- Date: 2026-11-20
- Issues: [#205](https://github.com/Waylight-App/waylight-mobile/issues/205), [waylight#582](https://github.com/Waylight-App/waylight/issues/582)
- Supersedes: decisions 1 and 2 of [ADR 0008](0008-push-notifications.md) (flavours, Firebase)

## Context

ADR 0008 receives push notifications on Android through Firebase Cloud
Messaging in a `store` flavour and builds an `fdroid` flavour without it.
Firebase puts Google code into the app and Google into every delivery. The
project's relay at `push.getwaylight.app` (Hetzner) now delivers to Android
itself over Server-Sent Events (server ADR 0027).

## Decision

1. **One Android build.** The `store` and `fdroid` flavours, Firebase
   Messaging and the `WAYLIGHT_FCM_*` build values are removed. CI fails
   if Firebase or Play services classes appear in the APK.
2. **A foreground service holds the stream.** While push is on,
   `PushService` keeps one Server-Sent Events stream to
   `https://push.getwaylight.app/v1/stream`. Android lets an app hold a
   connection in the background only this way; the service shows a silent,
   permanent notification on its own channel (type `remoteMessaging` from
   Android 14). It restarts after a reboot or an app update
   (`BootReceiver`).
3. **Reconnects.** `PushStream` reconnects with exponential backoff and
   full jitter (1 s up to 5 min), honours `Retry-After`, starts at once when
   the network comes back, treats 70 s without data as a dead connection
   (the relay sends a heartbeat every 25 s) and resumes with
   `Last-Event-ID`. The ID is saved after a message is shown, so a crash
   repeats a message rather than losing it.
4. **Device identity in the Keystore.** `StreamKey` creates an ECDSA P-256
   key in the Android Keystore and signs each stream request; the device
   token given to the instance is the base64url SHA-256 of its public key.
   The X25519 key for decrypting messages stays as in ADR 0008; Tink
   provides X25519 below Android 13 and has no network access.
5. **Battery.** The settings ask the person to lift the battery
   restrictions for the app while push is on, because Doze may otherwise
   cut the stream.
6. **One note on the connect screen.** "Your Waylight. Your data. Your
   server." for every build.

## Consequences

- No Google service takes part in delivering notifications; the APK can be
  published on F-Droid without changes.
- A permanent notification is visible while push is on, and the stream
  costs a little battery and data (a heartbeat every 25 seconds).
- Push depends on the relay being reachable; the instance still reaches
  people through its other channels.

## Alternatives considered

- **Firebase (ADR 0008):** no connection of our own, but Google code and
  Google in every delivery.
- **WorkManager polling:** no permanent notification, but delays of 15
  minutes and more.
- **UnifiedPush:** needs a distributor app; it can be added later next to
  the stream.
