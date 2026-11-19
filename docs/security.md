# Security and privacy

The app inherits the principles of Waylight: private by default, least
privilege, no telemetry. This page says what that means for the app. To
report a vulnerability, see [SECURITY.md](../SECURITY.md).

## Principles

1. **Only your server.** The app sends requests to the server address you
   entered and nowhere else: no analytics, no crash reporting, no fonts or
   images from third parties, no update checks.
2. **Secrets in the platform's secure storage.** Sessions and tokens are
   stored in the iOS Keychain and the Android Keystore
   (`SecureKeyValueStore`), never in shared preferences, files or logs.
3. **Nothing sensitive in logs.** Loggers write paths and status codes,
   never bodies, cookies, tokens, passwords or full URLs with query
   parameters. Release builds log warnings and worse only.
4. **Least permissions.** The app asks only for `INTERNET` on Android.
   Every further permission (notifications, camera for QR codes) needs an
   issue that explains why, and is requested when the feature is first
   used, not at start.
5. **Same rules as the server.** The server's network allow-list
   (`ALLOWED_CIDRS`), lockouts, two-factor authentication and security log
   apply to the app exactly as to the browser. The app never weakens them.

## Transport security

Waylight usually runs in a home network, often on plain
`http://192.168.x.x:8090`. HTTPS is the default in the app: an address
without scheme becomes `https://`, and the connect screen warns when you
type `http://`. Plain HTTP is only accepted for addresses in a private
network (`192.168.x.x`, `10.x.x.x`, `172.16–31.x.x`, `localhost`, `.local`,
`.home.arpa`, IPv6 ULA and link-local); every other address needs HTTPS
([ADR 0006](adr/0006-plain-http-in-the-home-network.md)). Self-signed
certificates are not trusted.

## Sign-in

How the app signs in is decided in [ADR 0004](adr/0004-authentication.md).
The app asks the server for an **app session** (phase 2): a bearer token
for this device, listed with the device name in the session list of the
web interface and revoked there. Servers without app sessions get the
session of a browser (phase 1). For both:

- **What is kept.** After the sign-in the app keeps the bearer token, or the
  session cookie and its CSRF token, together with the server address they
  belong to, in the
  secure storage (Keychain on iOS, Keystore on Android) and nowhere else.
  The password and the second-factor code are never stored or logged; the
  sign-in screen clears them after a failed attempt. `Session.toString()`
  leaves the secrets out, so they cannot end up in a log by accident.
- **Where it is sent.** `ApiCredentials` adds the bearer token, or the
  cookie and on POST, PUT, PATCH and DELETE the CSRF token, only to requests
  under the address of the session's own server. Connecting another server cannot
  leak the session to it.
- **When it ends.** A 401 from any request that carried the session ends it
  on the device, and the sign-in screen says that the session has ended.
  *Sign out* asks the server to end the session and forgets it on the device
  even when the server cannot be reached; it can then be ended in the
  session list of the web interface. *Use another server* signs out first.
- **Second factor and single sign-on.** Accounts with an authenticator app
  enter its code or a recovery code. Passkeys, Microsoft and single sign-on
  work through *Sign in in the browser*: the server hands the sign-in back
  to the app with a code that only redeems with the app's PKCE verifier,
  and the app ignores answers to sign-ins it did not start.
