# ADR 0012: Dashboard grid with widget sizes

- Status: Accepted
- Date: 2026-11-20

## Context

On phones the dashboard showed every widget at the full width and its
natural height. A tab with a dozen widgets was several screens long, and
the clock or the weather took as much width as a to-do list. Phone home
screens solve this with widgets of a few fixed sizes on a grid. The server
stores a phone layout per tab — order, hidden on phones, a minimum height
(`rows`) — but no width.

## Decision

1. **Four sizes on a grid of square cells**, like a phone's home screen:
   small 2 × 2, medium 4 × 2, large 4 × 4, strip 4 × 1. The grid is 4 cells
   wide on phones and 8 on tablets; the sizes keep their cells, so a tablet
   shows two medium widgets side by side.
2. **Dense packing in display order** (`packGrid` in the domain): each
   widget takes the first place where it fits, so a later small widget
   fills the gap next to an earlier one. Pure and tested.
3. **No size means today's look**: full width at the natural height. Tabs
   nobody resized look exactly as before; runs of sized and unsized widgets
   alternate in the order of the phone layout.
4. **Fixed boxes, full view on tap.** A tile shows the widget's view in a
   box of its size; content that does not fit fades out, and tapping the
   tile opens the widget in full. Views read their size from
   `WidgetSizeScope` and get compact forms one by one (#211).
5. **Sizes live in the server's phone layout** (Waylight-App/waylight#585),
   so every device and the phone view of the web interface share them. The
   server rejects unknown fields, so the app sends `size` only after an
   answer contained it; until then the dashboard repository keeps sizes on
   the device, per server, tab and widget, and lays them over the server's
   answer.

## Consequences

- Much less scrolling once widgets have sizes; the default changes nothing
  for existing users.
- Until a widget kind has a compact view, a small tile shows the top of
  its normal view, faded out. #211 works through the kinds.
- Sizes chosen before the server knows them stay on that device; once the
  server has the field, the next save stores them there.
- The edit mode on the dashboard (#209) and adding widgets (#210) build on
  this; for now the size is chosen in the tab's edit screen.

## Alternatives considered

- **Free sizes (any width and height):** more flexible, but hard to arrange
  on a phone and to keep consistent across screen widths.
- **Sizes only on the device:** no server change, but every phone would
  have its own layout and the phone view of the web interface would stay a
  single column.
- **A grid package** (e.g. a staggered or reorderable grid): the layout is
  a few lines on top of `Stack` and `Positioned`; dragging comes with #209
  and is decided there (ADR 0003).
