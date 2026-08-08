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

State flows down from a single owner, and measured geometry flows back up.

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
  communication with SwiftUI through its `Coordinator`.
- `OutlinerTextView` is an `NSTextView` subclass that invokes `onLayout` after
  each layout pass. The representable uses this callback to re-measure the
  content.

Height-syncing is the current focus of active work: as the user types, the
measured text height flows back up the chain and is written to `row.height`, so
the row resizes to fit its text.

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
- **Fixed geometry lives in named constants.** Indent width (16 pt per depth
  level), chevron width, bullet size, paddings, and the chevron expand angle are
  file-private constants, not magic numbers.
