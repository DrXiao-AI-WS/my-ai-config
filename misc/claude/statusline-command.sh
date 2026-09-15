#!/bin/bash
# Claude Code status line: Model / Context / Rate Limit / Cost
# Reads the status line JSON payload from stdin.

input=$(cat)

# --- Model ---
model_name=$(echo "$input" | jq -r '.model.display_name // "unknown"')
effort=$(echo "$input" | jq -r '.effort.level // empty')
thinking=$(echo "$input" | jq -r 'if .thinking.enabled == true then "thinking" else empty end')

# --- Context ---
ctx_used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
ctx_size=$(echo "$input" | jq -r '.context_window.context_window_size // empty')
ctx_in=$(echo "$input" | jq -r '.context_window.total_input_tokens // empty')
ctx_out=$(echo "$input" | jq -r '.context_window.total_output_tokens // empty')

# --- Rate limits ---
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_reset_at=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
week_reset_at=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

# Format seconds remaining until a given epoch as "Xd Yh Zm" (only non-zero, largest units first)
format_remaining() {
  local reset_at="$1"
  [ -z "$reset_at" ] && return
  local now remaining
  now=$(date +%s)
  remaining=$(( reset_at - now ))
  [ "$remaining" -le 0 ] && { echo "now"; return; }
  local days=$(( remaining / 86400 ))
  local hours=$(( (remaining % 86400) / 3600 ))
  local mins=$(( (remaining % 3600) / 60 ))
  local out=""
  [ "$days" -gt 0 ] && out="${out}${days}d"
  [ "$hours" -gt 0 ] && out="${out}${out:+ }${hours}h"
  [ "$days" -eq 0 ] && [ "$mins" -gt 0 ] && out="${out}${out:+ }${mins}m"
  [ -z "$out" ] && out="<1m"
  echo "$out"
}

five_remaining=$(format_remaining "$five_reset_at")
week_remaining=$(format_remaining "$week_reset_at")

# --- Cost (present in some Claude Code versions; skipped gracefully if absent) ---
cost_usd=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
lines_add=$(echo "$input" | jq -r '.cost.total_lines_added // empty')
lines_del=$(echo "$input" | jq -r '.cost.total_lines_removed // empty')
dur_ms=$(echo "$input" | jq -r '.cost.total_duration_ms // empty')

# --- Colors ---
RESET='\033[0m'
CYAN='\033[36m'
YELLOW='\033[33m'
GREEN='\033[32m'
MAGENTA='\033[35m'

# --- Label alignment ---
# Widest label is "RateLimit:" (10 chars); pad every label to that width
# so values start in the same column on every line.
LABEL_WIDTH=10
pad_label() { printf '%-*s' "$LABEL_WIDTH" "$1"; }

# --- Build Model segment ---
model_seg="${CYAN}$(pad_label 'Model:')${RESET} ${model_name}"
[ -n "$effort" ] && model_seg="${model_seg} (${effort})"
[ -n "$thinking" ] && model_seg="${model_seg} [${thinking}]"

# --- Build Context segment ---
if [ -n "$ctx_used" ]; then
  ctx_seg="${YELLOW}$(pad_label 'Context:')${RESET} $(printf '%-3.0f' "$ctx_used")% used"
  if [ -n "$ctx_in" ] && [ -n "$ctx_out" ]; then
    ctx_seg="${ctx_seg} (in: ${ctx_in} out: ${ctx_out}"
    [ -n "$ctx_size" ] && ctx_seg="${ctx_seg}/${ctx_size}"
    ctx_seg="${ctx_seg})"
  fi
else
  ctx_seg="${YELLOW}$(pad_label 'Context:')${RESET} n/a"
fi

# --- Build Rate Limit segment ---
rl_seg=""
if [ -n "$five_pct" ] || [ -n "$week_pct" ]; then
  rl_seg="${GREEN}$(pad_label 'RateLimit:')${RESET}"
  if [ -n "$five_pct" ]; then
    rl_seg="${rl_seg} 5h:$(printf '%3.0f' "$five_pct")%"
    [ -n "$five_remaining" ] && rl_seg="${rl_seg} (resets in ${five_remaining})"
  fi
  if [ -n "$week_pct" ]; then
    rl_seg="${rl_seg}  7d:$(printf '%3.0f' "$week_pct")%"
    [ -n "$week_remaining" ] && rl_seg="${rl_seg} (resets in ${week_remaining})"
  fi
fi

# --- Build Cost segment ---
cost_seg=""
if [ -n "$cost_usd" ]; then
  cost_seg="${MAGENTA}$(pad_label 'Cost:')${RESET} \$$(printf '%.4f' "$cost_usd")"
  if [ -n "$lines_add" ] && [ -n "$lines_del" ]; then
    cost_seg="${cost_seg} (+${lines_add}/-${lines_del})"
  fi
  if [ -n "$dur_ms" ]; then
    dur_s=$(( dur_ms / 1000 ))
    cost_seg="${cost_seg} ${dur_s}s"
  fi
fi

out="${model_seg}\n${ctx_seg}"
[ -n "$rl_seg" ] && out="${out}\n${rl_seg}"
[ -n "$cost_seg" ] && out="${out}\n${cost_seg}"

printf "%b" "${out}"
