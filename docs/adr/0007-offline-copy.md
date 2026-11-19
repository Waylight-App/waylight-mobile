# ADR 0007: Offline copy of the dashboard

- Status: Accepted (2026-11-19)
- Date: 2026-11-19
- Issue: [#23](https://github.com/Waylight-App/waylight-mobile/issues/23)

## Context

Phones lose the connection to a home server often: on the way, in the
basement, when the VPN is off. The dashboard should still open with the
last data it showed, like the web app does in the browser.

## Decision

1. **What is kept.** The API client keeps the last successful answer of
   the read endpoints of the dashboard and the native widgets
   (`ApiClient.cachedPaths`). Sign-in, account and settings endpoints,
   exports, backups and logs are never kept.
2. **Where.** One file per address in the app's private directory
   (`getApplicationSupportDirectory()/offline`), named by a hash of the
   address. Files instead of a database: the answers are read whole, by
   address, and there are only a few of them.
3. **Encryption at rest.** The files rely on the platform: app-private
   storage with file-based encryption on Android and Data Protection on
   iOS. They contain what the dashboard shows, never credentials; the
   session stays in the secure storage.
4. **Limits.** At most 5 MB; the oldest files go first. Answers older than
   seven days are not shown.
5. **When it is used.** Only when the server cannot be reached. The
   dashboard then says *Offline · showing the data from 07:58* with the time
   of the oldest data on screen; the first request that reaches the server
   clears the note.
6. **Deletion.** Signing out, an expired session and *Use another server*
   delete all files.

## Consequences

- The app opens offline with the last dashboard and widget data.
- Changes made offline are not queued; that follows in #24.
