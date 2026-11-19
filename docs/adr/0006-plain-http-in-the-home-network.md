# ADR 0006: Plain HTTP only in the home network

- Status: Accepted (2026-11-19)
- Date: 2026-11-19
- Issue: [#9](https://github.com/Waylight-App/waylight-mobile/issues/9)

## Context

Waylight usually runs in a home network, often at an address such as
`http://192.168.178.115:8090` without TLS. Android (since API 28) and iOS
block plain HTTP unless the app allows it. The password and the session
cookie travel with every request, so plain HTTP over the internet would
expose them.

## Decision

1. **`http://` only for private addresses.** `ServerAddress.parse` accepts
   plain HTTP for loopback, RFC 1918 and link-local IPv4 addresses, IPv6
   unique local and link-local addresses, `localhost`, `.local` and
   `.home.arpa` names. Every other address needs `https://`; the connect
   screen says so. Addresses without a scheme still become `https://`, and
   the warning below the field stays.
2. **Android:** `network_security_config.xml` permits cleartext for the
   whole app, because the platform cannot express IP ranges; the rule of
   point 1 is what limits it. Only system certificate authorities are
   trusted.
3. **iOS:** `NSAllowsLocalNetworking` in `Info.plist`, which allows plain
   HTTP to local IP addresses and `.local` names. iOS does not count
   `.home.arpa` as local; such servers need HTTPS on iOS.
4. **Self-signed certificates** are not supported. A server with HTTPS needs
   a certificate the phone trusts, for example through its reverse proxy.

## Consequences

- Most home setups work out of the box on the local network.
- Reaching the server from outside needs HTTPS (reverse proxy) or a VPN into
  the home network, where the private address works again.
- Names a router hands out without `.local` (such as `server.fritz.box`)
  need the IP address or HTTPS.
