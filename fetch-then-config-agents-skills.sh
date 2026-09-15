#!/usr/bin/env bash
#
# fetch-then-config-agents-skills.sh — Clone/update a built-in list of
# public "agents & skills" repos into ./source, then scan that tree and
# (re)create symbolic links to the agents/skills it contains under
# ~/.agents/agents and ~/.agents/skills. Finally, expose those two
# directories to other AI coding tools (Claude, Codex, Copilot, OpenCode,
# Google Antigravity) via symlinks so this directory is the single source
# of truth.
#
# Detection is content-based rather than name-based, so it works no matter
# how deeply agents/skills are nested inside a cloned repository:
#   - Agent   = a *.md file that lives directly inside a directory named
#               "agents" (this skips per-skill "agents" metadata folders
#               that only hold non-agent files, e.g. openai.yaml).
#   - Skill   = any directory that directly contains a SKILL.md file.
#
# ~/.agents itself is (re)linked to point at the directory this script
# lives in, whatever that repo checkout happens to be named, so this repo
# is the single source of truth on disk and not just for the aggregated
# agents/skills below it.
#
# Usage: fetch-then-config-agents-skills.sh [source_dir]
#   source_dir defaults to ~/.agents/source

set -euo pipefail

# Directory this script lives in (i.e. this repo checkout), regardless of
# what it's named or where it was cloned.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

AIWS_DIR="$HOME/.agents"
SOURCE_DIR="${1:-$AIWS_DIR/source}"
AGENTS_DIR="$AIWS_DIR/agents"
SKILLS_DIR="$AIWS_DIR/skills"

# Ensure ~/.agents is a symlink to this repo (idempotent, non-destructive).
link_agents_home() {
  if [[ -e "$AIWS_DIR" || -L "$AIWS_DIR" ]] \
    && [[ "$(realpath -m "$AIWS_DIR")" == "$SCRIPT_DIR" ]]; then
    return # already this repo, or already correctly linked to it
  fi

  if [[ -L "$AIWS_DIR" ]]; then
    echo "Relinking $AIWS_DIR -> $SCRIPT_DIR (was $(readlink -- "$AIWS_DIR"))"
    ln -sfn "$SCRIPT_DIR" "$AIWS_DIR"
  elif [[ -d "$AIWS_DIR" ]]; then
    if [[ -z "$(ls -A "$AIWS_DIR" 2>/dev/null)" ]]; then
      rmdir "$AIWS_DIR"
      ln -s "$SCRIPT_DIR" "$AIWS_DIR"
      echo "Linked $AIWS_DIR -> $SCRIPT_DIR"
    else
      echo "Error: $AIWS_DIR exists and is not this repo. Move or remove" >&2
      echo "it manually, then re-run this script." >&2
      exit 1
    fi
  elif [[ -e "$AIWS_DIR" ]]; then
    echo "Error: $AIWS_DIR exists and is not a directory. Remove it" >&2
    echo "manually, then re-run this script." >&2
    exit 1
  else
    ln -s "$SCRIPT_DIR" "$AIWS_DIR"
    echo "Linked $AIWS_DIR -> $SCRIPT_DIR"
  fi
}

link_agents_home

# Built-in list of public repos containing agents/skills to aggregate.
SOURCE_REPOS=(
  "https://github.com/addyosmani/agent-skills.git"
  "https://github.com/mattpocock/skills.git"
)

# Clone a repo into $SOURCE_DIR (named after its basename) if it isn't
# there yet; otherwise fetch and fast-forward the existing clone.
sync_repo() {
  local url="$1" name dest branch
  name="$(basename "$url" .git)"
  dest="$SOURCE_DIR/$name"
  if [[ -d "$dest/.git" ]]; then
    echo "Updating $name..."
    git -C "$dest" fetch --quiet origin
    branch="$(git -C "$dest" symbolic-ref --short refs/remotes/origin/HEAD | sed 's#^origin/##')"
    git -C "$dest" checkout --quiet "$branch"
    git -C "$dest" merge --ff-only --quiet "origin/$branch"
  else
    echo "Cloning $name..."
    git clone --quiet "$url" "$dest"
  fi
}

mkdir -p "$SOURCE_DIR"
for url in "${SOURCE_REPOS[@]}"; do
  sync_repo "$url"
done

if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "Error: source directory not found: $SOURCE_DIR" >&2
  echo "Usage: $0 [source_dir]" >&2
  exit 1
fi

SOURCE_DIR="$(realpath -m "$SOURCE_DIR")"
mkdir -p "$AGENTS_DIR" "$SKILLS_DIR"

# Drop stale symlinks left over from previous runs whose source no longer
# exists, so removed/renamed agents and skills don't linger.
find "$AGENTS_DIR" "$SKILLS_DIR" -maxdepth 1 -xtype l -delete

# Create (or refresh) a relative symlink named $3 inside directory $2,
# pointing at $1. Warns if a differing link/entry with the same name
# already exists (name collision between two source repos).
link_into() {
  local target="$1" link_dir="$2" name="$3" dest rel
  dest="$link_dir/$name"
  rel="$(realpath --relative-to="$link_dir" "$target")"
  if [[ -e "$dest" || -L "$dest" ]] && [[ "$(readlink -- "$dest" 2>/dev/null || true)" != "$rel" ]]; then
    echo "Warning: '$name' already exists in $link_dir, overwriting with $target" >&2
  fi
  ln -sfn "$rel" "$dest"
}

agent_count=0
while IFS= read -r -d '' agents_dir; do
  while IFS= read -r -d '' agent_md; do
    name="$(basename "$agent_md")"
    link_into "$agent_md" "$AGENTS_DIR" "$name"
    echo "Found agent: $name (in $agents_dir)"
    agent_count=$((agent_count + 1))
  done < <(find "$agents_dir" -maxdepth 1 -type f -name '*.md' -print0 | sort -z)
done < <(find "$SOURCE_DIR" -type d -name agents -print0 | sort -z)

skill_count=0
while IFS= read -r -d '' skill_md; do
  skill_dir="$(dirname "$skill_md")"
  name="$(basename "$skill_dir")"
  link_into "$skill_dir" "$SKILLS_DIR" "$name"
  echo "Found skill: $name (in $skill_dir)"
  skill_count=$((skill_count + 1))
done < <(find "$SOURCE_DIR" -type f -name 'SKILL.md' -print0 | sort -z)

echo "Linked $agent_count agent(s) into $AGENTS_DIR"
echo "Linked $skill_count skill(s) into $SKILLS_DIR"

# Expose the aggregated agents/skills directories to other AI coding
# tools via symlinks, so this repo stays the single source of truth
# instead of duplicating files per tool.
#   Claude      -> $CLAUDE_CONFIG_DIR/agents, $CLAUDE_CONFIG_DIR/skills
#                  (CLAUDE_CONFIG_DIR defaults to ~/.claude)
#   Codex       -> $CODEX_HOME/agents (CODEX_HOME defaults to ~/.codex)
#   Copilot     -> ~/.copilot/agents
#   OpenCode    -> ~/.config/opencode/agents
#   Antigravity -> ~/.gemini/config/agents, ~/.gemini/config/skills
CLAUDE_HOME_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
CODEX_HOME_DIR="${CODEX_HOME:-$HOME/.codex}"

external_links=(
  "$CLAUDE_HOME_DIR/agents|$AGENTS_DIR"
  "$CLAUDE_HOME_DIR/skills|$SKILLS_DIR"
  "$CODEX_HOME_DIR/agents|$AGENTS_DIR"
  "$HOME/.copilot/agents|$AGENTS_DIR"
  "$HOME/.config/opencode/agents|$AGENTS_DIR"
  "$HOME/.gemini/config/agents|$AGENTS_DIR"
  "$HOME/.gemini/config/skills|$SKILLS_DIR"
)

for entry in "${external_links[@]}"; do
  dest="${entry%%|*}"
  target="${entry##*|}"
  dest_dir="$(dirname "$dest")"
  name="$(basename "$dest")"
  mkdir -p "$dest_dir"
  link_into "$target" "$dest_dir" "$name"
  echo "Linked $dest -> $target"
done
