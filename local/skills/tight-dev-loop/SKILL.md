---
name: tight-dev-loop
description: >
  Drives non-trivial code changes through a tight loop: pin a task card,
  find a neighboring pattern, change one small slice, prove it with evidence,
  then stop or advance. Use when implementing a feature, fixing a bug, or
  refactoring, especially on a smaller or faster model, or when the user asks
  for high-efficiency development, small-step verification, no guessing, a
  strict process, or throughput close to a stronger model. Also use when a
  coding task is about to start from memory, the diff is growing without a
  green proof, or you cannot name the existing pattern you will copy. Skip
  read-only questions and one-line answers. If a more specific skill is also
  loaded (tests first, security, commit format), use this loop as the outer
  order and that skill inside the matching step.
---

# Tight Dev Loop

Finish one proved slice at a time.

A stronger model keeps the plan, the local pattern, and the failure signal
in its head. You keep them on a written card. The card is the source of
truth. Memory is not.

Follow the steps literally and in order. Reply to the user in the user's
language, briefly. Code, names, and comments match the repository, not
this skill.

If another loaded skill owns a step (tests first, security, commit format,
repository `AGENTS.md`), follow it inside the matching step. This skill
still decides the order, the slice size, and what counts as evidence.

If the user explicitly asks you to skip process and just edit, do that.

## Words

- **Card:** the nine-field block below. It is the only plan you trust.
- **Neighbor:** the nearest existing function, flag, test, or call path
  that already does the closest thing. You copy its shape: names, errors,
  tests, layering. Example: `cmd/root.go:verboseFlag`.
- **Slice:** one behavior change. If the sentence needs "and" to join two
  behaviors, it is two slices.
- **Proof:** the exact command or inspection that decides pass or fail.
  Example: `go test ./cmd -run TestJSON`. "I read the code" is not a proof.
- **Green:** the last proof result you actually saw. "Should pass" is not
  green.
- **Real:** supported by a tool result in this session. Anything you only
  remember is `unknown`.

## Card

Keep the card in the conversation. Do not write it to a repository file
unless the user asks for a plan file.

```
Goal:        <one sentence, user's words>
Done when:   <outcome a stranger could observe>
Out:         <one nearby change you will not make>
Neighbor:    <path:symbol, or unknown>
Slice:       <one behavior, or unknown>
Proof:       <exact command or inspection, or unknown>
Files:       <paths this slice will touch>
Green:       <quoted result line, or none>
Left:        <remaining slices, or none>
```

- `Neighbor` is real only if you read that symbol in this session.
- `Proof` is real only if you found the command in the repository (script,
  Makefile, CI step, README, an existing test) or wrote the exact
  inspection: which lines you will quote, or which command you will run
  and what output means pass.
- `Green` is real only if it quotes the pass or fail line you saw.

Show the full card after Pin. After each slice, update the card and show
four lines: slice, proof result, files, next. When a later user message
arrives in the same task, re-pin first and drop any field it invalidates.

## The Loop

Move forward only when the current step's done-when is true. You may edit
only in Change, and only the paths in `Files`.

### 1. Pin

Fill `Goal`, `Done when`, and `Out` from the latest user message before
you search or edit.

"Make it better" is not a `Done when`. If the user gave no observable
outcome, pick the smallest check a stranger could run and say that you
chose it.

Done when: all three are filled, and `Out` names a real nearby change.

### 2. Orient

Find three things in the repository, not in habit:

- the files that own this behavior,
- the neighbor,
- the proof command. Check `package.json` scripts, `Makefile`, CI
  workflow, README, CONTRIBUTING, or how an existing test is run.

Search before you read. Read a window around the match, not the whole
file. Batch independent searches in one turn. Every read needs a
question; reading without one is stalling.

Budget about six searches and reads. If `Neighbor` or `Proof` is still
`unknown`, say what you looked for, then either ask one question or cut a
slice whose only job is to find the seam.

Done when: `Neighbor` and `Proof` are real, or you told the user the
missing fact the repository cannot give you.

```
Bad:  Neighbor: probably a flag parser somewhere.  Proof: npm test
Good: Neighbor: cmd/root.go:verboseFlag            Proof: go test ./cmd -run TestJSON
```

### 3. Slice

Pick one behavior using the recipe for the task:

| Task     | First slice                                 | Later slices                         |
|----------|---------------------------------------------|--------------------------------------|
| Bug      | Make the proof fail for the reported reason | Smallest edit that makes it pass     |
| Feature  | Smallest path that shows the new behavior   | Next caller, edge, or wire-up        |
| Refactor | Proof already green. One mechanical move.   | Next move, while the proof stays green |

Write only the current slice on the card, and fill `Files` with the exact
paths it touches. Three files or fewer, unless the neighbor itself spans
more and you are copying that span. No cleanup, no reformatting, no
"while I am here".

Done when: `Slice` states one behavior and `Files` lists its paths.

### 4. Ground

Re-read the exact lines you will change and the signatures you will call,
in this session. Take edit text from that read, never from an earlier
message or from memory.

Done when: `Neighbor`, `Slice`, `Proof`, and `Files` are all real.

### 5. Change

Make one surgical edit that copies the neighbor's shape. Add no helper,
abstraction, or config the neighbor does not use. Leave imports,
comments, and formatting outside the slice alone.

If the edit does not apply, re-read the span and retry once from the
fresh text.

Done when: the edit landed, or it failed twice and you said so.

### 6. Prove

Run `Proof` before any further edit. Quote the pass or fail line into
`Green`. Then:

- **Green:** go to Advance.
- **Red, attempt 1 or 2:** read the error, fix only the cause it names,
  re-run the same proof.
- **Red, attempt 3:** the slice was too big, or the cause is outside your
  files. Restore only the files this slice changed. Never `git reset
  --hard`, and never revert a file you did not change. Set `Green` back
  to the previous result and return to Slice with a smaller slice.
- **No test runner:** the proof is a command you found, or an inspection
  that quotes a line you just read or output you just produced. It is
  green only if the quoted line matches `Done when`. Say which command
  you could not run.

Do not switch to a different proof because this one failed. Do not re-run
a green proof on unchanged code. Widen to the full suite only after the
narrow proof is green and the slice touches shared behavior.

Done when: `Green` quotes output you saw, or you reported why the proof
could not run.

### 7. Advance or Stop

If `Done when` is met, stop. Do not refactor adjacent code or open
another file for completeness. Mention leftover ideas in one line of the
report instead of acting on them.

Otherwise move the next item from `Left` into `Slice` and return to
step 3 to set `Files`. Return to Orient only if that slice needs a
different neighbor.

Done when: you stopped, or the next slice is on the card.

## Ask Only Then

Read first. Ask only when a tool result cannot decide:

- Two neighbors conflict, and the choice changes a public API or
  persisted data.
- The next step needs a credential, a destructive command, or a
  production write.
- `Done when` still has two meanings after you read the owning code.

Otherwise pick the smallest reversible option, note it on the card, and
continue. Ask one question, not a list.

Commit, push, or write a plan file only when the user asks.

## Report

```
Done:   <yes, or the slice that is green and what is left>
Proof:  <command and the result line you saw>
Files:  <paths>
Out:    <what you did not change>
```

If you did not run a proof, the first line is `Done: no`. Add no summary
paragraph, walkthrough, or suggestions unless the user asks.

## Stop Signs

Return to the matching step when you notice any of these:

- You are editing a file that is not on the card.
- The card holds more than three files and no neighbor spans them.
- You are about to claim green without a quoted line.
- You are starting the next slice while the proof is red.
- You read the same span three times with no edit or proof between.
- You are about to ask the user something a search could answer.

For a full worked example and the excuses that usually precede a broken
loop, read `references/worked-example.md`.
