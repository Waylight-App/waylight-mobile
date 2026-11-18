# ADR 0003: Dependency policy

- Status: Accepted
- Date: 2026-11-18

## Context

Waylight is lean by default (server ADR 0011): every dependency adds size,
transitive packages, maintenance and supply-chain risk. An app is
additionally reviewed by stores and installed on phones with limited space.

## Decision

1. A new runtime dependency (`dependencies` in `pubspec.yaml`) needs a
   justification in the pull request: what it costs (size, transitive
   dependencies, platform code, maintenance and security track record) and
   why the SDK or a few lines of own code are not enough. The reason is
   added as a comment next to the dependency in `pubspec.yaml`.
2. Prefer packages published by the Dart and Flutter teams
   (`dart.dev`, `flutter.dev`, `tools.dart.dev` publishers).
3. No package that sends data anywhere by itself (analytics, crash
   reporting, ads), and none with proprietary binaries, so that the app can
   be published on F-Droid.
4. Dev dependencies need a reason too, but the bar is lower.
5. Dependabot keeps versions current; the *Dependency review* check blocks
   new dependencies with known vulnerabilities.

## Consequences

- Fewer packages to update and audit; each one is explained in
  `pubspec.yaml`.
- Some conveniences are written by hand (commands, `Result`, model parsing).
