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
   parameters. Release builds log warnings and worse only. The last
   records are kept in a file of at most 300 lines for the diagnostic
   report (#197); addresses, IP and e-mail addresses, credentials and long
   tokens are redacted before a record is written (`utils/redact.dart`).
   Signing out deletes the file, and the report leaves the phone only
   through the system share sheet.
4. **Least permissions.** At install the app gets `INTERNET` and
   `ACCESS_NETWORK_STATE` on Android; the latter only tells it that the
   network changed, to pick the server address that answers (#189). It
   never reads the Wi-Fi name, which would need the location permission.
   Every further permission (notifications, camera for QR codes) needs an
   issue that explains why, and is requested when the feature is first
   used, not at start.
   Reminders on the device (#190) use inexact alarms
   (`setAndAllowWhileIdle`), so they need no exact-alarm permission; the
   notification permission is asked when the first kind is turned on. The
   planned reminders (title, text, time) are kept in the app's private
   storage so they survive a reboot, and are deleted on sign-out.
   The focus timer (#191) ends a phase with an exact alarm: a timer must
   end on time, and `USE_EXACT_ALARM` is granted to timers from Android 13
   (`SCHEDULE_EXACT_ALARM` up to Android 12). Where the system refuses
   exact alarms the timer falls back to an inexact one.
   The camera permission is asked when *Scan* is first used (#196,
   ADR 0014); ZXing reads the code on the phone and only its text reaches
   the app. No picture is stored or sent.
5. **Wall displays.** A kiosk link (#193) signs the tablet in as the
   server's read-only kiosk account; the token is read from the link's
   fragment and sent only in the sign-in request. Leaving the wall display
   needs the device credential. A link disabled or renewed on the server
   ends the session; the tablet then forgets the server.
6. **Same rules as the server.** The server's network allow-list
   (`ALLOWED_CIDRS`), lockouts, two-factor authentication and security log
   apply to the app exactly as to the browser. The app never weakens them.

## App lock

The optional app lock (*Settings → App lock*, #46) asks for the phone's
fingerprint, face or device PIN when the app starts and when it returns
after the chosen time in the background (at once, 1, 5 or 15 minutes). It
uses the platform's local authentication; nothing about it is sent to the
server, and turning it on needs one confirmation.

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
- **Several servers.** Each server keeps its own session
  (`session@<address>` in the secure storage, #51); switching servers uses
  the session stored for it, removing a server deletes it.
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

## Wear OS app

The watch app ([ADR 0015](adr/0015-standalone-wear-os-app.md)) follows the
same principles and talks only to your server.

- **Own session.** The watch has its own app session with its own name on
  the server, revoked there or with *Sign out* on the watch. Its bearer
  token is encrypted with an AES-256-GCM key that the Android Keystore of
  the watch creates and never hands out; the app's private preferences hold
  only the ciphertext. Backups are off. A 401 from the server deletes the
  session on the watch.
- **Pairing through the phone.** The QR code on the watch carries its
  address in the Wi-Fi and a random 256-bit key. The phone sends the server
  address and a pairing code to that address, encrypted and authenticated
  with AES-256-GCM under the key. Someone else in the network sees only the
  ciphertext and cannot forge a handover without the key, which travels
  only through the camera. The watch listens only while the QR code is
  shown, stops after the first successful handover or ten requests, and
  accepts bodies of at most 4 KB. Pairing codes are single-use and expire
  after five minutes on the server.
- **Permissions.** `INTERNET`, `ACCESS_NETWORK_STATE` and
  `CHANGE_NETWORK_STATE`; the last one asks for Wi-Fi while the QR code is
  shown, because a watch near its phone usually stays on Bluetooth. No
  location, camera or body sensors.
- **What is stored.** Besides the session, the last snapshot of the glances
  (next event title and time, compact state texts, your status) stays in the
  app's private preferences so the tile can draw without a request. Sign-out
  deletes it.
- **Transport.** The rules of ADR 0006 apply, with one convenience: an
  address in the home network typed without a scheme is taken as
  `http://`. Redirects are not followed, so the token cannot be sent to
  another host.
- **No Google services.** No Wearable Data Layer and nothing from Google
  Play services or Firebase; CI checks the watch APK for it. The server and
  your network see the watch's IP address and when it fetches data, every
  30 minutes while it has a network.
