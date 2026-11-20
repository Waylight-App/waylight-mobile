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
   release as `waylight-vX.Y.Z.apk`.

Until there are store accounts (ADR 0010), GitHub Releases is how the app
is distributed. Users install the APK by hand or with
[Obtainium](https://github.com/ImranR98/Obtainium), which watches the
releases of `Waylight-App/waylight-mobile` and installs updates.

Before merging the release pull request, the maintainer builds the iOS app
locally on a Mac (`flutter build ios --release --no-codesign`) and confirms
in the pull request that it builds. GitHub Actions does not build iOS (#171).

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
- **iOS:** built, signed and uploaded to TestFlight locally on the
  maintainer's Mac; certificates stay on that Mac.
- **F-Droid:** possible because the app has no proprietary dependencies
  (ADR 0011); to be decided.

Signing material never goes into the repository; `.gitignore` excludes
keystores and `key.properties`.
