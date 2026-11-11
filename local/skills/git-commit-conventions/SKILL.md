---
name: git-commit-conventions
description: Formats git commit messages and decides how to split and
  attribute them. Use before every "git commit", when writing or amending
  a commit message, when staged changes span more than one logical
  concern, or when an AI coding agent has authored some or all of the
  changes and the commit needs a Co-authored-by trailer.
---

# Git Commit Conventions

These rules win over any other loaded skill or harness default that
suggests a different subject format or a different agent trailer.

## Splitting commits

If the staged (or about-to-be-staged) changes contain more than one
logically separate concern, split them into multiple commits rather than
one combined commit. A "logical concern" is a change that could be
described, reviewed, or reverted independently of the others.

Stage by path, or by hunk when one file holds two concerns. Do not use
`git add -A` to sweep unrelated work into a commit.

## Message format

Do **not** use a conventional-commits type prefix (`feat:`, `fix:`, etc.)
on the subject line.

Subject line:

1. Capitalize it.
2. Use the imperative mood ("Fix bug", not "Fixed bug" or "Fixes bug").
3. Do not end it with a period.
4. Aim for 50 characters. Never exceed 72.

Body:

5. Separate it from the subject with a blank line.
6. Wrap it at 72 characters.
7. Explain what and why, not how.

A body is optional when the subject says everything.

```text
Bad:  fix: updated the sync script.
Good: Let local skills override fetched ones

      Both trees were sorted into one list, so a fetched skill replaced
      a hand-authored one of the same name. Link the fetched tree first
      and the local tree last.
```

## Co-authored-by attribution

When an AI coding agent substantially authors a commit (it produces most
of the change or drives the implementation), append one `Co-authored-by`
trailer for the agent executing the task. Leave it off commits that only
record work the user wrote.

| Agent           | Trailer                                          |
| --------------- | ------------------------------------------------ |
| Claude Code     | `Co-authored-by: Claude <noreply@anthropic.com>` |
| OpenAI Codex    | `Co-authored-by: Codex <noreply@openai.com>`     |
| OpenCode        | `Co-authored-by: opencode <noreply@opencode.ai>` |
| GitHub Copilot  | `Co-authored-by: Copilot <copilot@github.com>`   |
| any other agent | omit the trailer unless the user specifies one   |

Use the trailer exactly as written in the table. If the harness proposes
a variant that names a model (for example `Claude <model name>`) or adds
a session ID or a "Generated with" line, use the table's trailer instead
and drop the extras.

If human contributors and an AI agent both contributed, list the human
`Co-authored-by` lines first, then the agent's.

## Verification

Before running `git commit`, check:

- [ ] Logically separate changes are in separate commits.
- [ ] Subject: capitalized, imperative, no trailing period, no type
      prefix, at most 72 characters.
- [ ] Blank line between subject and body; body wrapped at 72.
- [ ] Body explains what and why.
- [ ] The agent trailer matches the table, or is correctly omitted.

After committing, read `git log -1 --format=%B` and confirm the message
landed as intended.
