# ADR 0008: Push notifications in native code, Firebase only in the store build

- Status: Accepted; decisions 1 and 2 superseded by [ADR 0011](0011-push-over-the-relay-stream.md)
- Date: 2026-11-19

## Context

The server sends notifications to phones through its push relay, Google
Firebase Cloud Messaging (FCM) and the Apple Push Notification service
(APNs), encrypted for each device (server ADR 0025). Two facts shape the
app side:

- Firebase Messaging is a proprietary library. ADR 0003 keeps proprietary
  binaries out of the app, so that it can be published on F-Droid.
- A notification has to be decrypted and shown while the app is closed.
  Starting Flutter for every message is slow and costs battery; Android's
  messaging service and iOS' notification service extension run native code
  only.

## Decision

1. **Two Android flavours.** `store` (Google Play) receives push
   notifications through Firebase Messaging; `fdroid` contains no Firebase
   code and no push notifications. Firebase and its dependencies are
   `storeImplementation` only. Every Android build names its flavour
   (`--flavor store` or `--flavor fdroid`); iOS has no flavours.
2. **No Firebase Flutter plugin.** A plugin is a dependency of every build,
   so it would end up in the F-Droid build as well. The store flavour uses
   the Firebase Android SDK directly; Firebase is initialised in code from
   build-time values (`waylight.fcm.*` Gradle properties), not from a
   `google-services.json` in the repository. Without those values the store
   build behaves like the F-Droid build.
3. **The device key lives in native code.** The X25519 key pair is created
   and kept by the platform: on Android in a Tink keyset encrypted with a
   key of the Android Keystore, on iOS in the Keychain of an app group that
   the notification service extension can read. Dart asks for the public key
   and for the push token through the method channel `app.waylight/push`
   and never sees the private key.
4. **Decryption where the message arrives.** Android decrypts in its
   `FirebaseMessagingService` with Tink (X25519, HKDF-SHA256, AES-256-GCM)
   and shows the notification itself; iOS decrypts in the notification
   service extension with CryptoKit. Tapping opens the message's
   `waylight://` link (#47).
5. **Dart keeps the protocol in one place for tests.** The server's
   `pushproto` package defines the format; the native code is tested against
   a payload sealed by it.
6. **iOS receives through APNs directly, not through Firebase.** The push
   relay (server ADR 0025) sends to FCM for Android and to APNs for iOS. The
   iOS app contains no Firebase code; only Apple takes part in delivering to
   iPhones. The APNs key stays with the relay.

## Consequences

- F-Droid users get no push notifications; they keep ntfy, e-mail and the
  other channels of the server.
- Two dependencies in the store flavour only: Firebase Messaging and Tink
  (Apache 2.0). The Dart package `cryptography` is no longer needed.
- Commands that build or run the Android app need `--flavor`; `make` targets
  pass it.

## Alternatives considered

- **firebase_messaging plugin:** simplest, but it would put Firebase into the
  F-Droid build and decrypt in a background Flutter isolate.
- **Key in Dart's secure storage** (as first built in #94): the native
  receivers cannot read it reliably, so every message would need Flutter.
- **Firebase for iOS as well:** one provider API in the relay, but the iOS
  app would carry the Firebase SDK, Google would take part in every iPhone
  delivery, and APNs would still be needed behind Firebase.
- **UnifiedPush for everyone:** needs a distributor app on the phone; it can
  be added to the F-Droid build later.
