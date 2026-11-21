# ADR 0014: Barcode scanning on the device

- Status: Accepted
- Date: 2026-11-21

## Context

Adding a parcel means typing a long tracking number (#196); the camera can
read the barcode of the shipping label instead. The app has no Google
services (ADR 0011), so Google ML Kit and the Play services scanner are
not options. Pictures from the camera are personal data and must not leave
the phone.

## Decision

The Android app uses `zxing-android-embedded` (JourneyApps, Apache 2.0) on
top of the ZXing core. It brings its own camera screen, asks for the
camera permission when it opens and returns only the decoded text through
the channel `app.waylight/scan`. It reads Code 128, Code 39, Interleaved
2 of 5, Data Matrix and QR codes. No image is stored or sent.
`trackingNumberFrom` turns the text into a tracking number (carrier links,
GS1 identifiers); the person confirms or corrects it before it is sent.

## Consequences

One native dependency of about 0.5 MB, maintained for many years, without
network access. Recognition of damaged or curved labels is weaker than
ML Kit's; typing the number stays possible. The ZXing core lives under the
package `com.google.zxing`, which is not a Google service and is allowed
by the CI check for Firebase and Play services. iOS will use the system's
own scanner later (#185).

## Alternatives considered

- Google ML Kit or the Play services code scanner: excluded by ADR 0011.
- The Flutter `camera` plugin with a Dart port of ZXing: more code of our
  own and slower decoding on older phones.
- No in-app scanner (copying the number from another app): no permission
  and no dependency, but no help with a printed label.
