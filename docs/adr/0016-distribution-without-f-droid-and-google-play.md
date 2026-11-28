# ADR 0016: Distribution without F-Droid and Google Play for now

- Status: Accepted
- Date: 2026-11-28
- Issues: [#26](https://github.com/Waylight-App/waylight-mobile/issues/26), [#25](https://github.com/Waylight-App/waylight-mobile/issues/25), [#344](https://github.com/Waylight-App/waylight-mobile/issues/344)

## Context

ADR 0010 publishes the Android app through GitHub Releases and left
F-Droid and Google Play open. Both are now prepared in the repository:

- The app has no proprietary dependency and no Google code; CI checks the
  APK for it (ADR 0011). Store texts are in `fastlane/metadata/android`.
- F-Droid builds the app from source and signs it with its own key unless
  the build is reproducible. An APK from GitHub and one from F-Droid then
  cannot update each other. IzzyOnDroid would serve the GitHub APKs with
  the upstream signature; an own F-Droid repository would need its own
  index and hosting.
- The release workflow signs the APKs with the release key and builds and
  uploads an app bundle to the internal track of Google Play when the
  secret `PLAY_SERVICE_ACCOUNT_JSON` exists (#25).

## Decision

1. **GitHub Releases and Obtainium only.** Android releases are published
   on GitHub Releases and installed and updated with
   [Obtainium](https://github.com/ImranR98/Obtainium) or by hand.
2. **No F-Droid listing for now.** Neither the official F-Droid repository,
   nor IzzyOnDroid, nor an own F-Droid repository.
3. **Google Play stays on hold.** No developer account for now; the Play
   listing and the data safety form wait as well.

## Consequences

- Every release APK is signed with the release key from the repository
  secrets, so Obtainium installs each update over the previous one.
- The Play upload steps stay in the release workflow and are skipped while
  the secret `PLAY_SERVICE_ACCOUNT_JSON` is absent. Adding the account
  later needs the secret and the first upload by hand, no code change.
- The store texts in `fastlane/metadata` stay in the repository and can be
  used by F-Droid or Google Play later.
- F-Droid can be revisited later in a new ADR; the facts and options are
  kept in this record.

## Alternatives considered

- **Official F-Droid repository:** builds and signs with F-Droid's key, so
  existing GitHub installs could not update to it without a reproducible
  build.
- **IzzyOnDroid:** keeps the upstream signature; not chosen for now.
- **Own F-Droid repository:** needs an index and hosting maintained by the
  project.
- **Google Play now:** needs the developer account; on hold.
