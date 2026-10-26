---
name: subagent-delegation
description: Decomposes a task into bounded subtasks and dispatches each to a subagent running a smaller, cheaper model, while the main model keeps planning, integration, and final verification and stays on its own provider by default. Use when a task is large, parallelizable, or mostly mechanical, when a strong model should reserve its context and judgment for design and review, or when the user asks to split work across subagents or cheaper models.
metadata:
  requires: runtime subagent support with per-subagent model selection
  provider-policy: same provider as the main agent unless the user approves otherwise
---

# Subagent Delegation

## Overview

A high-capability main model is the most expensive and least replaceable
resource in the session. Use it for what only it can do — interpreting the
request, designing the approach, resolving ambiguity, integrating results, and
judging quality — and push bounded, checkable work onto subagents running
smaller models from the same provider.

The main agent remains the orchestrator. It never hands off ownership of the
outcome: it writes the brief, dispatch the work, verifies the artifact, and
owns the final answer.

## When to Use

Use when:

- The task splits into two or more workstreams that can progress independently.
- Most of the work is mechanical: searching, extracting, summarizing, applying
  a known change repeatedly, scaffolding tests, updating documentation.
- The main context would otherwise fill with raw material that only needs to be
  read once (large logs, many files, broad search results).
- The user asks to use subagents, parallelize, or spend fewer tokens on a task.

**When NOT to use:**

- The task is small enough to finish in a few tool calls. Delegation overhead
  exceeds the work.
- The work is one indivisible judgment call, such as choosing an architecture or
  finding the root cause of an unknown failure.
- Subtasks cannot be verified independently (no diff, file, test, or report to
  check).
- A subagent would need the same context budget as the main agent to succeed.
- The work is security-sensitive, irreversible, or requires user approval at
  each step.

## Model and Provider Policy

### Provider: same as the main agent by default

1. Derive the main agent's provider from its own model reference. For example,
   `ollama-cloud/glm-5.3` means the provider is `ollama-cloud`.
2. Choose the subagent model from **that same provider**.
3. Do not switch providers on your own initiative. Only use a different
   provider after the user explicitly approves it for this task or session.
   A user mentioning a model name is not approval to change provider; ask.
4. If the same provider has no suitable model for a subtask, say so and ask
   before crossing providers.
5. When approval is given, state the cross-provider choice and the reason in
   the final summary.

Ask a single, specific question when approval is needed, for example: "This
subtask needs a model with tool calling and a large context window; the current
provider has none available. May I use a model from another provider?"

### Model tier: smallest tier that can do the job

| Tier | Work it should own | Typical choice |
| --- | --- | --- |
| Orchestrator (main model) | Requirement interpretation, decomposition, design, review, conflict resolution, final verification | The model already running the session |
| Worker | Bounded implementation against a precise brief, test scaffolding, refactors with a known pattern | The fast/cheap sibling of the main model family, else the provider's cheapest strong model |
| Mechanical | Search, extraction, formatting, summarizing, running a command and reporting output, repetitive edits | The provider's smallest model with tool calling |

As of this writing, models available on `ollama-cloud` include the orchestrator
tier (`glm-5.3`, `deepseek-v4-pro:0813`, `kimi-k3`), the worker tier
(`glm-5.3-flash`, `deepseek-v4.1-flash:1017`, `minimax-m3.1-flash`), and the
mechanical tier (`gemma4:31b`, `gpt-oss:20b`). Treat these as examples, not a
fixed catalog: model IDs, variants, prices, and availability change.

### Resolving the model reference

Look the model up before dispatch; never guess an ID or provider prefix.

- OpenCode: use the model search tool (`tools.opencode.models`), filtering by
  the main agent's provider first, then pass the returned `providerID/modelID`
  to the subagent tool's `model` parameter.
- Other runtimes: use their equivalent model lookup, or the exact IDs listed in
  the local configuration.

Prefer, in order:

1. The cheap sibling of the main model family (for example `glm-5.3` →
   `glm-5.3-flash`), since it shares conventions and formatting behavior.
2. Another model on the same provider at the lowest tier that reliably handles
   the subtask.
3. A cross-provider model, only with recorded user approval.

If the chosen model exposes reasoning-effort variants, use the lowest effort
that still passes the subtask's verification. Variant names differ by model
(`low`, `medium`, `high`, `max`, …); check before passing one.

## Step 1: Decide whether to Decompose

Decompose only when all three are true:

- [ ] At least two subtasks can proceed without waiting on each other's output,
      or the total raw material clearly exceeds what the main context should
      hold.
- [ ] Each subtask has a deliverable the main agent can check without redoing
      the work — a diff, a file, a test result, or a structured report.
- [ ] Each brief can be written without first solving the subtask.

If any is false, do the work directly. Splitting a task that fails these tests
produces delegation theater: more tokens, more coordination, worse output.

## Step 2: Cut into Bounded Subtasks

Rules for a good cut:

- **One deliverable each.** A subtask produces one artifact or one report.
- **Small enough to verify.** Target 1–3 files or one command's worth of work.
  If it needs a tour of the repository, it is too large.
- **Self-contained.** The brief carries every path, constraint, and acceptance
  criterion the subagent needs. Never write "explore and figure out".
- **Disjoint write scopes when parallel.** Two subagents must not edit the same
  file at the same time. If scopes overlap, run them sequentially.
- **Explicit dependencies.** Dispatch in waves: independent subtasks first,
  then subtasks that consume their output.
- **Bounded width.** Three to five concurrent subagents is the practical limit.
  Needing more usually means the decomposition is wrong.
- **Split by artifact and verification boundary**, not by file count or by
  layer (all schema, then all API, then all UI).

Examples:

| Bad cut | Why | Better cut |
| --- | --- | --- |
| "Build the backend" | No single deliverable, unbounded | "Add `POST /users` handler in `src/api/users.ts` per this contract; run `pnpm test users`" |
| "Fix all failing tests" | Cause unknown, needs judgment | "Collect and group the failures from `pnpm test` into a report; do not edit code" |
| "Research the codebase" | Unbounded context | "List every caller of `legacyAuth()` with file:line and the argument shape" |
| "Update the docs" | Ambiguous scope | "Update the 6 endpoint sections in `docs/api.md` to match these signatures" |

## Step 3: Write the Brief

Keep each brief under roughly 200 words and make it operational:

```text
Goal: <one sentence, observable outcome>

Context: <repo and branch; relevant files with line references; patterns to follow>

Inputs: <exact paths, commands, docs, or excerpts the subagent needs>

Constraints:
- Do not touch <out-of-scope paths>
- Match <existing pattern or style>
- No new dependencies
- Stop and report if <blocking condition> instead of guessing

Deliverable: <files to create or modify, or the exact report structure>

Verification: <command to run and expected result>

Report back: <summary, changed files, test output, open questions>
```

Brief rules:

- Give paths, not descriptions of where to look.
- State explicit non-goals; cheaper models tend to expand scope.
- Require evidence (command output, diff stat), not self-assessment.
- Tell the subagent to stop and report when blocked rather than inventing a
  solution.

## Step 4: Dispatch

- Send independent subtasks in parallel, in one tool block, so they actually
  run concurrently.
- Run dependent subtasks sequentially and feed the previous artifact forward.
- Use foreground execution when the next step needs the result; use background
  only for work that can be integrated later.
- Subagents cannot spawn their own subagents. If a subtask turns out to need
  decomposition, the main agent splits it and dispatches the pieces.
- Reuse a subagent session to iterate on the same artifact; start a new one for
  unrelated work so stale context does not leak in.
- Keep a lightweight ledger while work is in flight: subtask, model, write
  scope, status, result location. It prevents duplicate or conflicting work.

Example shape for a runtime that exposes a subagent tool with model selection:

```text
subagent({
  agent: "general",
  description: "Add users POST handler",
  model: "ollama-cloud/glm-5.3-flash",
  prompt: "<the brief from Step 3>"
})
```

## Step 5: Integrate and Verify

- Never accept "done" from a subagent as evidence. Read the diff and run the
  verification command yourself.
- Check scope: only the intended files changed, and no unrelated rewrites.
- Run the repository's full gates at integration points, not only per-subtask
  checks.
- On failure, re-brief once with the exact failure output and a narrower scope.
  If it fails again, take the work over on the main model or escalate one tier.
- After integration, confirm the combined result still satisfies the original
  request — individually correct subtasks can still compose incorrectly.
- Report which subtasks ran on which models and what was verified.

## What the Main Agent Must Not Delegate

- Interpreting the request, or asking the user clarifying questions.
- Architecture, API, and data-model decisions.
- Root-cause debugging of an unknown failure. (Gathering logs or reproducing it
  mechanically can be delegated.)
- Security-sensitive code, authentication, secrets, migrations, and destructive
  operations.
- Final review, merge, and conflict resolution.
- Anything that requires user approval or a product decision.

## Common Rationalizations

| Rationalization | Reality |
| --- | --- |
| "It is faster to just do it myself." | True for small tasks, false once context fill and serialization dominate. Apply the Step 1 tests instead of guessing. |
| "Delegate everything to save tokens." | Orchestration and review have real costs, and small models amplify ambiguity into rework. Delegate only bounded, verifiable work. |
| "The subagent said the tests pass." | An unverified claim is not evidence. Run the command and read the output. |
| "The user mentioned a model from another provider, so it is approved." | Naming a model is not approval to switch providers. Ask explicitly and record the answer. |
| "This task is too ambiguous to brief." | Then it is not ready for delegation. Resolve the ambiguity on the main model first. |
| "The subagent can explore the repo and decide." | Small models burn context and drift. Supply exact paths, constraints, and non-goals. |
| "More subagents means more speed." | Coordination, conflicts, and merge cost grow faster than parallelism helps. Cap the width. |

## Red Flags

- More subagents than subtasks with independently checkable deliverables.
- Briefs that say "implement the feature" or "look around the codebase".
- Two parallel subagents editing the same file or package.
- A cross-provider model used without recorded approval.
- Subagent output pasted into the final answer without being read.
- A subagent asked to make a product, architecture, or security decision.
- The main agent going quiet while several background subagents run, with no
  integration step planned.

## Verification

Before reporting completion, confirm:

- [ ] Decomposition passed the Step 1 tests, or the task was done directly with
      a stated reason.
- [ ] Every subtask has one deliverable and a command or inspection that
      verifies it.
- [ ] Every brief contains exact paths, constraints, non-goals, and the report
      format.
- [ ] Parallel subtasks have disjoint write scopes; dependent ones ran in order.
- [ ] Every subagent model comes from the main agent's provider, or the user's
      cross-provider approval is recorded and stated.
- [ ] Model references were resolved through model lookup, not guessed.
- [ ] Every result was independently verified (tests run, diff read, output
      checked).
- [ ] Failed subtasks were retried once with a sharper brief, then escalated or
      taken over.
- [ ] The integrated result satisfies the original request.
- [ ] The final summary names the models used per subtask and what was verified.
