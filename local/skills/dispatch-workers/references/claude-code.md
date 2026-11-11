# Claude Code dispatch

Read this only when the child-session tool in this session is `Agent`.
Field names here are for that tool. If the schema in this session
differs, the schema wins.

## Spawn

Call `Agent` with:

- `subagent_type`: the read-only search agent (`Explore`) for a hand
  slice that only reads. The general-purpose agent for edits or
  commands. Use only a type this session lists.
- `model`: one of the aliases the schema lists. Always set it. Omitting
  it makes the child inherit your model.
- `effort`: `lower` for a hand slice. Omit it for craft.
- `prompt`: the brief, in full. The child does not see this
  conversation.
- `description`: a short label for the slice.

## Lookup

There is no models tool and no cross-provider choice. The `model` enum
in the tool schema is the whole list, and every entry is on your
provider.

- **Hand:** the smallest alias listed.
- **Craft:** the next alias up, if it is still below your own model.

There are no variants. `effort` is the only intensity control.

If you are already the smallest alias, keep the work.

## Continue

The spawn result carries an agent id or name. Send answer, correct,
extend, or stop to that same child with `SendMessage`. A second `Agent`
call is a new stranger.

## After it returns

Children run in the background and you are notified when one finishes.
Do not poll, and do not write the result yourself while you wait. Apply
the supervise step to the child's final report. The notification itself
is not evidence.

If the session's own instructions say to spawn agents only when the user
asks, that wins: dispatch only after the user asked to delegate, fan
out, or save cost.
