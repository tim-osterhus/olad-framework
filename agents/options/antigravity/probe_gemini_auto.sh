#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
probe_gemini_auto.sh [--model <auto|flash|pro_low|pro_high>] [--force] [--retry-minutes <N>]

Purpose:
- Perform an authoritative "probe call" (tiny request) against Gemini 3 models
  via the same route you intend to use for Anti-Gravity UI analysis.
- On quota/rate-limit errors, persist exhaustion flags (timestamp to minute)
  into agents/options/workflow_config.md and fall back to the next model.

Output:
- On success: prints the selected model id to stdout and exits 0.
- If all models are exhausted: exits 2.
- On non-quota integration errors: exits 1.

Assumptions (default implementation):
- Probe is executed via OpenClaw Gateway POST /v1/responses.
- OPENCLAW_GATEWAY_URL / OPENCLAW_AGENT_ID are read from agents/options/workflow_config.md.
- Token is read from OPENCLAW_GATEWAY_TOKEN or openclaw/openclaw.exe config.

If your Anti-Gravity integration is NOT reachable through OpenClaw Gateway, replace
the probe_call() function body with your Anti-Gravity invocation.
EOF
}

MODEL_MODE="auto"
FORCE="false"
RETRY_MINUTES="360"

while [ $# -gt 0 ]; do
  case "$1" in
    --model) MODEL_MODE="${2:-}"; shift 2 ;;
    --force) FORCE="true"; shift ;;
    --retry-minutes) RETRY_MINUTES="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 2 ;;
  esac
done

trim() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

get_cfg() {
  local key="$1"
  local line
  while IFS= read -r line || [ -n "$line" ]; do
    if [[ "$line" =~ ^##[[:space:]]*${key}[[:space:]]*=[[:space:]]*(.*)$ ]]; then
      printf '%s' "$(trim "${BASH_REMATCH[1]}")"
      return 0
    fi
  done < "agents/options/workflow_config.md"
  return 1
}

set_cfg() {
  local key="$1"
  local value="$2"
  python3 - "agents/options/workflow_config.md" "$key" "$value" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
key = sys.argv[2]
value = sys.argv[3]

lines = path.read_text(encoding="utf-8").splitlines()
pat = re.compile(rf"^(##\s*{re.escape(key)}\s*=).*$")

out = []
found = False
for line in lines:
  m = pat.match(line)
  if m:
    out.append(f"{m.group(1)}{value}")
    found = True
  else:
    out.append(line)

if not found:
  out.append(f"## {key}={value}")

path.write_text("\n".join(out) + "\n", encoding="utf-8")
PY
}

now_minute() {
  date -u +%Y-%m-%dT%H:%M
}

minutes_since() {
  python3 - "$1" <<'PY'
import sys
from datetime import datetime, timezone

s = sys.argv[1].strip()
if not s:
  raise SystemExit(2)

fmt = "%Y-%m-%dT%H:%M"
try:
  dt = datetime.strptime(s, fmt).replace(tzinfo=timezone.utc)
except Exception:
  raise SystemExit(3)

now = datetime.now(timezone.utc)
mins = int((now - dt).total_seconds() // 60)
print(mins)
PY
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
try: p=json.load(sys.stdin)
except Exception: raise SystemExit(1)
v=p.get("value") if isinstance(p, dict) else None
if isinstance(v, str) and v.strip(): sys.stdout.write(v.strip()); raise SystemExit(0)
raise SystemExit(1)
' 2>/dev/null <<<"$out")" || token=""
      if [ -n "$token" ]; then
        printf '%s' "$token"
        return 0
      fi
    fi
    out="$(openclaw config get gateway.auth.token 2>/dev/null)" || return $?
    printf '%s' "$(trim "$out")"
    return 0
  fi

  if command -v openclaw.exe >/dev/null 2>&1; then
    local out token
    out="$(openclaw.exe config get gateway.auth.token --json 2>/dev/null)" || out=""
    if [ -n "$out" ]; then
      token="$(python3 -c 'import json,sys
try: p=json.load(sys.stdin)
except Exception: raise SystemExit(1)
v=p.get("value") if isinstance(p, dict) else None
if isinstance(v, str) and v.strip(): sys.stdout.write(v.strip()); raise SystemExit(0)
raise SystemExit(1)
' 2>/dev/null <<<"$out")" || token=""
      if [ -n "$token" ]; then
        printf '%s' "$token"
        return 0
      fi
    fi
    out="$(openclaw.exe config get gateway.auth.token 2>/dev/null)" || return $?
    printf '%s' "$(trim "$out")"
    return 0
  fi

  echo "OpenClaw token not available. Set OPENCLAW_GATEWAY_TOKEN or install openclaw/openclaw.exe." >&2
  return 1
}

probe_call() {
  local model_id="$1"
  local url="${OPENCLAW_GATEWAY_URL:-http://127.0.0.1:18789}"
  local agent_id="${OPENCLAW_AGENT_ID:-main}"
  local token
  token="$(get_openclaw_token)" || return 10

  local body
  body="$(python3 -c 'import json,sys; model=sys.argv[1]; prompt=sys.argv[2]; print(json.dumps({"model": model, "input": prompt}))' \
    "$model_id" "Reply with the single token OK.")"

  local resp
  resp="$(curl -sS "$url/v1/responses" \
    -H "Authorization: Bearer $token" \
    -H "Content-Type: application/json" \
    -H "x-openclaw-agent-id: $agent_id" \
    -d "$body")" || return 11

  python3 - "$resp" <<'PY'
import json
import sys

raw = sys.argv[1]
try:
  data = json.loads(raw)
except Exception:
  # Non-JSON response from gateway.
  print("BLOCKED: non-json response from gateway", file=sys.stderr)
  raise SystemExit(30)

err = None
if isinstance(data, dict):
  err = data.get("error")

if err:
  msg = ""
  if isinstance(err, dict):
    msg = err.get("message") or json.dumps(err)
  else:
    msg = str(err)
  low = msg.lower()
  if any(x in low for x in ["quota", "rate limit", "resource_exhausted", "too many requests", "429"]):
    print(msg, file=sys.stderr)
    raise SystemExit(42)  # QUOTA
  print(msg, file=sys.stderr)
  raise SystemExit(41)  # OTHER_ERROR

raise SystemExit(0)
PY
}

model_order_for_pref() {
  local pref="$1"
  case "$pref" in
    flash) echo "flash pro_low pro_high" ;;
    pro_low) echo "pro_low pro_high flash" ;;
    pro_high) echo "pro_high pro_low flash" ;;
    auto|"") echo "flash pro_low pro_high" ;;
    *)
      echo "Unknown ANTIGRAVITY_MODEL_PREF: $pref" >&2
      echo "flash pro_low pro_high"
      ;;
  esac
}

pick_models() {
  if [ "$MODEL_MODE" != "auto" ] && [ -n "$MODEL_MODE" ]; then
    # Explicit override for debugging.
    echo "$MODEL_MODE"
    return 0
  fi
  local pref
  pref="$(get_cfg "ANTIGRAVITY_MODEL_PREF" 2>/dev/null || true)"
  model_order_for_pref "$pref"
}

model_id_for() {
  case "$1" in
    flash) get_cfg "ANTIGRAVITY_G3_FLASH_MODEL" 2>/dev/null || true ;;
    pro_low) get_cfg "ANTIGRAVITY_G3_PRO_LOW_MODEL" 2>/dev/null || true ;;
    pro_high) get_cfg "ANTIGRAVITY_G3_PRO_HIGH_MODEL" 2>/dev/null || true ;;
    *) echo "" ;;
  esac
}

exhausted_key_for() {
  case "$1" in
    flash) echo "ANTIGRAVITY_G3_FLASH_EXHAUSTED_AT" ;;
    pro_low) echo "ANTIGRAVITY_G3_PRO_LOW_EXHAUSTED_AT" ;;
    pro_high) echo "ANTIGRAVITY_G3_PRO_HIGH_EXHAUSTED_AT" ;;
    *) echo "" ;;
  esac
}

should_skip_due_to_exhausted_flag() {
  local key="$1"
  local val
  val="$(get_cfg "$key" 2>/dev/null || true)"
  if [ -z "$val" ] || [ "$FORCE" = "true" ]; then
    return 1
  fi

  local mins
  mins="$(minutes_since "$val" 2>/dev/null || true)"
  if [[ "$mins" =~ ^[0-9]+$ ]] && [ "$mins" -lt "$RETRY_MINUTES" ]; then
    return 0
  fi
  return 1
}

for m in $(pick_models); do
  mid="$(model_id_for "$m")"
  ek="$(exhausted_key_for "$m")"

  if [ -z "$mid" ]; then
    echo "Skipping $m (missing model id; set ANTIGRAVITY_G3_*_MODEL in agents/options/workflow_config.md)" >&2
    continue
  fi

  if [ -n "$ek" ] && should_skip_due_to_exhausted_flag "$ek"; then
    echo "Skipping $m due to recent exhausted flag ($ek)" >&2
    continue
  fi

  set +e
  probe_call "$mid"
  rc=$?
  set -e

  if [ "$rc" -eq 0 ]; then
    # Success: clear exhausted flag (best-effort) and print selected model id.
    if [ -n "$ek" ]; then
      set_cfg "$ek" ""
    fi
    printf '%s\n' "$mid"
    exit 0
  fi

  if [ "$rc" -eq 42 ]; then
    # Quota: mark exhausted and continue.
    if [ -n "$ek" ]; then
      set_cfg "$ek" "$(now_minute)"
    fi
    continue
  fi

  # Non-quota error: treat as blocked integration issue.
  echo "Probe failed for model $m ($mid) with non-quota error (rc=$rc). Aborting." >&2
  exit 1
done

# If we got here, nothing was usable (either all exhausted or missing config).
exit 2

