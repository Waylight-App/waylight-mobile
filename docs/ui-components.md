# UI components

The design system of the app in code: **tokens** (colours, type, spacing)
and **components** (widgets every screen reuses). Screens are built from
these and plain Material widgets, so they stay short, look the same and are
accessible without extra work. The look follows the [mockups](design/README.md);
the rules for writing components are in the
[code conventions](code-conventions.md#5-reusable-components); the decision
behind it is [ADR 0005](adr/0005-design-system.md).

Everything lives in `lib/ui/core/`:

```
ui/core/
├── themes/
│   ├── app_theme.dart       light and dark ThemeData, component themes
│   ├── status_colors.dart   warning and success colours (ThemeExtension)
│   └── dimens.dart          spacing, sizes, radii
├── widgets/                 the components below
├── error_messages.dart      shared texts for failures
└── localization.dart        context.l10n and the delegates
```

## Tokens

### Colours

Use the roles, never colour values (a test enforces it).

| Need | Use |
| --- | --- |
| Main action, links, selected tab | `colorScheme.primary` / `onPrimary` |
| Highlighted container (weather card, selected chip) | `primaryContainer` / `onPrimaryContainer` |
| Page background | `surface` (set by the theme) |
| Cards | `surfaceContainer` (set by the card theme) |
| Secondary text, icons | `onSurfaceVariant` |
| Dividers, outlines | `outlineVariant`, `outline` |
| Errors | `error`, `errorContainer` / `onErrorContainer` |
| Warnings (HTTP, offline, stale data) | `StatusColors.of(context).warning`, `warningContainer` / `onWarningContainer` |
| Success (service up) | `StatusColors.of(context).success` |

The scheme comes from Amber `#F2B441`, the default theme of the web
interface, with `DynamicSchemeVariant.fidelity`. Amber is the surface of
filled buttons, with `#1A1206` on it; `primary` (text, icons, focus) is the
readable accent text of the web theme, `#9C5D00` in light and `#FFD27A` in
dark mode.
All pairs above have a contrast of at least 4.5:1 in light and dark.

### Type

Text styles come from `Theme.of(context).textTheme` (Material 3 type
scale); never set `fontSize`.

| Use | Style |
| --- | --- |
| Screen title in a form | `headlineMedium` |
| App bar title, sheet title | `titleLarge` |
| Card title | `titleMedium` (done by `SectionCard`) |
| Body text | `bodyLarge` (default), `bodyMedium` in dense places |
| Notes, timestamps | `bodySmall` with `onSurfaceVariant` |

### Spacing and sizes — `Dimens`

| Token | Value | Use |
| --- | ---: | --- |
| `gapSmall` | 8 | heading → text, icon → label |
| `gapCard` | 12 | between cards; padding of banners |
| `gap` | 16 | default gap; page and card padding |
| `gapLarge` | 32 | between sections |
| `tapTarget` | 48 | minimum size of anything tappable |
| `radiusCard` | 16 | cards |
| `radiusBanner` | 12 | banners, small containers |
| `maxFormWidth` | 480 | forms on tablets and in landscape |

Add a token when a value is used for the same purpose in two places; name
it by purpose, not by size.

## Components

| Component | Use it for | Example in |
| --- | --- | --- |
| [`CommandButton`](#commandbutton) | Every button that starts a `Command` | Connect, Home |
| [`MessageBanner`](#messagebanner) | Errors, warnings and notes inside a screen | Connect (error), Home (setup, error) |
| [`SectionCard`](#sectioncard) | A titled card: dashboard widgets, grouped content | Home |
| [`FormPage`](#formpage) | Centred, scrollable single-column pages | Connect, Home |
| [`Wordmark`](#wordmark) | The name "Waylight" | Connect, app bar |
| [`ViewModelHost`](#viewmodelhost) | Creating and disposing a screen's view model in a route | Router |

Planned with their issues (from the mockups): `StatusDot` and `FreshnessLabel`
(#17, #19), `TabScaffold` for the dashboard (#16), `SettingsSection`
(#14), `CaptureSheet` (#21). Build them when the issue starts, not before.

### CommandButton

Runs a `Command` and shows its progress: disabled and with a spinner while
running, so no double submit and no loading flag in the screen.

```dart
CommandButton(
  command: viewModel.connect,
  onPressed: () => viewModel.connect.execute(_address.text).ignore(),
  label: l10n.connectButton,
  variant: CommandButtonVariant.filled, // outlined, text
)
```

At most one `filled` button per screen. Buttons that do not start a command
(navigation, cancel) are plain `TextButton`s / `OutlinedButton`s.

### MessageBanner

An icon and a sentence on a tinted background; `kind` decides colours and
icon (`error`, `warning`, `info`). Errors are announced by screen readers.
An optional `action` slot takes a button.

```dart
MessageBanner(
  kind: MessageKind.warning,
  message: l10n.homeSetupRequired,
)
```

Use it for failures of an action (below the button), for states of a
screen (offline) and for information (why a search source cannot answer).
Input errors belong to the field (`InputDecoration.errorText`), not into a
banner.

### SectionCard

A filled card with a title row, an optional trailing status and the
content. The frame of every dashboard widget.

```dart
SectionCard(
  title: l10n.todosTitle,
  trailing: l10n.todosOpen(count),
  child: TodoList(…),
)
```

### FormPage

A `SafeArea` with a scrollable, centred column limited to
`Dimens.maxFormWidth`. For sign-in-like screens and simple pages.

### Wordmark

"Waylight" in the wordmark font (Fraunces, bundled with #10; until then the
platform serif). `large: true` on start screens, default size in app bars.

### ViewModelHost

Not visible, but used by every route: creates the view model once when the
screen appears and disposes it with the screen, however often the router
rebuilds.

```dart
GoRoute(
  path: Routes.home,
  builder: (context, state) => ViewModelHost(
    create: (context) => SignInViewModel(
      serverRepository: context.read(),
      sessionRepository: context.read(),
    ),
    builder: (context, viewModel) => SignInScreen(viewModel: viewModel),
  ),
)
```

## Adding a component

1. Check the rules in the [code conventions](code-conventions.md#5-reusable-components)
   (rule of three, small API, slots, enums, theme-driven, no domain imports).
2. Write it in `lib/ui/core/widgets/<name>.dart` with a doc comment and an
   example.
3. Test it in `test/ui/core/<name>_test.dart`: every variant, the
   interaction, and `meetsGuideline` for contrast and tap targets in light
   and dark (`pumpScreen(…, brightness: Brightness.dark)`).
4. Add it to the table above, and replace the hand-built versions in
   existing screens in the same pull request.
