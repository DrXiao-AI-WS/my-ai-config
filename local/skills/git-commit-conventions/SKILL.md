---
name: git-commit-conventions
description: Formats git commit messages and decides how to split and
  attribute them. Use when running "git commit", when staged changes span
  more than one logical concern, or when an AI coding agent has authored
  some or all of the changes and the commit needs a Co-authored-by trailer.
---

# Git Commit Conventions

## When to use

Any time a commit is about to be created in a repository that loads this
skill — deciding whether to split staged changes into multiple commits,
writing the commit message itself, and attributing AI-authored work.

## Splitting commits

If the staged (or about-to-be-staged) changes contain more than one
logically separate concern, split them into multiple commits rather than
one combined commit. A "logical concern" is a change that could be
described, reviewed, or reverted independently of the others.

## Message format

This repo family's commit style does **not** use a conventional-commits
type prefix (`feat:`, `fix:`, etc.) on the subject line. If another loaded
skill (e.g. a generic git-workflow skill) suggests a type-prefixed subject,
this skill's format takes precedence:

1. [MUST] Separate subject from body with a blank line.
2. [MUST] Limit the subject line to 50 characters if possible; 72 is the
   acceptable maximum.
3. [MUST] Capitalize the subject line.
4. [MUST] Do not end the subject line with a period.
5. [MUST] Use the imperative mood in the subject line (e.g. "Fix bug", not
   "Fixed bug" or "Fixes bug").
6. [MUST] Wrap the body at 72 characters.
7. [MUST] Use the body to explain what and why, not how.

## Co-authored-by attribution

When an AI coding agent substantially authors a commit (i.e. produces most
of the code changes or drives the implementation), append a
`Co-authored-by` trailer matching the agent currently executing the task.
Determine the agent identity from the current execution context before
committing:

| Agent            | Trailer                                        |
| ---------------- | ----------------------------------------------- |
| Claude Code       | `Co-authored-by: Claude <noreply@anthropic.com>` |
| OpenAI Codex      | `Co-authored-by: Codex <noreply@openai.com>`     |
| OpenCode          | `Co-authored-by: opencode <noreply@opencode.ai>` |
| GitHub Copilot    | `Co-authored-by: Copilot <copilot@github.com>`   |
| any other agent   | omit the trailer unless the user specifies one   |

If both human contributors and an AI agent contributed to the same commit,
list human `Co-authored-by` lines first, followed by the agent's.

If the coding agent is Claude Code, it is not necessary to include a
"Co-authored-by \<model name\>" line or the Claude session ID in the commit
message — the agent-identity trailer above is sufficient.

## Verification

Before finalizing a commit message, check:
- [ ] Changes that are logically separate are in separate commits.
- [ ] Subject line: capitalized, imperative, no trailing period, no type
      prefix, ≤50 chars (≤72 acceptable).
- [ ] Blank line between subject and body.
- [ ] Body wrapped at 72 chars and explains what/why, not how.
- [ ] Correct `Co-authored-by` trailer present (or correctly omitted) for
      the executing agent.
