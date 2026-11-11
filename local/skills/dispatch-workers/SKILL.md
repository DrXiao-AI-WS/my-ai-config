---
name: dispatch-workers
description: >
  Assigns a bounded slice of the current task to a cheaper, lower-intensity
  model, then supervises that worker in the same child session until the
  slice is accepted or taken back. Use when you are a flagship or
  high-reasoning model and the task has separable work a weaker model can
  finish under a checkable done-when: exploration, mechanical edits,
  parallel independent slices, boilerplate, running a known command,
  summarizing named files. Also use when the user asks to save cost, fan
  out, delegate, split work across subagents, assign work to a smaller or
  faster model, or stop spending the flagship on grunt work. Do not use it for a one-step answer, for
  judgment you have not made yet, to fan out from a child session, or when
  you are already the cheap model.
---

# Dispatch workers

You are the flagship. Judgment is the scarce resource. A cheaper model can
search, edit, and run commands. It cannot see what you left unwritten, and
it will not notice that it solved the wrong problem.

You split, brief, dispatch, and accept. The worker does one slice. You keep
the split, the model choice, the acceptance, and the integration. The user
is paying for the child, so a dispatch that costs more to review than to do
is a failed dispatch.

Reply to the user in the user's language. Briefs use the language of the
task. Paths and commands stay as they are in the repo.

You are the worker, not the flagship, if the prompt that started this
session is a brief with a `Lane:` field, or if this session has no
child-session tool. Do the slice in front of you. Do not dispatch further.

## Words

- **Dispatch:** send one slice to a cheaper model.
- **Brief:** the only context that worker gets.
- **Hand:** a slice with no new design. Search, read, summarize named
  files, run a known command, mechanical transform.
- **Craft:** a specified artifact, copied from a named neighbor.
- **Accept:** you checked done-when against evidence, including a
  spot-check of any load-bearing claim.
- **Correct:** a follow-up on the same child, naming the failed criterion.
- **Answer:** the one missing fact, sent to the same child.
- **Extend:** the next dependent slice, sent to a child you already
  accepted.
- **Take back:** you do the slice, and you stop the child.

## Keep or dispatch

Dispatch only when all of these are true:

- A stranger could check the done-when.
- The slice does not need a judgment you have not made yet.
- The brief is shorter than the work.
- A wrong result is recoverable: you can correct it or take it back.
- A cheaper tool-capable model is available. Look it up this session.

Keep the slice when any of these are true:

- The requirement is still ambiguous. That includes an unsettled security,
  auth, secret, or permission decision. A worker may touch those paths
  only after the decision is in the brief as a specified change, not as a
  problem for it to solve.
- The slice is the split, the model choice, the acceptance, the
  integration, or the conversation with the user.
- It is craft, and you cannot name the files, the neighbor, and the proof.
  Find those with a hand slice, or find them yourself if that is shorter
  than a brief.
- This session has no child-session tool that accepts a model and returns
  a resume handle.

A one-step answer stays with you. So does any slice the user told you to
do yourself, and any task they pinned to a named model.

Another loaded skill may spawn a child of its own for judgment: a code
reviewer, an adversarial second opinion, a research synthesis. That child
belongs to that skill. Spawn it the way that skill says, and do not lower
its model to save cost. The cheaper-model choice here applies only to
slices you cut in this loop.

## Loop

Prepare every slice through split, pick, and brief before you spawn.
Independent slices spawn together. Supervise each one when its result is
in front of you. Integrate last.

Move on only when the current step's done-when is true.

### 1. Split

A slice is one behavior or one question. If the sentence needs "and" to
join two behaviors, it is two slices.

Mark each slice keep, hand, or craft.

Two slices that share a file, or whose done-when depends on each other,
are not parallel. Sequence them on one child, or wait.

Done when: every slice is keep, hand, or craft, and each slice you will
dispatch has a one-sentence goal.

### 2. Pick a worker

Look up models in this session. An id you remember is stale. Do not invent
one.

Drop embeddings, image-only models, and anything deprecated. The worker
must be able to call tools. If a spawn fails because it cannot, pick the
next candidate. Do not retry that id.

Stay on your own provider. Take the provider from your own model id
(`acme/big-1` is provider `acme`) and pick the worker from that
provider's list. Another provider sees the brief and bills separately, so
crossing is the user's call: ask once, naming the model and why your
provider has nothing suitable. A user mentioning a model name is not that
approval.

Compare price to your own model, input plus output.

- **Hand:** the cheapest tool-capable model. Variant `low` if that model
  lists it.
- **Craft:** a model clearly cheaper than you. Variant `medium` if it
  lists one. A lower variant of a capable model beats a tiny model when a
  bad edit is expensive to unwind.

Pass the variant explicitly. An omitted variant may bill as high
reasoning, which spends the savings.

If no cheaper tool-capable model exists, keep the work. Spawning a peer
is for parallelism, not savings. If you do that, tell the user.

Done when: the slice has a `provider/model` id you just looked up, on
your own provider or one the user approved, with a variant when that
model lists one, or you have kept the slice.

### 3. Brief

The worker starts blank. A vague brief comes back confident and wrong,
and you pay to unwind it.

The brief is copied into another model's context. Include the paths and
facts the slice needs. Leave out credentials, tokens, and private data
the slice does not need.

```
Lane: hand | craft
Goal: <one sentence>
Done when: <observable by a stranger>
Out: <one nearby change not to make>
Files: <paths in scope>
Neighbor: <path:symbol to copy, or none. Do not invent a pattern>
Proof: <exact command or inspection, and the line that means pass>
```

Then the contract:

- Do only this slice. Paths not listed are out.
- If a fact is missing, stop and ask for that fact. Do not guess a path,
  API, flag, or command.
- Paste the proof output in the report. A paraphrase is not evidence.
- Do not commit, push, or spawn your own workers.
- Do not widen the diff, and do not clean up code the brief did not name.

If the slice changes code and the worker can load `tight-dev-loop`, tell
it to run that skill inside this slice. This brief's Done when and Out
win if they conflict.

Require this report:

```
Status: done | blocked | partial
Changed: <paths, or none>
Evidence: <quoted tool output>
Blocked on: <the one fact you need, or none>
Left undone: <what the brief asked that you did not do>
```

A hand slice may set Neighbor to none and Files to a directory. Its Proof
is still a check you could run, usually "quote the line you opened."

```
Bad:  Look around the auth code and fix the login bug.
Good: Lane: hand
      Goal: Find the function that rejects an expired session cookie.
      Done when: path:symbol you opened, plus the expiry-check line.
      Out: do not propose a fix.
      Files: src/auth/**
      Neighbor: none. Do not invent a pattern.
      Proof: quote the expiry check. A file name alone is not found.
```

Done when: all six fields are filled, Out names a real nearby change, and
Proof is a check you could run yourself.

### 4. Dispatch

Read the child-session tool schema in this session before the first spawn.
Use the fields it actually has. A field name from another harness is a
guess. Do not send it.

You need a model parameter, a prompt set to the brief, and a resume handle
for that same child.

The tool may say not to set a model unless the user asked for one. The
user installed this skill to have workers run on a cheaper model of the
same provider, so set it. Omitting it makes the child inherit you. That
standing request stops at the provider boundary and at any instruction
the user gave in this session.

Read the reference for your tool before the first spawn and follow it:

- OpenCode's `subagent`: `references/opencode.md`
- Claude Code's `Agent`: `references/claude-code.md`

Pick the child by the slice:

- Read-only search: the read-only explorer, if this session has one.
- Edits or commands: the general worker.

Foreground when the next decision needs the result. Background when the
slice is independent and you can keep working. Do not poll. Accept when
the result is actually in front of you. A notification that says "done"
is not the report. If the report is missing, continue that child and ask
for it.

Send independent slices together. Cap in-flight workers at four.
Acceptance is yours and serial. Past four, review costs the savings.

Keep this note in the conversation, not in the repo:

```
handle | lane | model | goal | waiting | accepted | taken back
```

After compaction, recover a missing handle from the spawn result. A new
child is not how you find the old one.

Done when: each dispatched slice has a resume handle, a model id, and a
lane, or you kept it.

### 5. Supervise

The worker is a correspondent, not a batch job. Stay on the same child.
A new child is a stranger: it repeats the mistake and re-reads the files
you already paid for.

Read the report against the brief, not against how hard the worker tried.
Accept only if Done when is met and Evidence is quoted tool output. For a
load-bearing claim (a test passed, a file was written, a behavior
changed), re-run or re-read it yourself before you accept. A quote can be
stale, truncated, or from the wrong command.

Read the diff before you accept an edit. Extra files, drive-by cleanup,
and a new abstraction are a failed Out, even when the proof passed.

If you do not accept, send one of these, and nothing else:

- **Answer.** It blocked on one fact. Send the fact. If the answer is a
  judgment you have not made, make it first, then send the decision or
  take the slice back.
- **Correct.** Quote the failed criterion from the brief, give the
  specific fix, and say what to leave alone. "Try again" is not a
  correction.
- **Stop.** You are taking the slice back. Tell that child to stop and
  change nothing further. Do not invent a cancel API. If you cannot stop
  it, leave its Files untouched until it returns, then revert what you
  did not accept.

Two corrections. The first fixes a miss. The second fixes a
misunderstanding. After the second failure, take the work back. A third
message is you avoiding the slice.

If you dispatch again after a take-back, change the brief. The same brief
to a new child is the same failure.

**Extend** only after accept, and only for the next dependent slice.
Restate Goal, Done when, Out, and Files. Do not assume it kept the old
Out.

When you take a slice back, revert out-of-scope edits yourself before you
continue. You own the tree.

Done when: you have accepted on evidence you checked, or you have taken
the slice back and the tree matches what you intend.

### 6. Integrate

You merge accepted slices. You resolve conflicts. A worker's summary is
not your finding. Do not pass an unaccepted claim to the user.

Tell the user what landed, what you rejected, and what you took back. One
short line per slice, in their language.

Done when: every slice is accepted, taken back, or still in flight with a
resume handle, and the user-facing result does not rest on an unaccepted
claim.

## While a worker is in flight

Keep doing keep-slices. Do not edit a path in a worker's Files list, and
do not put a second worker on those paths.

When a worker returns, accept or correct before you build on its result.

## Talking to the user

On dispatch, one line: the slice, the model, the lane.

Do not ask permission per slice. Ask only if they told you to ask, if you
are about to spawn a model as expensive as yourself, if the worker would
run on another provider, or if the slice writes outside the task they
gave you.

At the end, name the model each slice ran on.

If they say to do it yourself, or they pin a model for the whole task,
this skill yields.
