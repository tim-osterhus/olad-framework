# UI Verification Option (OpenClaw + Anti-Gravity friendly)

This option is intended to be used by `agents/_customize.md`.

Goal: enable optional, structured UI verification that can be invoked by an OpenClaw Supervisor (or an OpenClaw-enhanced QA session) without requiring a human to be present.

Key design:
- Deterministic gate produces the authoritative `PASS|FAIL|BLOCKED`.
- LLM analysis (Anti-Gravity/Gemini or OpenClaw) is explanatory only.

## What this option changes (high level)

When enabled, OLAD gains:
- Workflow flags (in `agents/options/workflow_config.md`) controlling UI verification.
- A canonical artifact contract under `agents/diagnostics/ui_verify/`.
- A YAML spec template (`agents/ui_verification_spec.yaml`) suitable for broad coverage.
- An OpenClaw UI Verifier entrypoint (`agents/options/openclaw/_ui_verify.md`) that:
  - reads the config flags,
  - runs the appropriate verification path,
  - writes artifacts,
  - and only sets `agents/status.md` to `### BLOCKED` when the UI verification system itself is blocked by environment/tooling.

## Modes (choose one via workflow flags)

Set in `agents/options/workflow_config.md`:

- `UI_VERIFY_MODE=manual`
  - Equivalent to opting out. The Supervisor may still ask a human to verify manually.

- `UI_VERIFY_MODE=deterministic`
  - Run deterministic automation (Playwright/OpenClaw) and produce artifacts.
  - No LLM analysis required.

- `UI_VERIFY_MODE=hybrid`
  - Run deterministic automation and then (optionally) run an analyzer to generate a narrative report.
  - Analyzer selection is controlled by `UI_VERIFY_ANALYZER`.

## Required config flags

All flags live in `agents/options/workflow_config.md` as `## KEY=value` lines.

Core:
- `UI_VERIFY_MODE=manual|deterministic|hybrid`
- `UI_VERIFY_EXECUTOR=playwright|openclaw_browser|antigravity_agent`
- `UI_VERIFY_ANALYZER=antigravity|openclaw|none`
- `UI_VERIFY_HOST=windows|mac|auto`
- `UI_VERIFY_COVERAGE=smoke|standard|broad`
- `UI_VERIFY_QUOTA_GUARD=on|off`
- `UI_VERIFY_BROWSER_PROFILE=<profile>` (required for OpenClaw tool-based browser automation)

Anti-Gravity selection (if analyzer or executor uses it):
- `ANTIGRAVITY_MODEL_PREF=auto|flash|pro_low|pro_high`
- `ANTIGRAVITY_PROBE_MODE=probe_call`
- `ANTIGRAVITY_G3_*_EXHAUSTED_AT=` flags (set automatically on quota errors; timestamp to minute)

See: `agents/options/antigravity/antigravity_option.md` for the quota probe + fallback rules.

## Artifact contract (must be stable)

Every UI verification attempt must create a bundle folder:

- `agents/diagnostics/ui_verify/<YYYYMMDD-HHMMSS>-<task_slug>/`
  - `result.json` (authoritative machine output)
  - `report.md` (human-readable, includes evidence pointers; may include LLM analysis)
  - `evidence/` (screenshots/logs/etc)
  - `meta/` (resolved spec + environment metadata)

And update "latest" pointers:
- `agents/ui_verification_result.json`
- `agents/ui_verification_report.md`

`result.json` minimum schema:
- `status`: `PASS|FAIL|BLOCKED`
- `executor`: `playwright|openclaw_browser|antigravity_agent`
- `analyzer`: `antigravity|openclaw|none`
- `coverage`: `smoke|standard|broad`
- `started_at`, `ended_at` (ISO8601)
- `evidence_dir`
- `checks[]` with per-check statuses
- `errors[]` (typed)
- `quota` object describing probe outcome (if used)

## Spec format (YAML)

Create (or maintain) a runnable spec at:
- `agents/ui_verification_spec.yaml`

The spec should support multiple suites (smoke/flows/visual/a11y/etc) so `UI_VERIFY_COVERAGE=broad` is feasible.

## Host policy (important)

Even if `UI_VERIFY_HOST=auto`:
- Attempt Windows-local execution first (the normal OLAD environment).
- Only attempt Mac-host execution after Windows has repeatedly failed (this is an advanced fallback, not a generic default).

Mac-host UI verification is most appropriate for verifying a deployed environment (staging/prod URL) reachable from the Mac.

## Fallback ladder (required behavior)

When `UI_VERIFY_ANALYZER=antigravity` (or executor uses Anti-Gravity) and quota guard is on:
1) Run a probe call (tiny request) on the intended model.
2) On quota error: mark the model exhausted (timestamp flag) and try the next model.
3) If all three are exhausted: fall back to OpenClaw native browser automation.

If OpenClaw browser automation is blocked and troubleshooting cannot fix it:
- The Supervisor must ask the user whether to switch to smoketest-based UI verification (Quick/Thorough).
- If no, the workflow remains `### BLOCKED` awaiting manual verification.

## Files this option may touch (during install/wiring)

- `agents/options/workflow_config.md` (flags only)
- `agents/_customize.md` (add the toggle + write flags)
- `agents/_supervisor.md` (policy: Supervisor may write ONLY `agents/status.md`)
- `agents/options/openclaw/_ui_verify.md` (artifact contract + quota probe + fallback ladder)
- `agents/ui_verification_spec.yaml` (template file)
- Shell templates (optional): `agents/options/orchestrate/orchestrate_options_*.md` (parsers ignore unknown keys)

## Verification checklist (quick)

- `agents/options/workflow_config.md` contains UI_VERIFY + ANTIGRAVITY flags as `## KEY=value`.
- Bash/PowerShell parsers ignore unknown keys (no hard failures).
- `agents/options/openclaw/_ui_verify.md`:
  - writes artifact bundles under `agents/diagnostics/ui_verify/`
  - updates `agents/ui_verification_result.json` and `agents/ui_verification_report.md`
  - does not stomp `agents/status.md` on PASS/FAIL (only sets BLOCKED when tooling/env is blocked)
- `agents/_supervisor.md` explicitly allows writing ONLY `agents/status.md` (nothing else).

