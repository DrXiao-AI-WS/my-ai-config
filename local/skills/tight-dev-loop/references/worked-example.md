# Worked example

Imitate the shape, not the files. Task: add `--json` to a CLI that already
has `--verbose`.

Card before the first edit:

```
Goal:      cmd --json prints a JSON object
Done when: go test ./cmd -run TestJSON passes
Out:       do not change the text output of other flags
Neighbor:  cmd/root.go:verboseFlag, cmd/root_test.go:TestVerbose
Slice:     add TestJSON that expects a JSON object and fails
Proof:     go test ./cmd -run TestJSON
Files:     cmd/root_test.go
Green:     none
Left:      wire the flag the way verboseFlag is wired
```

Execution:

1. Change is the test only. Prove goes red for a missing flag. Quote the
   `FAIL` line into `Green`.
2. The next slice sets `Files` to `cmd/root.go` and copies `verboseFlag`.
   Prove goes green. Quote the `ok` line into `Green`.
3. `Left` is none. Stop. Do not also reformat the CLI.

One behavior per slice, the neighbor copied exactly, every green backed
by a quoted tool line, and a stop at `Done when`.

# Excuses and what is true

| Excuse | Reality |
|---|---|
| "I know this codebase, I can skip Orient." | Memory is not evidence. Read the neighbor in this session or mark it `unknown`. |
| "I will test everything at the end." | A bug in slice 1 makes slices 2 to 5 wrong. Prove each slice before the next edit. |
| "This small cleanup belongs in the same edit." | Mixed concerns hide bugs and blur the proof signal. Note it, do not touch it. |
| "The test command is probably `npm test`." | Probably is `unknown`. Find the command in the repository. |
| "It should pass now." | Should is `none`. Run the proof and quote the line. |
| "One more file for completeness." | Completeness after `Done when` is scope creep. Stop. |
