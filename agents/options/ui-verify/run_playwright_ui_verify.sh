#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
run_playwright_ui_verify.sh --out <OUT_DIR> [--spec <SPEC_PATH>] [--coverage <smoke|standard|broad>] [--cmd <COMMAND>] [--update-latest]

Purpose:
- Best-effort deterministic UI verification runner scaffold.
- Creates an artifact bundle (result.json + report.md + evidence/meta folders).

Notes:
- This script does not install Playwright for you.
- If Playwright (or required tooling) is missing, it writes status=BLOCKED with a precise error.
- If a Playwright command runs and exits non-zero, it writes status=FAIL.

Recommended usage in OLAD:
- Provide a project-specific Playwright test suite and invoke it via --cmd.
EOF
}

SPEC_PATH="agents/ui_verification_spec.yaml"
OUT_DIR=""
COVERAGE=""
CMD=""
UPDATE_LATEST="false"

while [ $# -gt 0 ]; do
  case "$1" in
    --spec) SPEC_PATH="${2:-}"; shift 2 ;;
    --out) OUT_DIR="${2:-}"; shift 2 ;;
    --coverage) COVERAGE="${2:-}"; shift 2 ;;
    --cmd) CMD="${2:-}"; shift 2 ;;
    --update-latest) UPDATE_LATEST="true"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 2 ;;
  esac
done

if [ -z "$OUT_DIR" ]; then
  echo "Missing --out <OUT_DIR>" >&2
  usage
  exit 2
fi

mkdir -p "$OUT_DIR/evidence" "$OUT_DIR/meta"

STARTED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
STATUS="BLOCKED"
EXECUTOR="playwright"
ANALYZER="none"

ERROR_TYPE=""
ERROR_MESSAGE=""

if [ -f "$SPEC_PATH" ]; then
  cp -f "$SPEC_PATH" "$OUT_DIR/meta/spec_resolved.yaml" 2>/dev/null || true
fi

if ! command -v node >/dev/null 2>&1; then
  ERROR_TYPE="ENV"
  ERROR_MESSAGE="node is not installed or not on PATH"
elif ! command -v npx >/dev/null 2>&1; then
  ERROR_TYPE="ENV"
  ERROR_MESSAGE="npx is not installed or not on PATH"
else
  if ! npx playwright --version >/dev/null 2>&1; then
    ERROR_TYPE="ENV"
    ERROR_MESSAGE="Playwright is not installed (try adding it to the project and rerun)"
  else
    set +e
    if [ -n "$CMD" ]; then
      bash -lc "$CMD"
      RC=$?
    else
      # Default: run the project's configured Playwright suite.
      npx playwright test
      RC=$?
    fi
    set -e

    if [ "$RC" -eq 0 ]; then
      STATUS="PASS"
    else
      STATUS="FAIL"
      ERROR_TYPE="ASSERTION"
      ERROR_MESSAGE="Playwright exited non-zero (rc=$RC)"
    fi
  fi
fi

ENDED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

export UI_VERIFY_STATUS="$STATUS"
export UI_VERIFY_EXECUTOR="$EXECUTOR"
export UI_VERIFY_ANALYZER="$ANALYZER"
export UI_VERIFY_COVERAGE="$COVERAGE"
export UI_VERIFY_STARTED_AT="$STARTED_AT"
export UI_VERIFY_ENDED_AT="$ENDED_AT"
export UI_VERIFY_EVIDENCE_DIR="$OUT_DIR/evidence"
export UI_VERIFY_ERROR_TYPE="$ERROR_TYPE"
export UI_VERIFY_ERROR_MESSAGE="$ERROR_MESSAGE"

python3 - "$OUT_DIR/result.json" <<PY
import json
import os
import sys

out_path = sys.argv[1]

data = {
  "status": os.environ.get("UI_VERIFY_STATUS", ""),
  "executor": os.environ.get("UI_VERIFY_EXECUTOR", ""),
  "analyzer": os.environ.get("UI_VERIFY_ANALYZER", ""),
  "coverage": os.environ.get("UI_VERIFY_COVERAGE", ""),
  "started_at": os.environ.get("UI_VERIFY_STARTED_AT", ""),
  "ended_at": os.environ.get("UI_VERIFY_ENDED_AT", ""),
  "evidence_dir": os.environ.get("UI_VERIFY_EVIDENCE_DIR", ""),
  "checks": [],
  "errors": [],
  "quota": None,
}

err_type = (os.environ.get("UI_VERIFY_ERROR_TYPE") or "").strip()
err_msg = (os.environ.get("UI_VERIFY_ERROR_MESSAGE") or "").strip()
if err_type and err_msg:
  data["errors"].append({"type": err_type, "message": err_msg})

with open(out_path, "w", encoding="utf-8") as f:
  json.dump(data, f, indent=2, sort_keys=True)
  f.write("\n")
PY

cat >"$OUT_DIR/report.md" <<EOF
# UI Verification Report

UI_VERIFY: $STATUS

- executor: $EXECUTOR
- analyzer: $ANALYZER
- coverage: ${COVERAGE:-""}
- started_at: $STARTED_AT
- ended_at: $ENDED_AT
- evidence_dir: $OUT_DIR/evidence

## Notes

- This is a deterministic runner scaffold. Provide a project-specific Playwright suite and invoke it via \`--cmd\` for meaningful coverage.
- Spec (if present): \`$SPEC_PATH\` (copied to \`meta/spec_resolved.yaml\`).
EOF

if [ "$UPDATE_LATEST" = "true" ] && [ -d "agents" ]; then
  cp -f "$OUT_DIR/result.json" "agents/ui_verification_result.json" 2>/dev/null || true
  cp -f "$OUT_DIR/report.md" "agents/ui_verification_report.md" 2>/dev/null || true
fi

case "$STATUS" in
  PASS) exit 0 ;;
  FAIL) exit 1 ;;
  BLOCKED) exit 2 ;;
  *) exit 3 ;;
esac
