# Releasing

Versions follow [Semantic Versioning](https://semver.org) and are derived
from the Conventional Commits on `main` by
[release-please](https://github.com/googleapis/release-please). Nobody edits
the version or the changelog by hand.

## How a release happens

1. Every push to `main` updates the release pull request
   (`chore(main): release x.y.z`). It bumps `version:` in `pubspec.yaml`
   (version name and build number) and adds the changelog section to
   `CHANGELOG.md`.
2. When the maintainer merges it, release-please tags `vx.y.z` and creates
   the GitHub release with the changelog.
3. The release workflow then builds the Android APK and attaches it to the
   release, and checks that the iOS app builds.

Until 1.0.0, `feat` bumps the minor version and `fix` the patch version;
breaking changes bump the minor version too.

Configuration: `release-please-config.json`,
`.release-please-manifest.json`, `.github/workflows/release.yml`.

## Identifiers

| Platform | Identifier |
| --- | --- |
| Android `applicationId` | `app.waylight.mobile` |
| iOS bundle identifier | `app.waylight.mobile` |

Store identifiers can never change after the first store release.

## Signing and stores

Not set up yet ([#25](https://github.com/Waylight-App/waylight-mobile/issues/25)). Until then
the release APK is signed with the debug key and meant for testers only,
and iOS builds are unsigned.

The plan:

- **Android:** an upload key in the GitHub secrets (`ANDROID_KEYSTORE_BASE64`,
  `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`),
  read by `android/app/build.gradle.kts`; Play App Signing; upload of the AAB
  to the internal track.
- **iOS:** App Store Connect API key and certificates in the secrets,
  Xcode cloud or `fastlane match`, upload to TestFlight.
- **F-Droid:** possible because the app has no proprietary dependencies;
  to be decided.

Signing material never goes into the repository; `.gitignore` excludes
keystores and `key.properties`.
