# Architecture Decision Records

Each record documents one significant decision of the app: its context, the
decision and its consequences. Records are immutable; a changed decision
gets a new record that supersedes the old one. Decisions of the server are
in the [server repository](https://github.com/Waylight-App/waylight/tree/main/docs/adr).

Copy [`template.md`](template.md) to `NNNN-short-title.md`, start with
status *Proposed*, and discuss it in the pull request.

| No. | Title | Status |
| --- | --- | --- |
| [0001](0001-app-architecture.md) | App architecture: the Flutter architecture guide (MVVM, repositories, services) with enforced layers | Accepted |
| [0002](0002-flutter-stack.md) | Flutter stack: material_ui, provider, ChangeNotifier with commands, go_router, http, gen-l10n | Accepted |
| [0003](0003-dependency-policy.md) | Dependency policy: every runtime dependency needs a reason | Accepted |
| [0004](0004-authentication.md) | Sign-in of the app: session endpoints first, app sessions from the server later | Accepted |
| [0005](0005-design-system.md) | Design system in code: theme tokens and shared components | Accepted |
| [0006](0006-plain-http-in-the-home-network.md) | Plain HTTP only for addresses in the home network | Accepted |
| [0007](0007-offline-copy.md) | Offline copy of the dashboard: files in the private directory, limited, deleted on sign-out | Accepted |
| [0008](0008-push-notifications.md) | Push notifications in native code; Firebase only in the store flavour | Accepted |
| [0009](0009-home-screen-widgets.md) | Home screen widgets draw cards the app formats; refresh through WorkManager and a headless engine | Accepted |
| [0010](0010-distribution-without-store-accounts.md) | Distribution without store accounts for now: Android through GitHub Releases, iOS as web app with Web Push | Accepted |
