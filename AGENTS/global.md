# Global preferences
- All code, identifiers, comments, docstrings, commit messages, and log messages
  MUST be written in English.
- If the repository-level AGENTS.md file exists, follow its instructions for
  agent usage.
- When performing "git commit", notice that the changes should be split into
  multiple commits if they are logically separate.
- When an AI coding agent substantially authors a commit (i.e., produces
  most of the code changes or drives the implementation), append the
  Co-authored-by trailer matching the agent currently executing this
  task. Determine the agent identity from the current execution context
  before committing.

  - Claude Code:
    Co-authored-by: Claude <noreply@anthropic.com>
  - OpenAI Codex:
    Co-authored-by: Codex <noreply@openai.com>
  - OpenCode:
    Co-authored-by: opencode <noreply@opencode.ai>
  - GitHub Copilot:
    Co-authored-by: Copilot <copilot@github.com>
  - Any other agent not listed above: omit the trailer unless the user
    specifies one.

  If both human contributors and an AI agent contributed to the same
  commit, list human Co-authored-by lines first, followed by the agent's.

  If the coding agent is Claude Code, it is not necessary to include the
  "Co-authored-by <model name>" line and the Claude session ID in the commit
  message.

- Git commit principle
  1. [MUST] Separate subject from body with a blank line
  2. [MUST] Limit the subject line to 50 characters if possible
            The acceptable maximum is 72 characters
  3. [MUST] Capitalize the subject line
  4. [MUST] Do not end the subject line with a period
  5. [MUST] Use the imperative mood in the subject line
  6. [MUST] Wrap the body at 72 characters
  7. [MUST] Use the body to explain what and why vs. how
