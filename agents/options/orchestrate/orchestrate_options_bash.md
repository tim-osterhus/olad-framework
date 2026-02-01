# Orchestrator Options (Bash/WSL Templates)

This document is a copy/paste scratchpad for running OLAD cycles headlessly from a WSL/Linux shell.

It is intentionally kept out of `agents/_orchestrate.md` to keep the Runner entrypoint small.

## Assumptions

- You are running from the repo root (the directory containing `agents/`).
- You have the CLIs you plan to use installed:
  - `codex` (Codex CLI)
  - `claude` (Claude Code CLI), if used
  - Optional (OpenClaw runner): `curl` + `python3` and either:
    - `openclaw`/`openclaw.exe` available on PATH (to read the Gateway token), OR
    - `OPENCLAW_GATEWAY_TOKEN` exported in your shell
  - OpenClaw runner requires the Gateway `/v1/responses` endpoint enabled (see `agents/options/openclaw/runner_integration_bash.md`)

## Create a run folder + run a cycle (bash)

```bash
RUN_ID="$(date +%F_%H%M%S)"
RUN_DIR="agents/runs/$RUN_ID"
mkdir -p "$RUN_DIR"

trim() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"  # leading
  s="${s%"${s##*[![:space:]]}"}"  # trailing
  printf '%s' "$s"
}

parse_model_config() {
  local in_active=0
  local line key value

  while IFS= read -r line || [ -n "$line" ]; do
    if [ "$in_active" -eq 0 ]; then
      case "$line" in
        "## Active config"*) in_active=1 ;;
      esac
      continue
    fi

    case "$line" in
      ---) break ;;
    esac

    if [[ "$line" =~ ^[[:space:]]*([A-Z0-9_]+)[[:space:]]*=[[:space:]]*(.*)$ ]]; then
      key="${BASH_REMATCH[1]}"
      value="$(trim "${BASH_REMATCH[2]}")"

      case "$key" in
        INTEGRATION_RUNNER) INTEGRATION_RUNNER="$value" ;;
        INTEGRATION_MODEL) INTEGRATION_MODEL="$value" ;;
        BUILDER_RUNNER) BUILDER_RUNNER="$value" ;;
        BUILDER_MODEL) BUILDER_MODEL="$value" ;;
        QA_RUNNER) QA_RUNNER="$value" ;;
        QA_MODEL) QA_MODEL="$value" ;;
        HOTFIX_RUNNER) HOTFIX_RUNNER="$value" ;;
        HOTFIX_MODEL) HOTFIX_MODEL="$value" ;;
        DOUBLECHECK_RUNNER) DOUBLECHECK_RUNNER="$value" ;;
        DOUBLECHECK_MODEL) DOUBLECHECK_MODEL="$value" ;;
        *) echo "Unknown key in model_config: $key" >&2; return 1 ;;
      esac
    fi
  done < "agents/options/model_config.md"

  local required=(BUILDER_RUNNER BUILDER_MODEL QA_RUNNER QA_MODEL HOTFIX_RUNNER HOTFIX_MODEL DOUBLECHECK_RUNNER DOUBLECHECK_MODEL)
  for k in "${required[@]}"; do
    if [ -z "${!k:-}" ]; then
      echo "Missing $k in Active config block" >&2
      return 1
    fi
  done
}

parse_workflow_config() {
  local line key value

  while IFS= read -r line || [ -n "$line" ]; do
    if [[ "$line" =~ ^##[[:space:]]*([A-Z0-9_]+)[[:space:]]*=[[:space:]]*(.*)$ ]]; then
      key="${BASH_REMATCH[1]}"
      value="$(trim "${BASH_REMATCH[2]}")"

      case "$key" in
        INITIALIZED) INITIALIZED="$value" ;;
        INTEGRATION_MODE) INTEGRATION_MODE="$value" ;;
        INTEGRATION_COUNT) INTEGRATION_COUNT="$value" ;;
        INTEGRATION_TARGET) INTEGRATION_TARGET="$value" ;;
        HEADLESS_PERMISSIONS) HEADLESS_PERMISSIONS="$value" ;;
        SHELL_TEMPLATES) SHELL_TEMPLATES="$value" ;;
        OPENCLAW_MODE) OPENCLAW_MODE="$value" ;;
        OPENCLAW_GATEWAY_URL) OPENCLAW_GATEWAY_URL="$value" ;;
        OPENCLAW_AGENT_ID) OPENCLAW_AGENT_ID="$value" ;;
        *) echo "Unknown key in workflow_config: $key" >&2; return 1 ;;
      esac
    fi
  done < "agents/options/workflow_config.md"

  if [ -z "${HEADLESS_PERMISSIONS:-}" ]; then
    echo "Missing HEADLESS_PERMISSIONS in workflow_config" >&2
    return 1
  fi
}

set_permission_flags() {
  case "$HEADLESS_PERMISSIONS" in
    Normal)
      CODEX_PERM_FLAGS=(--full-auto)
      CLAUDE_PERM_FLAGS=()
      ;;
    Elevated)
      CODEX_PERM_FLAGS=(--full-auto --sandbox danger-full-access)
      CLAUDE_PERM_FLAGS=(--permission-mode acceptEdits)
      ;;
    Maximum)
      CODEX_PERM_FLAGS=(--full-auto --dangerously-bypass-approvals-and-sandbox)
      CLAUDE_PERM_FLAGS=(--dangerously-skip-permissions)
      ;;
    *)
      echo "Unknown HEADLESS_PERMISSIONS: $HEADLESS_PERMISSIONS" >&2
      return 1
      ;;
  esac
}

get_openclaw_token() {
  if [ -n "${OPENCLAW_GATEWAY_TOKEN:-}" ]; then
    printf '%s' "$OPENCLAW_GATEWAY_TOKEN"
    return 0
  fi

  if command -v openclaw >/dev/null 2>&1; then
    local out token
    out="$(openclaw config get gateway.auth.token --json 2>/dev/null)" || out=""
    if [ -n "$out" ]; then
      token="$(python3 -c 'import json,sys
try:
  p=json.load(sys.stdin)
except Exception:
  raise SystemExit(1)
v=p.get("value") if isinstance(p, dict) else None
if isinstance(v, str) and v.strip():
  sys.stdout.write(v.strip())
  raise SystemExit(0)
raise SystemExit(1)
' 2>/dev/null <<<"$out")" || token=""
      if [ -n "$token" ]; then
        printf '%s' "$token"
        return 0
      fi
    fi

    # Fallback: some installs print the token directly (or emit JSON without --json).
    out="$(openclaw config get gateway.auth.token 2>/dev/null)" || return $?
    token="$(python3 -c 'import json,sys
try:
  p=json.load(sys.stdin)
except Exception:
  raise SystemExit(1)
v=p.get("value") if isinstance(p, dict) else None
if isinstance(v, str) and v.strip():
  sys.stdout.write(v.strip())
  raise SystemExit(0)
raise SystemExit(1)
' 2>/dev/null <<<"$out")" || token=""
    if [ -n "$token" ]; then
      printf '%s' "$token"
      return 0
    fi
    printf '%s' "$(trim "$out")"
    return 0
  fi

  if command -v openclaw.exe >/dev/null 2>&1; then
    local out token
    out="$(openclaw.exe config get gateway.auth.token --json 2>/dev/null)" || out=""
    if [ -n "$out" ]; then
      token="$(python3 -c 'import json,sys
try:
  p=json.load(sys.stdin)
except Exception:
  raise SystemExit(1)
v=p.get("value") if isinstance(p, dict) else None
if isinstance(v, str) and v.strip():
  sys.stdout.write(v.strip())
  raise SystemExit(0)
raise SystemExit(1)
' 2>/dev/null <<<"$out")" || token=""
      if [ -n "$token" ]; then
        printf '%s' "$token"
        return 0
      fi
    fi

    # Fallback: some installs print the token directly (or emit JSON without --json).
    out="$(openclaw.exe config get gateway.auth.token 2>/dev/null)" || return $?
    token="$(python3 -c 'import json,sys
try:
  p=json.load(sys.stdin)
except Exception:
  raise SystemExit(1)
v=p.get("value") if isinstance(p, dict) else None
if isinstance(v, str) and v.strip():
  sys.stdout.write(v.strip())
  raise SystemExit(0)
raise SystemExit(1)
' 2>/dev/null <<<"$out")" || token=""
    if [ -n "$token" ]; then
      printf '%s' "$token"
      return 0
    fi
    printf '%s' "$(trim "$out")"
    return 0
  fi

  echo "OpenClaw token not available. Set OPENCLAW_GATEWAY_TOKEN or install openclaw/openclaw.exe." >&2
  return 1
}

openclaw_run() {
  local model="$1"
  local prompt="$2"
  local stdout_path="$3"
  local stderr_path="$4"
  local last_path="$5"

  local openclaw_url="${OPENCLAW_GATEWAY_URL:-http://127.0.0.1:18789}"
  local openclaw_agent_id="${OPENCLAW_AGENT_ID:-main}"
  local token
  token="$(get_openclaw_token)" || return 1

  local cycle="${stdout_path##*/}"
  cycle="${cycle%.stdout.log}"
  local user_key="olad:${RUN_ID}:${cycle}"

  local body
  body="$(python3 -c 'import json,sys; model=sys.argv[1]; user=sys.argv[2]; prompt=sys.stdin.read(); print(json.dumps({"model": model, "user": user, "input": prompt}))' \
    "$model" "$user_key" <<<"$prompt")"

  local response_path
  response_path="$(dirname "$stdout_path")/${cycle}.openclaw.response.json"
  if ! curl -sS "$openclaw_url/v1/responses" \
    -H "Authorization: Bearer $token" \
    -H "Content-Type: application/json" \
    -H "x-openclaw-agent-id: $openclaw_agent_id" \
    -d "$body" >"$response_path" 2>"$stderr_path"; then
    return 1
  fi

  python3 - "$response_path" >"$stdout_path" 2>>"$stderr_path" <<'PY'
import json
import sys

path = sys.argv[1]
with open(path, "r", encoding="utf-8") as f:
  data = json.load(f)

if isinstance(data, dict) and data.get("error"):
  err = data["error"]
  if isinstance(err, dict):
    msg = err.get("message") or json.dumps(err)
  else:
    msg = str(err)
  sys.stdout.write(msg)
  sys.exit(2)

text = ""
if isinstance(data, dict):
  text = data.get("output_text") or ""

if not text and isinstance(data, dict):
  out = data.get("output") or []
  parts = []
  for item in out:
    if not isinstance(item, dict):
      continue
    if item.get("type") != "message":
      continue
    if item.get("role") != "assistant":
      continue
    for c in item.get("content", []) or []:
      if not isinstance(c, dict):
        continue
      t = c.get("text")
      if isinstance(t, str):
        parts.append(t)
  text = "".join(parts)

sys.stdout.write(text)
PY
  exit_code=$?

  if [ -n "$last_path" ]; then
    cp -f "$stdout_path" "$last_path"
  fi

  return $exit_code
}

parse_model_config || exit 1
parse_workflow_config || exit 1
set_permission_flags || exit 1

run_cycle() {
  runner="$1"
  model="$2"
  prompt="$3"
  stdout_path="$4"
  stderr_path="$5"
  last_path="$6"
  codex_search="${7:-}"

  local CODEX_SEARCH_FLAGS=()
  if [ "$codex_search" = "true" ]; then
    CODEX_SEARCH_FLAGS=(--search)
  fi

  if [ "$runner" = "openclaw" ]; then
    openclaw_run "$model" "$prompt" "$stdout_path" "$stderr_path" "$last_path"
    return $?
  fi

  if [ "$runner" = "codex" ]; then
    if [ -n "$last_path" ]; then
      codex exec --model "$model" "${CODEX_PERM_FLAGS[@]}" "${CODEX_SEARCH_FLAGS[@]}" -o "$last_path" "$prompt" >"$stdout_path" 2>"$stderr_path"
    else
      codex exec --model "$model" "${CODEX_PERM_FLAGS[@]}" "${CODEX_SEARCH_FLAGS[@]}" "$prompt" >"$stdout_path" 2>"$stderr_path"
    fi
    return $?
  fi

  if [ "$runner" = "claude" ]; then
    claude -p "$prompt" --model "$model" --output-format text "${CLAUDE_PERM_FLAGS[@]}" >"$stdout_path" 2>"$stderr_path"
    exit_code=$?
    if [ -n "$last_path" ]; then
      cp -f "$stdout_path" "$last_path"
    fi
    return $exit_code
  fi

  echo "Unknown runner: $runner (expected codex|claude|openclaw). Check agents/options/model_config.md" >&2
  return 1
}

# Builder
run_cycle "$BUILDER_RUNNER" "$BUILDER_MODEL" "Open agents/_start.md and follow instructions." \
  "$RUN_DIR/builder.stdout.log" "$RUN_DIR/builder.stderr.log" "$RUN_DIR/builder.last.md"

# QA
run_cycle "$QA_RUNNER" "$QA_MODEL" "Open agents/_check.md and follow instructions." \
  "$RUN_DIR/qa.stdout.log" "$RUN_DIR/qa.stderr.log" "$RUN_DIR/qa.last.md" true
```

## Optional cycles (only if your repo enables them)

Integration cycle (only if `agents/_orchestrate.md` has Integration enabled):

```bash
run_cycle "$INTEGRATION_RUNNER" "$INTEGRATION_MODEL" "Open agents/_integrate.md and follow instructions." \
  "$RUN_DIR/integration.stdout.log" "$RUN_DIR/integration.stderr.log" "$RUN_DIR/integration.last.md"
```

Hotfix + Doublecheck (only if QA writes `### QUICKFIX_NEEDED`):

```bash
run_cycle "$HOTFIX_RUNNER" "$HOTFIX_MODEL" "Open agents/_hotfix.md and follow instructions." \
  "$RUN_DIR/hotfix.stdout.log" "$RUN_DIR/hotfix.stderr.log" "$RUN_DIR/hotfix.last.md"

run_cycle "$DOUBLECHECK_RUNNER" "$DOUBLECHECK_MODEL" "Open agents/_doublecheck.md and follow instructions." \
  "$RUN_DIR/doublecheck.stdout.log" "$RUN_DIR/doublecheck.stderr.log" "$RUN_DIR/doublecheck.last.md" true
```

Troubleshooter (only if installed and enabled by `agents/_orchestrate.md`):

```bash
run_cycle "codex" "gpt-5.2-codex" "Open agents/_troubleshoot.md and follow instructions. For context: \"<blocker summary>\"" \
  "$RUN_DIR/troubleshoot.stdout.log" "$RUN_DIR/troubleshoot.stderr.log" "$RUN_DIR/troubleshoot.last.md"
```

## Timeouts (bash)

If you have GNU `timeout`, wrap a call like:

```bash
timeout 5400 codex exec --model gpt-5.2-codex --full-auto -o "$RUN_DIR/builder.last.md" "Open agents/_start.md and follow instructions."
```

## Diagnostics PR helpers (gh)

Example commands (run from the diagnostics branch):

```bash
gh pr create --title "Diagnostics: runner blocked $(date +%F\ %T)" --body "See agents/diagnostics/<DIAG_DIR> for logs and snapshots."
gh pr comment --body "@codex Diagnose why the local runner got blocked. Read agents/diagnostics/<DIAG_DIR> and propose the smallest fix to unblock the runner."
```

## Notes

- Keep the *prompt string* exactly as specified in the Runner entrypoints; only flags/redirects may change.
- Permission flags are controlled by `HEADLESS_PERMISSIONS` in `agents/options/workflow_config.md`.
