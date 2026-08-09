# OutlinerView Design

Design notes for agents working in this directory. These describe the current
design and may evolve; they are not binding contracts.

## Overview

`OutlinerView` is the editable outline of the app. A macOS-first view: it
bridges SwiftUI with an `NSTextView` so each row can be edited inline. A row is
a text item with a depth, an expand/collapse chevron, and a bullet. Rows are
currently stored as a flat array; depth is a per-row integer, so tree semantics
are expressed by the `depth` value rather than nested data structures.

## Architecture & data flow

State flows down from a single owner, while measured geometry and row-edit
events flow back up.

```
OutlinerView                     owns rows: [OutlinerRowModel]
  └─ ScrollView > LazyVStack
       └─ OutlinerRowView        renders one row (indent, chevron, bullet, text)
            └─ OutlinerTextViewRepresentable   NSViewRepresentable bridge
                 └─ OutlinerTextView           NSTextView subclass
```

- `OutlinerView` is the single owner of row state. Each `OutlinerRowView` binds
  to one row and derives its layout from the model.
- `OutlinerTextViewRepresentable` wraps the AppKit text view and mediates all
  communication with SwiftUI through its `Coordinator`. The coordinator
  refreshes its stored `parent` on every `updateNSView`; holding the struct
  captured at `makeCoordinator` would leave stale `@Binding`s pointing at a
  different row after the rows array shifts (e.g. deleting a row above).
- `OutlinerTextView` is an `NSTextView` subclass that invokes `onLayout` after
  each layout pass. The representable uses this callback to re-measure the
  content.
- Pressing Return (without Shift) in a row fires `onInsertNewline`, which the
  coordinator relays up to `OutlinerView.insertNewRow(in:textView:)`. That
  splits the row's text at the cursor and inserts a new row below it — a
  sibling, except when splitting the root row, where the new row is born as a
  child at depth 1 (`max(row.depth, 1)`). It sets `focusedRowId` to move focus
  to the new row.
- Pressing the backspace or forward-delete key with the cursor at position 0
  (no selection) fires `onDeleteRow`, which the coordinator relays up to
  `OutlinerView.deleteRow`. That removes the row, keeps the outline from ever
  becoming empty (`rows.count > 1`), promotes the row's descendants one level
  (they become siblings of its former siblings), and sets `focusedRowId` to the
  row above (the root row can never be removed).
- Pressing Tab fires `onIndentRow`, and pressing Shift+Tab fires
  `onOutdentRow`, which the coordinator relays up to
  `OutlinerView.indentRow`/`outdentRow`. Both change the row's depth by one
  level and cascade that change to the row's descendants: consecutive rows
  below it whose depth is greater than the row's depth before the edit, until a
  row of equal or shallower depth stops the walk. Outdenting is a no-op for the
  root row and floors non-root rows at depth 1.
- Each row's expand/collapse chevron is rendered only when the row has
  children (`hasChildren`); leaf rows reserve the chevron's width with a blank
  spacer so bullets and text stay aligned. Clicking a parent's chevron toggles
  `isExpanded`. `OutlinerView.visibleRowBindings` walks the flat rows, tracks
  the depth of the nearest collapsed ancestor, and drops any row deeper than
  it, so collapsing a row hides its descendants from display without touching
  the underlying array. `hasChildren` is recomputed by `refreshHasChildren`
  after every structural edit (insert, delete, indent, outdent). Rows default
  to expanded (`isExpanded: true`) so a newly indented child never disappears
  under a parent it has just gained.

Height-syncing, Return-key row insertion, backspace/delete row removal,
Tab/Shift+Tab indentation, and expand/collapse are the current focus of active
work. As the user types, the measured text height flows back up the chain and
is written to `row.height`, so the row resizes to fit its text. Pressing Return
splits the row at the cursor into two rows, and focus moves to the new row.
Pressing backspace or forward-delete at the start of a row removes that row
(promoting its descendants one level), and focus moves to the row above (the
root row can never be removed). Pressing Tab or Shift+Tab changes the row's
depth, moving its descendants with it. Clicking a parent row's chevron
collapses or expands its descendants.

## Key design notes

- **Model is the source of truth.** `OutlinerRowModel` holds the row's text,
  depth, expansion state, and measured height; views are derived from it.
- **Height is measured, never hardcoded.** The text view's height is derived
  from `layoutManager.usedRect`, clamped to at least one line. A 0.5 pt change
  threshold avoids redundant height updates. The container's height is fixed at
  `.greatestFiniteMagnitude` (`heightTracksTextView = false`); the representable
  measures the content and controls the view's height, owned by SwiftUI via
  `frame(height:)`. Rows start at a hardcoded placeholder height
  (`initialRowHeight`, 20 pt) until their first measurement arrives.
- **Flat rows for now.** `rows` is a flat `[OutlinerRowModel]` rendered in a
  `LazyVStack`. If the outline becomes a true tree, the row model and the
  container will need to change together.
- **Root row is `rows[0]`.** The topmost row lives at index 0 and is pinned to
  depth 0; every other row is a descendant and sits at depth 1 or deeper. The
  root can never be deleted, indented, or outdented (`deleteRow` and `indentRow`
  guard on `index != 0`, `outdentRow` floors non-root rows at depth 1, and new
  rows are created at `max(row.depth, 1)` so nothing is ever born at depth 0).
  The root renders visually larger than the rest: its text uses a 30 pt bold
  font (`rootFontSize`) while other rows use 14 pt regular (`editorFontSize`),
  its height is still measured from `textView.font`, and it renders no bullet.
  The root row is center-aligned so its expand/collapse chevron sits at the
  row's vertical center and stays there as the row's text grows; other rows
  remain top-aligned.
- **Fixed geometry lives in named constants.** Indent width (16 pt per depth
  level), chevron width, bullet size, paddings, the chevron expand angle, and
  the row font sizes are file-private constants, not magic numbers.
