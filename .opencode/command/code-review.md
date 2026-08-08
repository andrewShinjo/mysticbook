---
description: Run a code review.
---

Review our changes compared to main by delegating each rule to a dedicated sub-agent, then consolidating their findings. Do not perform the rule checks yourself.

## Setup

1. Capture the diff to review:
   - For committed work, run `git diff main...HEAD`.
   - For uncommitted work, run `git diff`.
   - If both exist, review both; treat the working tree and committed changes as one review scope.
2. Save the diff output to a temp file (e.g. under `/var/folders/.../T/opencode/`) so sub-agents can read it without you re-pasting it. Keep the diff's file paths and line numbers intact.
3. Confirm the scope: review only code introduced or directly modified by the diff. Do not flag pre-existing declarations that merely live in a touched file.

## Spawn one sub-agent per rule

For each rule below, launch a dedicated sub-agent with the Task tool, all four in parallel. Use the `explore` sub-agent type, the read-only agent permitted in this project; if a type is blocked by permissions, fall back to the permitted type. Give every sub-agent:

- The scope note: review only code introduced or directly modified by the diff; do not flag pre-existing declarations that merely live in a touched file.
- The location of the saved diff (tell it to read the temp file, or paste the diff if small). Each sub-agent may instead regenerate the diff itself by running `git diff main...HEAD` and `git diff` in the repo; use this when a temp file can't be written (e.g. plan mode).
- The rule text, verbatim.
- The instruction to return findings as a concise list with `file:line` references, or "No issues" if clean.
- The instruction to review only and never edit files.

Rule 1: Every struct, class, and function introduced or directly modified by the change has a documentation comment. Properties, constants, and other variables need a documentation comment only when their purpose is non-obvious (for example, a magic-number constant or state kept to avoid redundant work); do not document self-evident members.

Rule 2: Every comment added or modified by the change is correct and up-to-date.

Rule 3: No magic numbers in the lines the change adds or modifies.

Rule 4: AGENTS.md files that document the code the change touches are still accurate. Locate AGENTS.md files by walking up from each changed file's directory to the repo root. If the change invalidates anything they document (architecture, data flow, design notes), flag the AGENTS.md as stale and specify what must be updated.

## Consolidate

After all sub-agents return, merge their findings into a single report grouped by rule, with `file:line` references. Report "No issues" for any rule that came back clean. Do not edit code; review only.

