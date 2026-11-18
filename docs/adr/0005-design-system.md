# ADR 0005: Design system in code — theme tokens and shared components

- Status: Accepted
- Date: 2026-11-18

## Context

The mockups (`docs/design/`) repeat the same elements on every screen:
buttons that run an action, banners for errors and warnings, titled cards,
the wordmark. Built by hand on each screen, they drift apart in spacing,
colour and accessibility, and every screen has to remember loading states,
contrast and semantics again. The app also has to match the colours of the
web interface in light and dark mode.

## Decision

1. **Tokens in the theme.** `AppTheme` derives the colour scheme from the
   Amber, the default theme of the web interface (#54), with
   `DynamicSchemeVariant.fidelity`; Amber fills buttons and the darker
   accent text of the web theme is primary and sets component themes for buttons, fields and
   cards. Colours the scheme has no role for (warning, success) are a
   `ThemeExtension` (`StatusColors`). Spacing, sizes and radii are
   constants in `Dimens`.
2. **Shared components in `lib/ui/core/widgets`:** `CommandButton`,
   `MessageBanner`, `SectionCard`, `FormPage`, `Wordmark`, and
   `ViewModelHost` for the life cycle of view models. They depend on
   Flutter, the theme and `utils` only.
3. **Screens contain no styling:** no colour literals and no `fontSize`
   outside `ui/core/themes`, enforced by `test/conventions_test.dart`.
4. **Components grow with the issues** that need them (rule of three, or a
   pattern the design shows in several places); no component library up
   front.
5. **Shared error texts** in `ui/core/error_messages.dart`.

No widget catalogue tool (Widgetbook) for now: `docs/ui-components.md`
and the widget tests cover the handful of components; revisit when there
are more than about fifteen.

## Consequences

- Screens are shorter and look the same; loading, contrast and semantics
  are solved once.
- A design change (colour, radius, button height) is one edit.
- Contributors must look in `ui/core` before building UI; the docs and the
  review checklist point there.
- `ViewModelHost` adds one wrapper per route, in exchange for correct
  disposal and no state loss on router rebuilds.

## Alternatives considered

- **Third-party design system packages:** another dependency and look to
  fight against; Material 3 with our tokens is enough.
- **Wrapping every Material widget (`AppTextField`, `AppCard` …):** more
  code without benefit where a component theme does the job (KISS).
- **`ChangeNotifierProvider` per route for view models:** works, but makes
  screens read the view model from the context, which hides the
  dependency and makes them harder to test than a constructor argument.
