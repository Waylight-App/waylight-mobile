# Waylight on Wear OS

The watch app shows a few glances from your Waylight server on the wrist:
the next calendar event, how many to-dos are open, your presence status and
the short states of modules such as habits and the focus timer. A tile shows
the same at a swipe from the watch face. This page covers installing and
pairing the app and how it is built.

The app talks to your server directly, over the watch's Wi-Fi, LTE or the
connection it shares with the phone. It does not need the phone app to be
open and uses no Google Play services. The reasons are in
[ADR 0015](adr/0015-standalone-wear-os-app.md).

## Requirements

- A watch with Wear OS 3 or newer.
- A Waylight server with app sessions (server #559) that the watch can
  reach. A server only reachable in the home network works while the watch
  or the phone it is connected to is in that network.
- For pairing through the phone: the Waylight phone app and both devices in
  the same Wi-Fi.

## Install

Download `waylight-wear-vX.Y.Z.apk` from the latest
[release](https://github.com/Waylight-App/waylight-mobile/releases) and
install it with `adb`:

1. On the watch, turn on *Developer options* (tap *Build number* seven times
   under *Settings → System → About*), then *ADB debugging* and *Debug over
   Wi-Fi*.
2. Note the address the watch shows, for example `192.168.178.42:5555`.
3. On your computer:

   ```sh
   adb connect 192.168.178.42:5555
   adb -s 192.168.178.42:5555 install waylight-wear-v1.2.0.apk
   ```

4. Turn *ADB debugging* off again.

Until release signing exists
([#25](https://github.com/Waylight-App/waylight-mobile/issues/25)) the APK is
signed with a temporary key, so an update may need an uninstall first.

## Pair the watch

Open Waylight on the watch and choose one of the two ways.

**Pair with phone.** The watch turns on Wi-Fi and shows a QR code. The
phone app scans it and sends the server address and a fresh pairing code to
the watch, encrypted with a key that only the QR code carries. In the
phone app, open *Settings → This phone → Pair a watch*, tap *Scan the
watch's code*, check the address it found and tap *Pair this watch*. The
phone sends the server address shown under *Settings → Server &
connection*; a watch that should also work outside the home network needs
an address it can reach from there.

**Enter code.** Type the server address and a pairing code. An address in
the home network without a scheme, such as `192.168.178.115:8090`, is taken
as plain HTTP; every other address needs HTTPS. The web interface shows
pairing codes under *Settings → Apps* only as a QR code so far
([waylight#605](https://github.com/Waylight-App/waylight/issues/605)); the
code is the `code` parameter of the link in that QR code, which any QR
reader on the phone shows.

Either way the watch gets its own app session. It shows up with the watch's
name under *Settings → Apps* on the server, where you can revoke it. *Sign
out* on the watch ends the session and deletes it from the watch.

## Glances and the tile

The app's main screen lists the next event, the compact states, your status
and when the data was fetched. Long-press the watch face or swipe to the
tiles, tap *Add tile* and choose *Waylight* to get the tile. It shows the
stored data with its age and asks for fresh data when the last fetch is
more than a quarter of an hour old. A tap on the to-do row ticks it off,
a tap anywhere else opens the app.

Two complications put the data on the watch face: *Waylight: next event*
(short: time and the start of the title; long: title and time) and
*Waylight: open to-dos* (the number). Long-press the watch face, choose
*Edit* and pick them for a slot. They show the stored data and change
after every refresh; a tap opens the app.

The server sends the texts of compact states in English together with the
key of their template. The watch shows them in its own language (English
or German) when it knows the key; texts of modules added on a newer
server stay in English until the watch app knows them. The keys live in
`glances/ServerTexts.kt`, the templates in the string resources.

In the background the watch fetches new data every 30 minutes while it has
a network. If the server says the session has ended, the watch forgets it
and asks to be paired again.

## Actions on the wrist

The watch can change a few things itself, with its own app session:

- **Tick off a to-do.** The app and the tile show the first open to-do;
  tap it to mark it done. On the tile the request runs in the background
  and waits for a network if there is none.
- **Set my status.** Tap *My status* in the app and pick office, home,
  away or *Not set* for today.
- **Compact actions.** When a module's compact state offers an action
  (start a focus session, choose one of several options), the app shows
  it as a chip under the state.
- **Smart home.** Entities the server allows to switch
  (`SMARTHOME_ACTIONS_ENTITIES`) are listed under *Smart home*, at most
  six; a tap toggles or presses them.

After every action the watch fetches the glances again, so the screen and
the tile show the new state.

## Build it

The watch app is a Gradle build of its own in `wear/`; it needs JDK 17 and
the Android SDK, not Flutter.

```sh
cd wear
./gradlew assembleDebug testDebugUnitTest
adb install build/outputs/apk/debug/waylight-wear-debug.apk
```

Android Studio opens `wear/` as a project. The Wear OS emulator (system
image *Wear OS 4* or newer) runs the app; pairing by code works there
against a server on the host (`http://10.0.2.2:8090`).

The code is Kotlin with Compose for Wear OS, the Wear Tiles, ProtoLayout and
watch face complication libraries and WorkManager from AndroidX, and the
ZXing core for the QR code.
Nothing from Google Play services or Firebase may be added; CI checks the
APK for it. The version comes from `pubspec.yaml`.

| Folder | What is in it |
| --- | --- |
| `data/` | server address rules, the HTTP client, the session and its Keystore storage |
| `pairing/` | the handover key, the small HTTP listener for the phone, Wi-Fi and the QR code |
| `glances/` | fetching, parsing and storing the snapshot, background refresh, texts |
| `tile/` | the tile |
| `complications/` | the watch face complications |
| `ui/` | the screens and their view model |
