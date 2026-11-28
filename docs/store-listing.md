# Store listings

Everything the stores ask for besides the build. Android only; iOS is
paused ([ADR 0010](adr/0010-distribution-without-store-accounts.md)).
Google Play and F-Droid both read the
[fastlane](https://docs.fastlane.tools/actions/supply/#images-and-screenshots)
layout, so one set of files serves both.

## Texts

```text
fastlane/metadata/android/<locale>/
  title.txt              up to 30 characters
  short_description.txt  up to 80 characters
  full_description.txt   up to 4000 characters
  images/phoneScreenshots/   1.png, 2.png, ... (see below)
```

Locales are `en-US` and `de-DE`. Keywords exist only for the App Store and
are added with the iOS listing. A change to a text is a pull request like
any other; the app's `README.md` and these texts state the same features.

## Privacy policy

[Privacy policy](privacy-policy.md). The store forms take its URL:
`https://github.com/Waylight-App/waylight-mobile/blob/main/docs/privacy-policy.md`.

## Data safety facts (Google Play)

Facts for filling in the form; the answers follow from the code and
[Security and privacy](security.md).

| Question | Answer |
| --- | --- |
| Does the app collect data for the project? | No. The project operates no analytics, crash reporting or advertising. |
| Does the app share data with third parties? | No. Requests go to the server the person entered and, while push is on, to the push relay run by the project. |
| Data sent off the device | To the person's own server: account content (dashboard, to-dos, notes, places, search queries), sign-in credentials. To the push relay: a device identifier (key hash), IP address, end-to-end encrypted messages. |
| Approximate location | Read once on request (*Use my location*), rounded to about 100 m, saved on the person's own server. |
| Encryption in transit | HTTPS by default; plain HTTP only for private-network addresses (ADR 0006). Push content is end-to-end encrypted. |
| Deletion | Sign out deletes the session and local data; sessions end in the web interface of the server. The relay deletes messages after 72 hours. |
| Advertising ID, Google services | Not used. |
| Permissions | Listed with their use in the privacy policy. |

## Screenshots

Screenshots cannot be produced in CI or on the build server, which has no
emulator. Reproducible procedure on a machine with an Android emulator:

1. Start phone and tablet emulators (for example Pixel 8, Pixel Tablet),
   set English, then German.
2. Install the release APK and sign in to the public demo server
   `https://demo.getwaylight.app` (credentials in the `Makefile`,
   `WAYLIGHT_PASSWORD`).
3. Capture the dashboard, a tab with widgets, to-dos, quick capture and
   settings, once light and once dark
   (`adb exec-out screencap -p > 1.png`).
4. Save them as `fastlane/metadata/android/<locale>/images/phoneScreenshots/`
   (and `tenInchScreenshots/` for the tablet) in the order they should
   appear.

The demo content is the same for every capture, so the set can be repeated
for each release.

## F-Droid

Not listed for now. Releases are published through GitHub Releases and
Obtainium only; the facts and options are in
[ADR 0016](adr/0016-distribution-without-f-droid-and-google-play.md).
