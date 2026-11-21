# ADR 0013: Markdown rendering

- Status: Accepted
- Date: 2026-11-21

## Context

Announcements (#202) are written in Markdown, and notes and read-later
articles will be shown the same way. Text from the server is input written
by other people: rendering it must not load anything from other hosts or
run anything, and links must open in the browser, never inside the app.

## Decision

Markdown is parsed with the `markdown` package of the Dart team and turned
into widgets by a small renderer of our own, `MarkdownView` in `ui/core`.
It supports what the server's web interface shows: paragraphs, headings,
lists, emphasis, inline code and code blocks, block quotes, horizontal
rules and links. Links open through `LinkOpener` in the system browser, and
only for `http`, `https` and `mailto`. Images are never loaded; their
alternative text is shown instead. Raw HTML in the source is shown as text.

## Consequences

One small, well-maintained dependency without native code. The renderer is
ours to keep: tables and other extensions show as plain text until someone
needs them. Every place that shows Markdown looks the same and follows the
app's theme.

## Alternatives considered

- `flutter_markdown_plus`: a complete renderer, but a larger dependency
  with its own release rhythm for the few elements the app needs.
- Plain text only: no dependency, but announcements lose their links and
  lists.
