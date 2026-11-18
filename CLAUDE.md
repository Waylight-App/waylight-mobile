# Notes for AI assistants

Read these before changing code; they are the source of truth:

- `docs/architecture.md` — layers and rules (enforced by `test/architecture_test.dart`)
- `docs/adding-a-feature.md` — how a new screen is built, step by step
- `docs/code-conventions.md` — principles, names, Dart style, widgets, errors, logging
- `docs/ui-components.md` — design tokens and the reusable components; use them
- `docs/design/README.md` — mockups of every screen
- `docs/workflow.md` — issue first, Conventional Commits, pull requests

Essentials:

- Copy the structure of the connect screen (`lib/ui/connect_server/`,
  `lib/data/repositories/server/`, `lib/data/services/api/platform_api.dart`)
  for new features.
- Import `package:material_ui/material_ui.dart`, never `package:flutter/material.dart`.
- Services and repositories return `Result`; view model actions are `Command`s.
- Routes host view models in `ViewModelHost`; screens get them via the constructor.
- Build screens from `lib/ui/core/widgets` (`CommandButton`, `MessageBanner`,
  `SectionCard` …); no colour values or font sizes outside `ui/core/themes`.
- Error texts: own errors first, everything else `l10n.errorMessage(error)`.
- Every text goes into `lib/l10n/app_en.arb` and `app_de.arb`; then `make gen`.
- Run `make ci` before committing; it must pass unchanged.
- No new runtime dependency without a reason (docs/adr/0003-dependency-policy.md).
