# ADR 0009: Home screen widgets draw cards the app formats

- Status: Accepted
- Date: 2026-11-20

## Context

Home screen widgets (#42) have to show data while the app is closed, and
the data has to be refreshed in the background (#48). Android draws them
with `RemoteViews` in the launcher's process; iOS uses WidgetKit in an
extension. Neither can run Flutter code while drawing. The data comes from
the Waylight server with the user's session, which only the app's
repositories know how to use.

## Decision

1. **The app formats, the widget draws.** After each refresh the app writes
   one *card* per widget: title, lines, an empty text, the age
   ("Updated 10:42") and the app link to open, already in the app's
   language. Times are absolute, so a card stays right while it is shown
   unchanged. The native code lays out text and opens the link; it holds
   no logic and no translations besides "open the app once".
2. **Cards hold display text only.** No session, token or server address
   is stored for the widgets. Signing out deletes the cards.
3. **Storage.** Android keeps the cards as JSON in a private
   `SharedPreferences` file (`home_widgets`), written through the method
   channel `app.waylight/home`. iOS will use an App Group with the same
   JSON when its widgets follow.
4. **Background refresh through the app's own code.** Android's WorkManager
   runs a periodic job (30 minutes, only with network and enough battery).
   It starts a headless Flutter engine with the entry point
   `backgroundRefresh` in `lib/main.dart`, which restores the server and the
   session and refreshes the cards through the same repositories as the
   app. An expired session or a signed-out app clears the cards and cancels
   the job. The job waits for `done` for at most a minute.
5. **Plain `RemoteViews`, no Glance.** Glance pulls in Jetpack Compose for
   two text cards; `RemoteViews` needs no extra library.
6. **No Flutter plugin for widgets or scheduling.** `home_widget` and
   `workmanager` would wrap about the same amount of native code that we now
   own. The only new native dependency is `androidx.work:work-runtime`
   (Apache 2.0), part of the one Android build (ADR 0011).

## Consequences

- New widgets need a card in `HomeWidgetsRepository`, its texts in
  `HomeWidgetTexts`, a receiver in the manifest and a provider class.
- The background job starts Flutter, which takes a few seconds of CPU every
  30 minutes; the platform defers it in Doze and with low battery.
- iOS widgets and `BGAppRefreshTask` remain open (#42, #48).
