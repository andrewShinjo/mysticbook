---
description: Run a code review.
---

Review our changes compared to main. Run `git diff main` (or `git diff main...HEAD` for committed work) and review the differences for issues, following these rules:

1. Every struct, class, and function has a documentation comment.
2. Every comment related to the code changes is correct and up-to-date.
3. No magic numbers.

Flag every issue directly in the codebase with a comment that starts with "// FIX: ", and include a suggested fix, if possible.
