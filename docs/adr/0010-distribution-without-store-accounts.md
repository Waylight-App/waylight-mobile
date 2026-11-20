# ADR 0010: Distribution without store accounts for now

- Status: Accepted
- Date: 2026-11-20
- Issues: [#180](https://github.com/Waylight-App/waylight-mobile/issues/180), [#185](https://github.com/Waylight-App/waylight-mobile/issues/185)

## Context

Publishing in Google Play needs a developer account (one-time fee; new
personal accounts also need a closed test with twelve testers over 14
days). Publishing on iOS needs the Apple Developer Program (yearly fee), and
so does every way to install outside the App Store in the EU: alternative
marketplaces and web distribution both require the membership. Push on iOS
needs it as well, because APNs only accepts apps of members.

## Decision

1. **Android through GitHub Releases.** Every release attaches the APK,
   which includes push over the relay's stream (ADR 0011). Users install
   and update it with [Obtainium](https://github.com/ImranR98/Obtainium) or
   by hand. No Google Play account for now; F-Droid follows when the app is
   ready for its review.
2. **No native iOS release yet.** iPhone users use the web interface, which
   shows live notifications while it is open (server issue waylight#583).
3. **The iOS code stays.** The `ios/` folder remains part of the Flutter
   project and is built locally on the maintainer's Mac (#171). The iOS
   parts that need the Apple account wait in the epic #185 with the label
   `blocked`. The relay keeps its APNs support.
4. **Stable signing for Android.** Updates through Obtainium only install
   over an APK with the same signature, so releases are signed with one
   release key in the repository secrets instead of the debug key (#25,
   Android part).

## Consequences

- Android users get everything, push included, without a store account.
- iPhone users get the web interface, but no native app, widgets or push
  until the Apple account exists.
- Store listings (#26) wait; buying the accounts later needs no change in
  the code, only signing and the listings.

## Alternatives considered

- **Google Play now:** a small fee, but the closed test with twelve testers
  is a hurdle before the app has users.
- **iOS sideloading with a free Apple ID:** signatures expire after seven
  days, at most three apps, and no push.
- **Deleting the iOS code or moving it to its own repository:** Flutter
  builds both platforms from one project; splitting it would break the
  local iOS build and lose the work.
