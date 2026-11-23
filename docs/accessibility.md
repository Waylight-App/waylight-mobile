# Accessibility

The web interface aims for WCAG 2.2 AA; the app aims for the same
([#28](https://github.com/Waylight-App/waylight-mobile/issues/28)). This page
says what is checked automatically, what only a person with a screen reader
can check, and how to do it. No manual audit has been recorded yet; findings
are filed with the *Accessibility finding* issue form and listed in #28.

## Checked automatically

`make ci` runs these on every pull request ([Testing](testing.md)):

| Check | Where |
| --- | --- |
| Tap targets of at least 48 dp (Android) and 44 pt (iOS) | `androidTapTargetGuideline`, `iOSTapTargetGuideline` in the screen tests |
| Every tappable element has a label | `labeledTapTargetGuideline` |
| Text contrast of at least 4.5:1, light and dark | `textContrastGuideline` |
| Text size of the account (*Accessibility* settings) is applied on top of the system's | `test/ui/core/app_accessibility_test.dart`, `text_scaling_test.dart` |
| Texts in German and English | the screen tests, `make check-generated` |

What the guidelines cannot judge: reading order, where focus goes after an
action, what is announced, whether a label makes sense, whether content is
cut off at large text, and animation. Those are checked by hand.

## Checked by hand

Use a release build or the latest release APK on a device, signed in to a
server with data in every widget (the public demo
`https://demo.getwaylight.app` works). Record the app version, device and
Android version with every finding. Test in English and in German.

### TalkBack (Android)

Turn it on in *Settings → Accessibility → TalkBack*. Swipe right and left
to move, double-tap to activate, two-finger swipe to scroll.

For every screen of the flow checklist below:

1. Swiping through the screen visits every control once, in a sensible
   order, and nothing visible is skipped.
2. Each control is announced with a meaningful name, its role and state
   (selected, checked, disabled), not an icon name or *button* alone.
3. Decorative images are skipped; informative ones have a description.
4. After an action (save, delete, error, sheet opened or closed) focus
   lands somewhere logical and the result is announced.
5. Errors and banners are announced without moving focus away from the
   field being edited.
6. Dialogs and sheets keep focus inside until closed; Back closes them.
7. Gestures with an alternative: everything done by long press or drag has
   a TalkBack action or a button.

### VoiceOver (iOS)

iOS is paused; the same steps apply to a local iOS build once it is
brought back. Turn VoiceOver on in *Settings → Accessibility*.

### Large text and display zoom

1. Set the system font size to the largest value (about 200 % with the
   *Display size and text* settings on Android) and also try the app's own
   text size under *Settings → Accessibility*.
2. Open every screen of the checklist: no text is cut off or overlaps,
   nothing needs horizontal scrolling, every action stays reachable.
3. Repeat with the display size at its largest and in landscape.

### Reduced motion

Turn on *Remove animations* (Android: *Settings → Accessibility → Colour
and motion*). The app reads `MediaQuery.disableAnimationsOf`; the arrange
view and the dashboard grid already follow it. Open every screen and check
that no transition, shimmer or moving element remains.

### Other

- Contrast in light and dark and with the account's *High contrast* option.
- Focus order with an external keyboard (Tab, arrows, Enter).

## Flow checklist

Mark each flow for TalkBack, large text and reduced motion.

| # | Flow | Route |
| --- | --- | --- |
| 1 | Connect: enter the server address, see the plain-HTTP warning | `/connect` |
| 2 | Sign in with password; with a two-factor code; error state | `/sign-in` |
| 3 | Sign in by QR code or in the browser | `/sign-in`, `/auth` |
| 4 | First start (welcome) | `/welcome` |
| 5 | Dashboard: switch tabs, open a widget, pull to refresh | `/` |
| 6 | Arrange the dashboard | `/` (arrange view) |
| 7 | Needs your attention | `/attention` |
| 8 | Search and an answer | `/search` |
| 9 | To-dos: add, tick off, delete | dashboard widget |
| 10 | Notes: open, edit | `/note` |
| 11 | Quick capture and the share sheet | `/share`, `/paste` |
| 12 | Calendar, shopping list, feeds, timeline, smart home | their routes |
| 13 | Settings: every area, status lines, switches | `/settings` |
| 14 | App lock prompt | `/locked` |
| 15 | Pair a watch | `/settings/watch` |
| 16 | NFC tag sheet and tag action | `/tag` |
| 17 | Wall display (kiosk) | `/kiosk` |
| 18 | Home screen widgets and Quick Settings tiles | system UI |
| 19 | Notifications: reminder and push message, notification actions | system UI |

## Findings

File each finding with the
[Accessibility finding](https://github.com/Waylight-App/waylight-mobile/issues/new?template=4-accessibility_finding.yml)
form, one issue per problem. Findings are fixed before 1.0 and get a test
where a guideline or a widget test can cover them.
