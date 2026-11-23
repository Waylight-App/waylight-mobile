# Privacy policy

This page describes what the Waylight app (Android, Wear OS) does with
data. The same facts are listed for the store forms in
[Store listings](store-listing.md).

## Summary

- The app has no account with the project and no analytics, crash
  reporting, advertising or tracking.
- It sends requests to the server address you entered and, only while push
  notifications are on, to the push relay `push.getwaylight.app`.
- No Google services, no Firebase and no third-party libraries that
  contact a network are part of the app.

## Data on your server

Everything you see and create in the app (dashboard, to-dos, notes,
search, places, status) is stored by your own Waylight server. The app
sends it there with the session of your account. The project has no access
to that server or its data. The server's own policy and your network
decide who sees traffic between the app and the server.

## Data kept on the device

- The session (bearer token or cookie) and the server address, in the
  Android Keystore-backed secure storage; deleted on sign-out.
- An offline copy of the dashboard, planned reminders, the entity list of
  the device controls and the glances of the watch, in the app's private
  storage; deleted on sign-out.
- A log of at most 300 lines for the diagnostic report, with addresses,
  e-mail addresses, credentials and long tokens redacted. It leaves the
  phone only when you share the report.
- Settings such as the app lock; the lock uses the platform's local
  authentication and nothing about it is sent anywhere.

## Push relay

If you turn push notifications on, the app keeps a connection to
`https://push.getwaylight.app/v1/stream` and your server sends messages to
the relay for your device. The relay sees the device identifier (a hash of
a public key created in the Android Keystore), the IP address of the
connection and the time of requests. Message content is end-to-end
encrypted between your server and the app; the relay keeps up to 100
encrypted messages per device for 72 hours so that none gets lost while the
phone is offline. Without push, the app makes no request to the relay.

## Permissions

| Permission | Use |
| --- | --- |
| Internet, network state | Talk to your server; pick the address that answers |
| Notifications | Show reminders and push messages; asked when you turn them on |
| Foreground service, boot completed, battery optimisation request | Keep the push connection alive and restart it after a reboot |
| Exact alarms | End a focus timer on time |
| Biometrics | Optional app lock |
| Camera | Scan QR codes and barcodes on the phone; no picture is stored or sent |
| Approximate location | Only when you tap *Use my location*: read once, rounded to about 100 m and saved as a place on your server |
| NFC | Optional tags; reader mode only while the write sheet is open |

## Your choices

Sign out to delete the session and the local data. Sessions can also be
ended in the session list of the web interface of your server. Uninstalling
the app removes everything it stored on the device.

## Contact

Questions about this page: open an issue in
[Waylight-App/waylight-mobile](https://github.com/Waylight-App/waylight-mobile/issues).
Security problems: [SECURITY.md](../SECURITY.md).
