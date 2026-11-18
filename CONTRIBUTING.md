# Contributing

Thanks for your interest in the Waylight app! Please follow our
[Code of Conduct](CODE_OF_CONDUCT.md). Planned work is on the
[roadmap](ROADMAP.md); issues labelled
[good first issue](https://github.com/Waylight-App/waylight-mobile/labels/good%20first%20issue)
are a good place to start. Problems that also happen in the browser belong
to the [server repository](https://github.com/Waylight-App/waylight).

## Development setup (about 10 minutes)

Requirements: Flutter in the version of [`.fvmrc`](.fvmrc) (we recommend
[FVM](https://fvm.app)), `make`, and Android Studio or Xcode for a device.

```sh
git clone https://github.com/Waylight-App/waylight-mobile.git && cd waylight-mobile
fvm install        # optional: the pinned Flutter version
make deps          # packages
make ci            # generated files, format, analysis, tests, coverage
make run           # starts the app on the emulator or phone
```

Details, editor setup and troubleshooting: [docs/development.md](docs/development.md).

## Rules

1. **Issue first.** Every change starts with an issue (use the forms). Pull
   requests close it with `Closes #<number>`. Keep changes small: one issue
   per pull request.
2. **Architecture.** Read [docs/architecture.md](docs/architecture.md) and
   follow [adding a feature](docs/adding-a-feature.md). The layer rules are
   enforced by `test/architecture_test.dart`.
3. **Clean code.** Follow the [coding guidelines](docs/coding-guidelines.md).
   Code, comments and docs are in English; every public member has a doc
   comment; comments explain *why*.
4. **Tests** for every layer you touch ([testing](docs/testing.md)).
5. **Texts** come from `lib/l10n/app_en.arb` with a German translation in
   `app_de.arb`; run `make gen` and commit the result.
6. **Conventional Commits** for the pull request title
   (`feat(auth): sign in with a passkey`); it becomes the commit on `main`
   and the changelog entry ([workflow](docs/workflow.md#3-commits)).
   Branches are named `<type>/<issue>-<slug>`. Commits carry no trailers
   except `Signed-off-by`, and nothing in the repository attributes work to
   tools or assistants or links to sessions or chats.
7. **`make ci` before every push.** CI runs the same.
8. **Lean by default.** A new runtime dependency needs a reason in the pull
   request ([ADR 0003](docs/adr/0003-dependency-policy.md)).
9. **Significant decisions get an ADR** in `docs/adr/`.
10. **Privacy.** Never log or store passwords, tokens or cookies outside the
    secure storage; never send anything anywhere but the user's server
    ([security](docs/security.md)).

The complete flow from issue to release — branches, reviews, merging,
labels — is in [docs/workflow.md](docs/workflow.md).

## Licence of contributions

Contributions are made under the [MIT licence](LICENSE), the licence the app
is published under. There is nothing to sign.
