#!/usr/bin/env bash
#
# fetch-then-config-agents-skills.sh — Clone/update a built-in list of
# public "agents & skills" repos into ./source, then scan that tree plus
# this repo's own hand-authored ./local tree, and (re)create symbolic
# links to the agents/skills found in either under ~/.agents/agents and
# ~/.agents/skills. Finally, expose those two directories to other AI
# coding tools (Claude, Codex, Copilot, OpenCode, Google Antigravity) via
# symlinks so this directory is the single source of truth.
#
# Detection is content-based rather than name-based, so it works no matter
# how deeply agents/skills are nested inside a cloned repository:
#   - Agent   = a *.md file that lives directly inside a directory named
#               "agents" and opens with YAML frontmatter declaring a
#               "name:" (this skips per-skill "agents" metadata folders
#               that only hold non-agent files, e.g. openai.yaml, and
#               plain documentation that happens to sit under docs/agents).
#   - Skill   = any directory that directly contains a SKILL.md file.
# Directories named in EXCLUDE_DIRS (unfinished or retired upstream work,
# vendored dependencies) are never scanned. On a name collision the
# hand-authored ./local entry wins over a fetched one.
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
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)"

AIWS_DIR="$HOME/.agents"
SOURCE_DIR="${1:-$AIWS_DIR/source}"
AGENTS_DIR="$AIWS_DIR/agents"
SKILLS_DIR="$AIWS_DIR/skills"

# Hand-authored agents/skills tracked in this repo (as opposed to $SOURCE_DIR,
# which holds reproducible clones of external repos). Scanned as a second
# source root alongside $SOURCE_DIR so self-authored ones are aggregated the
# same way as fetched ones.
LOCAL_DIR="$SCRIPT_DIR/local"

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
mkdir -p "$AGENTS_DIR" "$SKILLS_DIR" "$LOCAL_DIR/agents" "$LOCAL_DIR/skills"

# Directory names never descended into while scanning: VCS metadata,
# vendored dependencies, and upstream work that is unfinished or retired.
EXCLUDE_DIRS=(.git node_modules in-progress deprecated)

# Print, NUL-delimited and sorted, every path under root $1 matching the
# remaining find(1) arguments, skipping anything below an EXCLUDE_DIRS
# directory.
scan() {
  local root="$1" dir
  shift
  local prune=()
  for dir in "${EXCLUDE_DIRS[@]}"; do
    prune+=(-o -name "$dir")
  done
  find "$root" -type d \( "${prune[@]:1}" \) -prune -o "$@" -print0 | sort -z
}

# Create (or refresh) a relative symlink named $3 inside directory $2,
# pointing at $1. Warns when it replaces a link to a different target
# (name collision between two sources), and refuses to touch anything
# that is not a symlink: "ln -sfn" would silently create the link inside
# an existing real directory instead of replacing it.
link_into() {
  local target="$1" link_dir="$2" name="$3" dest rel
  dest="$link_dir/$name"
  rel="$(realpath --relative-to="$link_dir" "$target")"
  if [[ -L "$dest" ]]; then
    if [[ "$(readlink -- "$dest")" != "$rel" ]]; then
      echo "Warning: '$name' in $link_dir now points at $target" >&2
    fi
  elif [[ -e "$dest" ]]; then
    echo "Error: $dest exists and is not a symlink. Move or remove it" >&2
    echo "manually, then re-run this script." >&2
    return 1
  fi
  ln -sfn "$rel" "$dest"
}

# Succeed if file $1 opens with a YAML frontmatter block that declares a
# "name:" key, which every agent definition does and plain docs do not.
is_agent_file() {
  awk '
    NR == 1 { if ($0 !~ /^---[[:space:]]*$/) exit 1; next }
    /^---[[:space:]]*$/ { exit 1 }
    /^name:[[:space:]]*[^[:space:]]/ { found = 1; exit 0 }
    END { if (!found) exit 1 }
  ' "$1"
}

# Record target $3 as the source for name $2 in the associative array
# named $1, noting when it replaces an earlier source of the same name.
choose() {
  local -n chosen="$1"
  local name="$2" target="$3"
  if [[ -n "${chosen[$name]:-}" ]]; then
    echo "Note: '$name' from $target overrides ${chosen[$name]}" >&2
  fi
  chosen[$name]="$target"
}

# Link every name -> target pair of the associative array named $2 into
# directory $1, then remove any other symlink found there, so agents and
# skills that were removed, renamed, or newly excluded don't linger.
# Non-symlink entries are left alone.
sync_links() {
  local link_dir="$1" name link
  local -n wanted="$2"
  while IFS= read -r -d '' name; do
    link_into "${wanted[$name]}" "$link_dir" "$name"
  done < <(printf '%s\0' "${!wanted[@]}" | sort -z)
  while IFS= read -r -d '' link; do
    if [[ -z "${wanted[$(basename "$link")]:-}" ]]; then
      echo "Removing stale link: $link"
      rm -- "$link"
    fi
  done < <(find "$link_dir" -maxdepth 1 -type l -print0)
}

# Fetched repos are scanned first and ./local last, so a hand-authored
# agent or skill replaces a fetched one of the same name.
declare -A agent_targets=() skill_targets=()
for root in "$SOURCE_DIR" "$LOCAL_DIR"; do
  while IFS= read -r -d '' agents_dir; do
    while IFS= read -r -d '' agent_md; do
      if ! is_agent_file "$agent_md"; then
        echo "Skipping non-agent file: $agent_md"
        continue
      fi
      choose agent_targets "$(basename "$agent_md")" "$agent_md"
    done < <(find "$agents_dir" -maxdepth 1 -type f -name '*.md' -print0 | sort -z)
  done < <(scan "$root" -type d -name agents)

  while IFS= read -r -d '' skill_md; do
    skill_dir="$(dirname "$skill_md")"
    choose skill_targets "$(basename "$skill_dir")" "$skill_dir"
  done < <(scan "$root" -type f -name 'SKILL.md')
done

sync_links "$AGENTS_DIR" agent_targets
sync_links "$SKILLS_DIR" skill_targets

echo "Linked ${#agent_targets[@]} agent(s) into $AGENTS_DIR"
echo "Linked ${#skill_targets[@]} skill(s) into $SKILLS_DIR"

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
