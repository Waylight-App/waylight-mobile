## Linked issue

Closes #

## Changes

-

## Screenshots

<!-- For UI changes: before / after, light and dark. Delete otherwise. -->

## Checklist

- [ ] The title follows Conventional Commits, e.g. `feat(auth): sign in with a passkey`
- [ ] The change respects the layers (UI → repositories → services, domain without Flutter); `test/architecture_test.dart` passes
- [ ] Tests for every affected layer (domain, service, repository, view model, widget)
- [ ] `make ci` passes locally
- [ ] Texts come from `lib/l10n/app_en.arb` with a German translation in `app_de.arb`
- [ ] Docs updated where needed (README, `docs/`, ADR for a significant decision)
- [ ] No new runtime dependency, or it is justified below ([ADR 0003](../docs/adr/0003-dependency-policy.md))
- [ ] Nothing logs or stores a password, token or cookie outside the secure storage
