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
3. The release workflow then builds the Android APK and the Wear OS APK and
   attaches them to the release as `waylight-vX.Y.Z.apk` and
   `waylight-wear-vX.Y.Z.apk`. The watch app takes its version from
   `pubspec.yaml`, so both carry the same version.

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
| Wear OS `applicationId` | `app.waylight.mobile` (same as the phone, as stores expect for a watch app of the same listing) |
| iOS bundle identifier | `app.waylight.mobile` |

Store identifiers can never change after the first store release.

## Signing and stores

The release APKs (phone and watch) are signed with one fixed release key
([#284](https://github.com/Waylight-App/waylight-mobile/issues/284)), so
installed apps accept updates from later releases. The key is a PKCS12
keystore kept in four GitHub secrets:

| Secret | Content |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | the keystore file, base64 encoded |
| `ANDROID_KEYSTORE_PASSWORD` | the keystore password |
| `ANDROID_KEY_ALIAS` | the key alias |
| `ANDROID_KEY_PASSWORD` | the key password (for PKCS12 the same as the keystore password) |

The release workflow decodes the keystore and passes it to
`android/app/build.gradle.kts` and `wear/build.gradle.kts` through
`ANDROID_KEYSTORE_FILE` and the other variables. Without the secrets the
workflow fails instead of publishing debug-signed APKs. Local builds and pull
requests keep the debug key.

Losing the key means installed apps can no longer be updated: keep a copy of
the keystore and its password outside GitHub. iOS builds are unsigned.

### Google Play upload

The `android` job of the release workflow additionally builds the app
bundle and uploads it to the internal track of Google Play when the secret
`PLAY_SERVICE_ACCOUNT_JSON` exists. Without it both steps are skipped and
the release stays a GitHub release. The bundle is signed with the release
key above, which is registered as the upload key in Play App Signing.

| Secret | Content |
| --- | --- |
| `PLAY_SERVICE_ACCOUNT_JSON` | JSON key of a Google Cloud service account that has release rights for the app in the Play Console |

The first upload of a new app has to be made by hand in the Play Console;
the workflow only publishes further releases. Play accepts each version code
once; release-please raises the build number on every release.

Google Play and F-Droid are on hold
([ADR 0016](adr/0016-distribution-without-f-droid-and-google-play.md)):
releases are published through GitHub Releases and Obtainium only, and the
upload steps above stay skipped. Adding Google Play later needs a developer
account, the app entry, Play App Signing enrolment with the upload key, a
service account with the secret above, and a test release on the internal
track. iOS is paused; it is built, signed and uploaded to TestFlight locally
on the maintainer's Mac, certificates stay on that Mac.

Signing material never goes into the repository; `.gitignore` excludes
keystores and `key.properties`.
