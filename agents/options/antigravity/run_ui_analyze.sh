#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
run_ui_analyze.sh --model <MODEL_ID> --bundle <UI_VERIFY_BUNDLE_DIR> --out <REPORT_PATH>

Best-effort analyzer runner:
- Reads UI verify bundle artifacts (result.json + evidence listing).
- Uses the provided MODEL_ID (typically a Gemini 3 model routed through your Gateway)
  to generate a narrative report.

If your environment does not route Gemini/Anti-Gravity models through OpenClaw Gateway,
adapt the "analyze_call" function to your analyzer invocation.
EOF
}

MODEL_ID=""
BUNDLE_DIR=""
OUT_PATH=""

while [ $# -gt 0 ]; do
  case "$1" in
    --model) MODEL_ID="${2:-}"; shift 2 ;;
    --bundle) BUNDLE_DIR="${2:-}"; shift 2 ;;
    --out) OUT_PATH="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 2 ;;
  esac
done

if [ -z "$MODEL_ID" ] || [ -z "$BUNDLE_DIR" ] || [ -z "$OUT_PATH" ]; then
  echo "Missing required args." >&2
  usage
  exit 2
fi

if [ ! -f "$BUNDLE_DIR/result.json" ]; then
  echo "Missing $BUNDLE_DIR/result.json" >&2
  exit 2
fi

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

get_openclaw_token() {
  if [ -n "${OPENCLAW_GATEWAY_TOKEN:-}" ]; then
    printf '%s' "$OPENCLAW_GATEWAY_TOKEN"
    return 0
  fi
  if command -v openclaw >/dev/null 2>&1; then
    local out
    out="$(openclaw config get gateway.auth.token --json 2>/dev/null)" || out=""
    if [ -n "$out" ]; then
      python3 -c 'import json,sys
try: p=json.load(sys.stdin)
except Exception: raise SystemExit(1)
v=p.get("value") if isinstance(p, dict) else None
if isinstance(v, str) and v.strip(): print(v.strip()); raise SystemExit(0)
raise SystemExit(1)
' <<<"$out" 2>/dev/null && return 0
    fi
    out="$(openclaw config get gateway.auth.token 2>/dev/null)" || return $?
    printf '%s' "$(trim "$out")"
    return 0
  fi
  if command -v openclaw.exe >/dev/null 2>&1; then
    local out
    out="$(openclaw.exe config get gateway.auth.token --json 2>/dev/null)" || out=""
    if [ -n "$out" ]; then
      python3 -c 'import json,sys
try: p=json.load(sys.stdin)
except Exception: raise SystemExit(1)
v=p.get("value") if isinstance(p, dict) else None
if isinstance(v, str) and v.strip(): print(v.strip()); raise SystemExit(0)
raise SystemExit(1)
' <<<"$out" 2>/dev/null && return 0
    fi
    out="$(openclaw.exe config get gateway.auth.token 2>/dev/null)" || return $?
    printf '%s' "$(trim "$out")"
    return 0
  fi
  echo "OpenClaw token not available. Set OPENCLAW_GATEWAY_TOKEN or install openclaw/openclaw.exe." >&2
  return 1
}

analyze_call() {
  local model="$1"
  local prompt="$2"
  local url="${OPENCLAW_GATEWAY_URL:-http://127.0.0.1:18789}"
  local agent_id="${OPENCLAW_AGENT_ID:-main}"
  local token
  token="$(get_openclaw_token)" || return 10

  local body
  body="$(python3 -c 'import json,sys; model=sys.argv[1]; prompt=sys.stdin.read(); print(json.dumps({"model": model, "input": prompt}))' \
    "$model" <<<"$prompt")"

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
data = json.loads(raw)
if isinstance(data, dict) and data.get("error"):
  err = data["error"]
  msg = err.get("message") if isinstance(err, dict) else str(err)
  print(msg, file=sys.stderr)
  raise SystemExit(1)
txt = ""
if isinstance(data, dict):
  txt = data.get("output_text") or ""
sys.stdout.write(txt)
PY
}

evidence_list="$(find "$BUNDLE_DIR/evidence" -maxdepth 3 -type f 2>/dev/null | sed "s#^$BUNDLE_DIR/##" | head -n 200 || true)"
result_json="$(cat "$BUNDLE_DIR/result.json" | head -c 40000)"

read -r -d '' PROMPT <<EOF || true
You are an automated UI verification report writer.

Inputs:
- result.json (authoritative): below
- evidence file list: below

Write a concise Markdown report with:
1) UI_VERIFY: PASS|FAIL|BLOCKED (repeat the status from result.json; do not change it)
2) What failed (if anything), grouped by check/suite if available
3) Likely causes (hypotheses; clearly labeled)
4) Suggested next fixes / debugging steps

Do NOT include secrets. Do NOT claim you verified UI beyond what the evidence supports.

--- result.json (truncated) ---
$result_json

--- evidence files (truncated) ---
$evidence_list
EOF

set +e
report="$(analyze_call "$MODEL_ID" "$PROMPT" 2>"$BUNDLE_DIR/meta/analyzer.stderr.log")"
rc=$?
set -e

if [ "$rc" -ne 0 ]; then
  echo "Analyzer failed; see $BUNDLE_DIR/meta/analyzer.stderr.log" >&2
  exit 2
fi

mkdir -p "$(dirname "$OUT_PATH")"
printf '%s\n' "$report" >"$OUT_PATH"

