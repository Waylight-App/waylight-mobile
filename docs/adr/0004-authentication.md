# ADR 0004: Sign-in of the app

- Status: Accepted (2026-11-18)
- Date: 2026-11-18

## Context

The server knows three ways to authenticate (`api/openapi.base.yaml`):

- **Session cookie** (`waylight_session`) from `POST /api/auth/login` with
  password and, if enabled, a TOTP code; state-changing requests also send
  the session's CSRF token in `X-CSRF-Token`. Sessions are visible and
  revocable, count towards lockouts and appear in the security log.
- **Personal API tokens** (`th_…`) with module scopes, created in the web
  settings and pasted into automations. They cannot reach `/api/auth/*`.
- **Kiosk links** for wall displays, read-only.

A phone app needs a sign-in that a user can do on the phone, that survives
app restarts, can be revoked per device, works with two-factor
authentication, and stores nothing but a revocable credential.

## Decision

1. **Phase 1:** the app uses the existing session endpoints. It signs in
   with password and TOTP code, keeps the session cookie and the CSRF token
   in the secure storage, sends them with every request, and treats a 401 as
   "signed out". No server change is needed.
2. **Phase 2:** the server gets dedicated **app sessions** (issue in the
   server repository): a long-lived, revocable token per device, created by
   signing in or by scanning a QR code in the web settings, listed with the
   device name under the sessions of the account. The app switches to it
   once released; phase 1 stays as fallback for older servers.
3. Passkeys and single sign-on in the app follow after phase 2.

## Status of the phases

- Phase 1 is in place since #12 and #13.
- Phase 2 (#15): the server offers app sessions since Waylight-App/waylight#559
  (server ADR 0024). The app first asks for one
  (`POST /api/auth/app-sessions` with a device name) and keeps its bearer
  token; a server that answers 404 gets the browser session of phase 1.
  Both kinds are stored with their kind, so sessions from before phase 2
  keep working.
- Passkeys, Microsoft and single sign-on (#45): on servers with app
  sessions the app opens `/app-sign-in` in the browser with an S256 PKCE
  challenge and a random state, both kept in the secure storage. The server
  sends a single-use code to `waylight://auth`; the app accepts it only with
  the state it started with and redeems it with the verifier (server
  Waylight-App/waylight#560).

## Consequences

- The app can be used with every current server from day one.
- Session lifetime is that of browser sessions until phase 2; the app has to
  handle expiry gracefully.
- Personal API tokens stay for automations; the app does not ask users to
  paste them, because they cannot reach the account endpoints and are
  created per module.

## Alternatives considered

- **API tokens pasted into the app:** no sign-in UI needed, but bad UX, no
  account endpoints, and tokens with broad scopes on a phone.
- **OAuth 2.0 device flow / PKCE against the server:** the cleanest
  long-term option, but a large server change; phase 2 can grow into it.
