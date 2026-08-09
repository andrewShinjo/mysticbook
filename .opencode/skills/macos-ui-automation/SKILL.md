---
name: macos-ui-automation
description: Drive and verify macOS SwiftUI/AppKit apps through the Accessibility API using osascript + System Events. Use when you need to reproduce a UI bug, type/click in a running macOS app, or verify UI behavior programmatically. Triggers: "drive the app", "reproduce", "verify UI", "accessibility", "type into the app", "UI automation".
---

# macOS UI Automation (Accessibility)

Drives a running macOS app (SwiftUI or AppKit) by reading and controlling its
Accessibility tree with AppleScript (`osascript` → `System Events`). No
simulator, no XCTest, no UI-test target needed. This is the technique used to
reproduce outliner row bugs in `mysticbook`.

## Prerequisites

1. **Accessibility permission.** The shell must have assistive access. Probe
   it (if this errors or lists nothing usable, the permission is not granted):

   ```bash
   osascript -e 'tell application "System Events" to get name of first process'
   ```

   **Screen Recording is NOT required** — observe state via the AX tree, not
   screenshots. `screencapture` fails with "could not create image from
   display" when Screen Recording is not granted; don't rely on it.

2. **App built and launched.** Prefer the `xcodebuildmcp` workflow:

   ```bash
   xcodebuildmcp macos build --scheme <Scheme> --project-path <path/to/.xcodeproj>
   xcodebuildmcp macos get-app-path --scheme <Scheme> --project-path <path/to/.xcodeproj>
   xcodebuildmcp macos launch --app-path "<app path from previous step>"
   ```

## Read state

Target the process, then walk into its window:

```applescript
tell application "System Events"
  tell process "<AppName>"
    tell front window
      -- inspect here
    end tell
  end tell
end tell
```

Element attributes: `role`, `description`, `value` (text of a text view),
`position`, `size`.

- `position`/`size` print as **concatenated** strings, e.g. `5584` = x=55,
  y=84, and `163117` = 163 wide, 117 tall. Split the digits when you need the
  components: `item 1 of p` and `item 2 of p` on the parsed value.

## Known hierarchy (OutlinerView rows)

For this app each row is a pair of elements inside
`window → first UI element (group) → first UI element (AXScrollArea) → first UI
element (AXOpaqueProviderGroup)`, in document order:

- `AXButton` — the expand/collapse chevron. Only present on rows that have
  children; leaf rows reserve the slot with a blank spacer and expose no button.
- `AXTextArea` — the editable `NSTextView`; its `value` is the row's text.

Collapsing a row removes its descendants' `AXTextArea`s from the tree until it
is expanded again.

For unknown hierarchies, walk recursively: `every UI element of X`, reading
`role`/`description` at each level until you find `AXTextArea` (or the element
you need).

## Drive input

- **Focus a row** — `set focused of e to true` (the AXFocused attribute). This
  is the *reliable* method. Coordinate `click` can land on the wrong row or
  silently miss, leaving focus on whatever row was last edited.
- **Place the cursor** — `click at {x, y}` (global screen coords) inside the
  focused text area, or use keyboard shortcuts (below).
- **Type text** — `keystroke "text"`.
- **Key codes** (`key code N`):
  | Key          | Code |
  |--------------|------|
  | Return       | 36   |
  | Tab          | 48   |
  | Backspace    | 51   |
  | Left arrow   | 123  |
  | Right arrow  | 124  |
- **Modifiers** — `key code 123 using command down` (Cmd+Left = cursor to
  start), `key code 124 using command down` (Cmd+Right = cursor to end),
  `keystroke "a" using command down` (select all).
- Ensure the app is focused first: `set frontmost to true`, and add small
  `delay 0.2–0.4` between actions to let AppKit process events.

## Verify loop

Re-read the element `value`s after each step and assert the expected state
before continuing. Example (list every row):

```applescript
set scrollArea to first UI element of front window
set inner to first UI element of scrollArea
set listG to first UI element of inner
repeat with e in every UI element of listG
  if role of e is "AXTextArea" then
    set out to out & "row value=[" & (value of e) & "] pos=" & (position of e) & linefeed
  end if
end repeat
```

## Pitfalls

- **Coordinate clicks can hit the wrong row** — prefer `set focused of e to
  true`. If you must click, click several points in from the text area's left
  edge, and re-read `AXFocused` to confirm before sending keystrokes.
- **Focus moves after structural edits.** Deleting a row moves focus to the
  predecessor row; creating a row moves focus to the new row. Re-focus the
  intended row after any such edit.
- **`screencapture` needs Screen Recording** — not granted by default; use the
  AX tree as the observation channel instead.
- **`xcodebuildmcp ui-automation` tools are iOS-simulator-only** (require
  `--simulator-id`); they do not work for macOS apps.

## Worked example: reproduce a row-edit bug

Goal: rows X(0), B(1), C(1), D(1); delete B; type "1" at the end of C; observe
whether C shows "C1" (correct) or the edit lands on another row (stale-binding
bug).

1. Replace the first row's text with "X" (click/focus, Cmd+A, `keystroke "X"`).
2. `key code 36` (Return) → type "B" → `key code 48` (Tab, indents to depth 1).
3. `key code 36` → type "C" → `key code 36` → type "D".
4. Focus row 2 (B), `key code 123 using command down`, `key code 51`
   (Backspace at position 0 deletes the row).
5. Verify rows are now X, C, D.
6. Focus row 2 (C), `key code 124 using command down`, `keystroke "1"`.
7. Read all row values. Expected with correct bindings: X, C1, D. The buggy
   app shows X, C, C1 (the edit landed on D's slot and C reverted).
