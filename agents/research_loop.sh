#!/usr/bin/env bash
set -euo pipefail

# Foreground research loop (local runner).
#
# This script drains idea-state queues (raw -> articulated -> staging -> specs),
# then runs Taskmaster/Taskaudit to feed tasks into agents/tasksbacklog.md via
# agents/taskspending.md.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

resolve_repo_root() {
  local candidate
  for candidate in "$SCRIPT_DIR/.." "$SCRIPT_DIR/../../.."; do
    if [ -f "$candidate/agents/_orchestrate.md" ]; then
      (cd "$candidate" && pwd -P)
      return 0
    fi
  done
  (cd "$SCRIPT_DIR/.." && pwd -P)
}

REPO_ROOT="$(resolve_repo_root)"
cd "$REPO_ROOT"

RAW_DIR="agents/ideas/raw"
ARTICULATED_DIR="agents/ideas/articulated"
STAGING_DIR="agents/ideas/staging"
QUEUE_SPECS_DIR="agents/ideas/specs"
RESEARCH_STATUS="agents/research_status.md"
MODEL_CFG="agents/options/model_config.md"
WF_CFG="agents/options/workflow_config.md"
RUNS_DIR="agents/runs/research"

IDEA_DEBOUNCE_SECS="${IDEA_DEBOUNCE_SECS:-120}"
RESEARCH_POLL_SECS="${RESEARCH_POLL_SECS:-60}"
HEARTBEAT_SECS="${HEARTBEAT_SECS:-60}"
MODE="forever"

TIMEOUT_BIN="timeout"
IDLE_WATCH_TOOL=""

trim() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

log() {
  local ts
  ts="$(date '+%F %T')"
  printf '[%s] %s\n' "$ts" "$*" >&2
}

ensure_repo_root() {
  cd "$REPO_ROOT" 2>/dev/null || {
    echo "FATAL: unable to cd to repo root: $REPO_ROOT" >&2
    exit 1
  }
}

require() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

write_research_status() {
  printf '%s\n' "$1" >"$RESEARCH_STATUS"
}

read_research_status() {
  if [ -f "$RESEARCH_STATUS" ]; then
    awk '/^### /{st=$0} END{if(st) print st; else print "### IDLE"}' "$RESEARCH_STATUS" | tr -d '\r'
  else
    echo "### IDLE"
  fi
}

stat_mtime() {
  local path="$1"
  if [ ! -e "$path" ]; then
    printf '0\n'
    return 0
  fi

  if stat -c %Y "$path" >/dev/null 2>&1; then
    stat -c %Y "$path"
    return 0
  fi
  if stat -f %m "$path" >/dev/null 2>&1; then
    stat -f %m "$path"
    return 0
  fi

  printf '0\n'
}

debounce_quiet_period() {
  local path="$1"
  local quiet="${2:-$IDEA_DEBOUNCE_SECS}"

  if ! [[ "$quiet" =~ ^[0-9]+$ ]]; then
    quiet=120
  fi
  if [ "$quiet" -le 0 ]; then
    return 0
  fi

  local stable_for=0
  local prev now
  prev="$(stat_mtime "$path")"

  while [ "$stable_for" -lt "$quiet" ]; do
    sleep 1
    now="$(stat_mtime "$path")"
    if [ "$now" = "$prev" ]; then
      stable_for=$(( stable_for + 1 ))
    else
      prev="$now"
      stable_for=0
    fi
  done
}

dir_has_payload_files() {
  local dir="$1"
  find "$dir" -maxdepth 1 -type f ! -name '.gitkeep' -print -quit | grep -q .
}

parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --once)
        MODE="once"
        ;;
      --forever)
        MODE="forever"
        ;;
      -h|--help)
        cat <<USAGE
Usage: bash agents/research_loop.sh [--once|--forever]

Options:
  --once     Run at most one stage then exit.
  --forever  Run continuously (default).

Environment:
  IDEA_DEBOUNCE_SECS (default: 120)
  RESEARCH_POLL_SECS (default: 60)
USAGE
        exit 0
        ;;
      *)
        echo "Unknown argument: $1" >&2
        exit 1
        ;;
    esac
    shift
  done
}

parse_model_config() {
  local in_active=0 line key value

  while IFS= read -r line || [ -n "$line" ]; do
    if [ "$in_active" -eq 0 ]; then
      case "$line" in "## Active config"*) in_active=1 ;; esac
      continue
    fi

    case "$line" in ---) break ;; esac

    if [[ "$line" =~ ^[[:space:]]*([A-Z0-9_]+)[[:space:]]*=[[:space:]]*(.*)$ ]]; then
      key="${BASH_REMATCH[1]}"
      value="$(trim "${BASH_REMATCH[2]}")"
      case "$key" in
        BUILDER_RUNNER) BUILDER_RUNNER="$value" ;;
        BUILDER_MODEL) BUILDER_MODEL="$value" ;;
        ARTICULATE_RUNNER) ARTICULATE_RUNNER="$value" ;;
        ARTICULATE_MODEL) ARTICULATE_MODEL="$value" ;;
        ARTICULATE_EFFORT) ARTICULATE_EFFORT="$value" ;;
        ANALYZE_RUNNER) ANALYZE_RUNNER="$value" ;;
        ANALYZE_MODEL) ANALYZE_MODEL="$value" ;;
        ANALYZE_EFFORT) ANALYZE_EFFORT="$value" ;;
        CLARIFY_RUNNER) CLARIFY_RUNNER="$value" ;;
        CLARIFY_MODEL) CLARIFY_MODEL="$value" ;;
        CLARIFY_EFFORT) CLARIFY_EFFORT="$value" ;;
        TASKMASTER_RUNNER) TASKMASTER_RUNNER="$value" ;;
        TASKMASTER_MODEL) TASKMASTER_MODEL="$value" ;;
        TASKMASTER_EFFORT) TASKMASTER_EFFORT="$value" ;;
        TASKAUDIT_RUNNER) TASKAUDIT_RUNNER="$value" ;;
        TASKAUDIT_MODEL) TASKAUDIT_MODEL="$value" ;;
        TASKAUDIT_EFFORT) TASKAUDIT_EFFORT="$value" ;;
        # Backward-compatible aliases.
        RESEARCH_RUNNER) RESEARCH_RUNNER="$value" ;;
        RESEARCH_MODEL) RESEARCH_MODEL="$value" ;;
        *) : ;;
      esac
    fi
  done <"$MODEL_CFG"

  local required=(BUILDER_RUNNER BUILDER_MODEL)
  local k
  for k in "${required[@]}"; do
    if [ -z "${!k:-}" ]; then
      echo "Missing $k in $MODEL_CFG (Active config block)" >&2
      exit 1
    fi
  done

  : "${RESEARCH_RUNNER:=$BUILDER_RUNNER}"
  : "${RESEARCH_MODEL:=$BUILDER_MODEL}"

  : "${ARTICULATE_RUNNER:=$RESEARCH_RUNNER}"
  : "${ARTICULATE_MODEL:=$RESEARCH_MODEL}"
  : "${ARTICULATE_EFFORT:=high}"

  : "${ANALYZE_RUNNER:=$RESEARCH_RUNNER}"
  : "${ANALYZE_MODEL:=$RESEARCH_MODEL}"
  : "${ANALYZE_EFFORT:=high}"

  : "${CLARIFY_RUNNER:=$RESEARCH_RUNNER}"
  : "${CLARIFY_MODEL:=$RESEARCH_MODEL}"
  : "${CLARIFY_EFFORT:=xhigh}"

  : "${TASKMASTER_RUNNER:=$RESEARCH_RUNNER}"
  : "${TASKMASTER_MODEL:=$RESEARCH_MODEL}"
  : "${TASKMASTER_EFFORT:=xhigh}"

  : "${TASKAUDIT_RUNNER:=$RESEARCH_RUNNER}"
  : "${TASKAUDIT_MODEL:=$RESEARCH_MODEL}"
  : "${TASKAUDIT_EFFORT:=medium}"

  local runner_key
  for runner_key in ARTICULATE_RUNNER ANALYZE_RUNNER CLARIFY_RUNNER TASKMASTER_RUNNER TASKAUDIT_RUNNER; do
    case "${!runner_key}" in
      codex|claude|openclaw) ;;
      *)
        echo "Invalid $runner_key=${!runner_key} in $MODEL_CFG (expected codex|claude|openclaw)" >&2
        exit 1
        ;;
    esac
  done
}

parse_workflow_config() {
  local line key value
  while IFS= read -r line || [ -n "$line" ]; do
    if [[ "$line" =~ ^##[[:space:]]*([A-Z0-9_]+)[[:space:]]*=[[:space:]]*(.*)$ ]]; then
      key="${BASH_REMATCH[1]}"
      value="$(trim "${BASH_REMATCH[2]}")"
      case "$key" in
        HEADLESS_PERMISSIONS) HEADLESS_PERMISSIONS="$value" ;;
        OPENCLAW_GATEWAY_URL) OPENCLAW_GATEWAY_URL="$value" ;;
        OPENCLAW_AGENT_ID) OPENCLAW_AGENT_ID="$value" ;;
        *) : ;;
      esac
    fi
  done <"$WF_CFG"

  : "${HEADLESS_PERMISSIONS:=Maximum}"
  : "${OPENCLAW_GATEWAY_URL:=http://127.0.0.1:18789}"
  : "${OPENCLAW_AGENT_ID:=main}"
}

set_permission_flags() {
  case "${HEADLESS_PERMISSIONS:-Maximum}" in
    Normal)
      CODEX_PERM_FLAGS=(--full-auto)
      CLAUDE_PERM_FLAGS=()
      ;;
    Elevated)
      CODEX_PERM_FLAGS=(--full-auto --sandbox danger-full-access)
      CLAUDE_PERM_FLAGS=(--permission-mode acceptEdits)
      ;;
    Maximum)
      CODEX_PERM_FLAGS=(--dangerously-bypass-approvals-and-sandbox)
      CLAUDE_PERM_FLAGS=(--dangerously-skip-permissions)
      ;;
    *)
      echo "Unknown HEADLESS_PERMISSIONS: ${HEADLESS_PERMISSIONS}" >&2
      exit 1
      ;;
  esac
}

get_openclaw_token() {
  if [ -n "${OPENCLAW_GATEWAY_TOKEN:-}" ]; then
    printf '%s' "$OPENCLAW_GATEWAY_TOKEN"
    return 0
  fi
  if command -v openclaw >/dev/null 2>&1; then
    openclaw config get gateway.auth.token 2>/dev/null | tr -d '\r\n'
    return 0
  fi
  if command -v openclaw.exe >/dev/null 2>&1; then
    openclaw.exe config get gateway.auth.token 2>/dev/null | tr -d '\r\n'
    return 0
  fi
  return 1
}

openclaw_run() {
  local model="$1"
  local prompt="$2"
  local stdout_path="$3"
  local stderr_path="$4"
  local last_path="$5"

  local token
  token="$(get_openclaw_token)" || {
    echo "OpenClaw runner requested but no OPENCLAW_GATEWAY_TOKEN and openclaw/openclaw.exe not available" >&2
    return 1
  }

  local payload
  payload="$(python3 - "$model" "$prompt" "$OPENCLAW_AGENT_ID" <<'PY'
import json
import sys
print(json.dumps({
  "model": sys.argv[1],
  "input": [{"role": "user", "content": [{"type": "text", "text": sys.argv[2]}]}],
  "metadata": {"openclaw_agent_id": sys.argv[3]},
}))
PY
)"

  curl -sS -X POST "$OPENCLAW_GATEWAY_URL/v1/responses" \
    -H "Authorization: Bearer $token" \
    -H "Content-Type: application/json" \
    -d "$payload" \
    >"$stdout_path" 2>"$stderr_path"

  if [ -n "$last_path" ]; then
    python3 - "$stdout_path" "$last_path" <<'PY'
import json
import sys
src, dst = sys.argv[1], sys.argv[2]
try:
  data = json.load(open(src, 'r', encoding='utf-8'))
except Exception:
  raise SystemExit(0)
text = []
for item in data.get('output') or []:
  for part in item.get('content') or []:
    if part.get('type') == 'output_text' and isinstance(part.get('text'), str):
      text.append(part['text'])
if text:
  open(dst, 'w', encoding='utf-8').write("\n".join(text).strip() + "\n")
PY
  fi
}

run_cycle() {
  ensure_repo_root

  local runner="$1"
  local model="$2"
  local prompt="$3"
  local stdout_path="$4"
  local stderr_path="$5"
  local last_path="$6"
  local search="${7:-false}"
  local effort="${8:-high}"
  local label="${9:-Stage}"

  local code=0
  local search_flags=()
  if [ "$search" = "true" ]; then
    search_flags=(--search)
  fi

  local reasoning_flags=(-c "model_reasoning_effort=\"$effort\"")

  log "$label: runner=$runner model=$model effort=$effort search=$search"

  case "$runner" in
    codex)
      if [ -n "$last_path" ]; then
        "$TIMEOUT_BIN" 5400 codex "${search_flags[@]}" exec --model "$model" "${CODEX_PERM_FLAGS[@]}" \
          "${reasoning_flags[@]}" -o "$last_path" "$prompt" >"$stdout_path" 2>"$stderr_path" || code=$?
      else
        "$TIMEOUT_BIN" 5400 codex "${search_flags[@]}" exec --model "$model" "${CODEX_PERM_FLAGS[@]}" \
          "${reasoning_flags[@]}" "$prompt" >"$stdout_path" 2>"$stderr_path" || code=$?
      fi
      ;;
    claude)
      "$TIMEOUT_BIN" 5400 claude -p "$prompt" --model "$model" --output-format text "${CLAUDE_PERM_FLAGS[@]}" \
        >"$stdout_path" 2>"$stderr_path" || code=$?
      if [ -n "$last_path" ] && [ -f "$stdout_path" ]; then
        cp -f "$stdout_path" "$last_path" || true
      fi
      ;;
    openclaw)
      openclaw_run "$model" "$prompt" "$stdout_path" "$stderr_path" "$last_path" || code=$?
      ;;
    *)
      echo "Unknown runner: $runner (expected codex|claude|openclaw). Check $MODEL_CFG" >&2
      return 1
      ;;
  esac

  if [ "$code" -ne 0 ]; then
    log "$label: exit=$code"
    return "$code"
  fi
  log "$label: exit=0"
  return 0
}

run_cycle_with_fallback() {
  local runner="$1"
  local model_chain="$2"
  local effort_chain="$3"
  local prompt="$4"
  local stdout_path="$5"
  local stderr_path="$6"
  local last_path="$7"
  local search="${8:-false}"
  local default_effort="${9:-high}"
  local label="${10:-Stage}"

  local chain efforts_chain
  chain="$(trim "$model_chain")"
  efforts_chain="$(trim "$effort_chain")"
  [ -n "$chain" ] || return 1
  [ -n "$efforts_chain" ] || efforts_chain="$default_effort"

  local -a models=()
  local -a efforts=()
  IFS='|' read -r -a models <<< "$chain"
  IFS='|' read -r -a efforts <<< "$efforts_chain"

  local idx model effort exit_code=1 ran=0
  for idx in "${!models[@]}"; do
    model="$(trim "${models[$idx]}")"
    [ -n "$model" ] || continue

    effort="$default_effort"
    if [ "$idx" -lt "${#efforts[@]}" ]; then
      effort="$(trim "${efforts[$idx]}")"
    fi
    [ -n "$effort" ] || effort="$default_effort"

    ran=1
    if run_cycle "$runner" "$model" "$prompt" "$stdout_path" "$stderr_path" "$last_path" "$search" "$effort" "$label"; then
      return 0
    fi
    exit_code=$?

    if [ "$idx" -lt $(( ${#models[@]} - 1 )) ]; then
      log "$label: fallback to next model after failure on $model (exit=$exit_code)"
    fi
  done

  if [ "$ran" -eq 0 ]; then
    return 1
  fi
  return "$exit_code"
}

stage_runner_for() {
  local stage="$1"
  case "$stage" in
    articulate) printf '%s\n' "$ARTICULATE_RUNNER" ;;
    analyze) printf '%s\n' "$ANALYZE_RUNNER" ;;
    clarify) printf '%s\n' "$CLARIFY_RUNNER" ;;
    taskmaster) printf '%s\n' "$TASKMASTER_RUNNER" ;;
    taskaudit) printf '%s\n' "$TASKAUDIT_RUNNER" ;;
    *) return 1 ;;
  esac
}

stage_model_for() {
  local stage="$1"
  case "$stage" in
    articulate) printf '%s\n' "$ARTICULATE_MODEL" ;;
    analyze) printf '%s\n' "$ANALYZE_MODEL" ;;
    clarify) printf '%s\n' "$CLARIFY_MODEL" ;;
    taskmaster) printf '%s\n' "$TASKMASTER_MODEL" ;;
    taskaudit) printf '%s\n' "$TASKAUDIT_MODEL" ;;
    *) return 1 ;;
  esac
}

stage_effort_for() {
  local stage="$1"
  case "$stage" in
    articulate) printf '%s\n' "$ARTICULATE_EFFORT" ;;
    analyze) printf '%s\n' "$ANALYZE_EFFORT" ;;
    clarify) printf '%s\n' "$CLARIFY_EFFORT" ;;
    taskmaster) printf '%s\n' "$TASKMASTER_EFFORT" ;;
    taskaudit) printf '%s\n' "$TASKAUDIT_EFFORT" ;;
    *) return 1 ;;
  esac
}

stage_prompt_for() {
  local stage="$1"
  case "$stage" in
    articulate) printf '%s\n' "Open agents/_articulate.md and follow instructions." ;;
    analyze) printf '%s\n' "Open agents/_analyze.md and follow instructions." ;;
    clarify) printf '%s\n' "Open agents/_clarify.md and follow instructions." ;;
    taskmaster) printf '%s\n' "Open agents/_taskmaster.md and follow instructions." ;;
    taskaudit) printf '%s\n' "Open agents/_taskaudit.md and follow instructions." ;;
    *) return 1 ;;
  esac
}

STAGE_COUNTER=0

run_stage() {
  local stage="$1"
  local runner model prompt effort base stdout_path stderr_path last_path status

  runner="$(stage_runner_for "$stage")"
  model="$(stage_model_for "$stage")"
  effort="$(stage_effort_for "$stage")"
  prompt="$(stage_prompt_for "$stage")"

  STAGE_COUNTER=$(( STAGE_COUNTER + 1 ))
  base="$RUNS_DIR/$(date +%F_%H%M%S)_$(printf '%04d' "$STAGE_COUNTER")_${stage}"
  stdout_path="$base.stdout.log"
  stderr_path="$base.stderr.log"
  last_path="$base.last.md"

  if ! run_cycle_with_fallback "$runner" "$model" "$effort" "$prompt" "$stdout_path" "$stderr_path" "$last_path" false high "Research-$stage"; then
    write_research_status "### BLOCKED"
    log "Stage $stage failed (non-zero). Logs: $stdout_path $stderr_path"
    return 1
  fi

  status="$(read_research_status)"
  case "$status" in
    "### IDLE")
      return 0
      ;;
    "### BLOCKED")
      log "Stage $stage reported BLOCKED"
      return 1
      ;;
    *)
      log "Stage $stage left unexpected research status: $status"
      write_research_status "### BLOCKED"
      return 1
      ;;
  esac
}

wait_for_new_raw() {
  local poll="${RESEARCH_POLL_SECS:-60}"

  if ! [[ "$poll" =~ ^[0-9]+$ ]]; then
    poll=60
  fi
  if [ "$poll" -le 0 ]; then
    poll=60
  fi

  log "Idle: waiting for new files in $RAW_DIR"
  while ! dir_has_payload_files "$RAW_DIR"; do
    sleep "$poll"
  done

  log "New raw idea detected; debouncing for ${IDEA_DEBOUNCE_SECS}s"
  debounce_quiet_period "$RAW_DIR" "$IDEA_DEBOUNCE_SECS"
}

run_once() {
  if dir_has_payload_files "$RAW_DIR"; then
    run_stage articulate
    return
  fi

  if dir_has_payload_files "$ARTICULATED_DIR"; then
    run_stage analyze
    return
  fi

  if dir_has_payload_files "$STAGING_DIR"; then
    run_stage clarify
    return
  fi

  if dir_has_payload_files "$QUEUE_SPECS_DIR"; then
    run_stage taskmaster
    return
  fi

  run_stage taskaudit
}

run_forever() {
  while true; do
    while dir_has_payload_files "$RAW_DIR"; do
      run_stage articulate || exit 1
    done

    while dir_has_payload_files "$ARTICULATED_DIR"; do
      run_stage analyze || exit 1
    done

    while dir_has_payload_files "$STAGING_DIR"; do
      run_stage clarify || exit 1
    done

    if dir_has_payload_files "$QUEUE_SPECS_DIR"; then
      run_stage taskmaster || exit 1
    fi

    if ! dir_has_payload_files "$QUEUE_SPECS_DIR"; then
      run_stage taskaudit || exit 1
    fi

    wait_for_new_raw
  done
}

preflight() {
  require bash
  require python3

  if command -v timeout >/dev/null 2>&1; then
    TIMEOUT_BIN="timeout"
  elif command -v gtimeout >/dev/null 2>&1; then
    TIMEOUT_BIN="gtimeout"
  else
    echo "Missing required command: timeout (or gtimeout on macOS)" >&2
    exit 1
  fi

  [ -f "$MODEL_CFG" ] || { echo "Missing $MODEL_CFG" >&2; exit 1; }
  [ -f "$WF_CFG" ] || { echo "Missing $WF_CFG" >&2; exit 1; }

  mkdir -p "$RUNS_DIR"

  local p
  for p in "$RAW_DIR" "$ARTICULATED_DIR" "$STAGING_DIR" "$QUEUE_SPECS_DIR"; do
    [ -d "$p" ] || { echo "Missing required directory: $p" >&2; exit 1; }
  done

  parse_model_config
  parse_workflow_config
  set_permission_flags

  if [ ! -f "$RESEARCH_STATUS" ]; then
    write_research_status "### IDLE"
  fi

  log "Config: mode=$MODE debounce=${IDEA_DEBOUNCE_SECS}s poll=${RESEARCH_POLL_SECS}s"
  log "Config: articulate=$ARTICULATE_RUNNER/$ARTICULATE_MODEL effort=$ARTICULATE_EFFORT"
  log "Config: analyze=$ANALYZE_RUNNER/$ANALYZE_MODEL effort=$ANALYZE_EFFORT"
  log "Config: clarify=$CLARIFY_RUNNER/$CLARIFY_MODEL effort=$CLARIFY_EFFORT"
  log "Config: taskmaster=$TASKMASTER_RUNNER/$TASKMASTER_MODEL effort=$TASKMASTER_EFFORT"
  log "Config: taskaudit=$TASKAUDIT_RUNNER/$TASKAUDIT_MODEL effort=$TASKAUDIT_EFFORT"
}

parse_args "$@"
preflight

if [ "$MODE" = "once" ]; then
  run_once
else
  run_forever
fi
