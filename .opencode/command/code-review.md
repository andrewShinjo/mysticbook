---
description: Run a code review.
---

Review our changes compared to main. Run `git diff main` (or `git diff main...HEAD` for committed work) and review the differences for issues, following these rules:

Scope the review to code introduced or directly modified by the diff. Do not flag pre-existing declarations that merely live in a touched file.

1. Every struct, class, and function introduced or directly modified by the change has a documentation comment. Properties, constants, and other variables need a documentation comment only when their purpose is non-obvious (for example, a magic-number constant or state kept to avoid redundant work); do not document self-evident members.
2. Every comment added or modified by the change is correct and up-to-date.
3. No magic numbers in the lines the change adds or modifies.
4. AGENTS.md files that document the code the change touches are still accurate. Locate AGENTS.md files by walking up from each changed file's directory to the repo root. If the change invalidates anything they document (architecture, data flow, design notes), flag the AGENTS.md as stale and specify what must be updated.

