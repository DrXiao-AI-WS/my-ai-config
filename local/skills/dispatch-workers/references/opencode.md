# OpenCode dispatch

Read this only when the child-session tool in this session is `subagent`.
Field names here are for that tool. Do not send them to a different one.

## Spawn

Call `subagent` with:

- `agent`: `explore` for read-only search. `general` for edits or
  commands. `general` cannot spawn its own workers. Do not ask it to.
- `model`: `provider/model` or `provider/model#variant`, from a lookup in
  this session. Always set it. Omitting it makes the child inherit your
  model.
- `prompt`: the brief, in full. The child does not see this conversation.
- `description`: a short label for the slice.
- `background`: true only for an independent slice you do not need before
  the next decision.

The tool description may say not to set `model` unless the user named one.
This skill is that instruction. Set it.

## Lookup

Look up ids with the models tool. Inside code mode that is
`tools.opencode.models`. Do not pass a name you remember.

Use the returned `id` and only a variant that appears in that model's
`variants` list. `low` and `medium` are not on every model. An unknown
variant fails the spawn. If `variants` is empty, pass the id with no
variant.

Skip `deprecated`. Skip a model whose name marks it as embedding or
image-only. Price is input plus output on the matching tier.

Filter the lookup to your own provider first. If it has no cheaper
tool-capable model, ask the user before using another provider.

## Continue

The spawn returns a session id. Pass it as `sessionID` to answer, correct,
extend, or stop that same child.

Put the new fact or the failed criterion in that message. Do not restate
the whole brief unless the child has lost the plot.

A new spawn is a new stranger. Use one when the child is stuck in a bad
frame, not when it is merely wrong. Change the brief if you do.

## After it returns

A background child notifies you when it finishes. The resume handle is the
session id from the spawn. Apply the supervise step to its final message.
The notification itself is not the report, and it is not evidence.
