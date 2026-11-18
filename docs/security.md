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
type `http://`. Android and iOS block plain HTTP by default; whether and how
the app allows it for local addresses is decided in
[#9](https://github.com/Waylight-App/waylight-mobile/issues/9).

## Sign-in

How the app signs in is decided in
[ADR 0004](adr/0004-authentication.md) (proposed).
