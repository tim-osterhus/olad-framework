# Examples (EXAMPLES.md)

This file stores detailed, real-world examples for the skill.

How to use:
1) Load SKILL.md (low context cost).
2) Search this file only when symptoms match (grep trigger phrases).
3) Prefer referencing examples by ID (EX-YYYY-MM-DD-##). Keep this file append-only.

CRITICAL: Always append new examples to the END of this file. Do not insert in the middle.

---

## EX-2026-02-04-01: browser.act fails unless UI_VERIFY_BROWSER_PROFILE is explicit

**Tags**: `openclaw`, `browser.act`, `profile`, `flake`
**Trigger phrases**:
- "UI_VERIFY_BROWSER_PROFILE"
- "browser.act"
- "profile"
- "No profile provided"
- "default profile"

**Date**: 2026-02-04

**Problem**:
OpenClaw browser automation fails immediately, or it "works" but is logged out / missing state,
because the browser profile was not explicitly specified.

**Impact**:
UI verification cannot be trusted: steps may execute in the wrong session state, producing false FAIL.

**Cause**:
Workflow flags did not set UI_VERIFY_BROWSER_PROFILE (or set a non-existent profile).

**Fix**:
1) Open agents/options/workflow_config.md.
2) Locate the UI_VERIFY_* section and set UI_VERIFY_BROWSER_PROFILE to a real, known-good profile.
3) Re-run the UI verify entrypoint described in agents/options/openclaw/_ui_verify.md.
4) Confirm the first evidence screenshot shows the expected logged-in state (or expected landing page).

**Prevention**:
- Add a preflight check in your UI verify runbook: "Refuse to run if UI_VERIFY_BROWSER_PROFILE is empty."

**References**:
- agents/options/openclaw/_ui_verify.md
- agents/options/workflow_config.md
- OpenClaw/TOOLS.md (browser tools)

---

## EX-2026-02-04-02: Automation works but evidence capture is too weak to be auditable

**Tags**: `evidence`, `screenshots`, `deterministic`, `audit`
**Trigger phrases**:
- "evidence folder empty"
- "no screenshots"
- "cannot reproduce"
- "insufficient evidence"
- "report has no proof"

**Date**: 2026-02-04

**Problem**:
Automation completes, but the evidence bundle is missing key screenshots or state snapshots.
Reviewers cannot tell what happened, and results become non-actionable.

**Impact**:
Results are disputed; UI_VERIFY status becomes low trust.

**Cause**:
Evidence was only captured at the end, or not captured at all for key branching steps.

**Fix**:
1) For each critical step (navigation, login, submit, post-submit result), capture:
   - screenshot after action
   - any available DOM snapshot (if the tool supports it)
2) Capture "start" and "end" screenshots every run.
3) Store evidence under the folder required by agents/options/openclaw/_ui_verify.md.

**Prevention**:
- Require a minimum evidence set in Definition of DONE:
  - start.png, end.png, plus at least 1 screenshot per critical step.

**References**:
- agents/options/openclaw/_ui_verify.md (evidence contract)
- OpenClaw/TOOLS.md (how to screenshot)

---

## EX-2026-02-04-03: Gemini Flash quota/rate-limit -> set exhausted flag -> fall back to Pro-low

**Tags**: `antigravity`, `gemini`, `quota`, `429`, `fallback`
**Trigger phrases**:
- "429"
- "Too Many Requests"
- "RESOURCE_EXHAUSTED"
- "quota exceeded"
- "rate limit"

**Date**: 2026-02-04

**Problem**:
Anti-Gravity analysis fails when using Gemini Flash due to quota/rate-limit.

**Impact**:
If you keep retrying Flash, you waste time and may worsen throttling.
UI verify should still complete deterministically.

**Cause**:
Flash model is temporarily unavailable (quota exhausted or rate limited).

**Fix**:
1) Run the repo-provided probe script:
   - agents/options/antigravity/probe_gemini_auto.(ps1|sh)
2) Confirm it marks Flash as exhausted by writing its exhaustion flag (timestamp rounded to minute).
3) Confirm it selects the next model in the ladder (Pro-low).
4) Run agents/options/antigravity/run_ui_analyze.(ps1|sh) with the selected model.
5) Keep deterministic PASS/FAIL based on OpenClaw evidence; treat analysis as advisory only.

**Prevention**:
- Never infinite-retry 429. Prefer: mark exhausted -> fall back -> continue.

**References**:
- agents/options/antigravity/probe_gemini_auto.ps1
- agents/options/antigravity/probe_gemini_auto.sh
- agents/options/workflow_config.md (ANTIGRAVITY_* exhaustion flags)

---

## EX-2026-02-04-04: All three Gemini models exhausted -> fall back to OpenClaw-only analysis

**Tags**: `antigravity`, `gemini`, `quota`, `fallback`
**Trigger phrases**:
- "all models exhausted"
- "no available Gemini model"
- "exhausted: flash"
- "exhausted: pro"
- "exhausted: pro-high"

**Date**: 2026-02-04

**Problem**:
Flash, Pro-low, and Pro-high are all exhausted (or disabled).
Anti-Gravity analysis cannot run.

**Impact**:
If you treat this as BLOCKED, you stop the whole workflow unnecessarily.

**Cause**:
Model availability is temporarily zero.

**Fix**:
1) Record the exhaustion state in the UI verify report (which flags exist and their timestamps).
2) Skip Anti-Gravity analysis entirely.
3) Continue OpenClaw-only UI verification and produce PASS/FAIL based on evidence.
4) Do NOT set agents/status.md to BLOCKED unless OpenClaw itself cannot run.

**Prevention**:
- Make "all models exhausted" a normal, non-blocking branch.

**References**:
- agents/options/antigravity/probe_gemini_auto.(ps1|sh)
- agents/options/workflow_config.md (cooldown rules)

---

## EX-2026-02-04-05: Probe succeeds after exhaustion -> clear stale exhausted flag

**Tags**: `antigravity`, `quota`, `flags`, `recovery`
**Trigger phrases**:
- "probe succeeded"
- "clearing exhausted flag"
- "stale exhausted flag"
- "cooldown passed"

**Date**: 2026-02-04

**Problem**:
A model was previously marked exhausted, but cooldown has passed and probing now succeeds.
If the exhausted flag is left in place, future runs may keep skipping a now-available model.

**Impact**:
You permanently degrade analysis quality and waste higher-tier quota.

**Cause**:
Exhaustion flag was never cleared after the model became available again.

**Fix**:
1) Use the probe script as the source of truth. If it reports the model is available:
   - Clear the exhausted flag as the script expects (often delete the flag file).
2) Re-run the probe to confirm the model is selected again.
3) Run analysis with run_ui_analyze.(ps1|sh).

**Prevention**:
- Ensure probe logic both sets and clears exhaustion flags (do not do this manually unless the script design requires it).

**References**:
- agents/options/antigravity/probe_gemini_auto.(ps1|sh)
- agents/options/workflow_config.md (exhaustion flag file paths)

---

## EX-2026-02-04-06: OpenClaw cannot reach target URL -> classify BLOCKED (not FAIL)

**Tags**: `openclaw`, `network`, `blocked`, `classification`
**Trigger phrases**:
- "ERR_NAME_NOT_RESOLVED"
- "ERR_CONNECTION_TIMED_OUT"
- "navigation failed"
- "DNS"
- "connection refused"

**Date**: 2026-02-04

**Problem**:
OpenClaw browser tooling cannot load the target URL due to network/DNS/connectivity issues.

**Impact**:
You cannot verify UI behavior at all, so PASS/FAIL is meaningless.

**Cause**:
Environment is blocked (wrong URL, VPN required, DNS issue, gateway cannot reach the network).

**Fix**:
1) Confirm the URL is correct (copy/paste exact).
2) Confirm network prerequisites (VPN, allowlist, proxy, firewall rules).
3) Attempt a minimal connectivity check (use whatever healthcheck/runbook exists in the repo).
4) If still unreachable, classify UI_VERIFY as BLOCKED and update agents/status.md accordingly.

**Prevention**:
- Add a preflight "reachability check" before running full UI automation.

**References**:
- OpenClaw/TOOLS.md (browser navigation + screenshot)
- agents/options/openclaw/_ui_verify.md (BLOCKED semantics)

---

## EX-2026-02-04-07: Artifact bundle is missing required files (result.json/report.md/latest pointers)

**Tags**: `artifacts`, `contract`, `ui-verify`
**Trigger phrases**:
- "result.json not found"
- "report.md missing"
- "latest pointer missing"
- "artifact contract"
- "bundle incomplete"

**Date**: 2026-02-04

**Problem**:
UI verify run produced evidence, but the required bundle files are missing or incorrectly named.
Downstream steps cannot consume the result.

**Impact**:
Automation cannot finalize UI_VERIFY outcome; pipelines break.

**Cause**:
The _ui_verify.md artifact contract was not followed exactly.

**Fix**:
1) Open agents/options/openclaw/_ui_verify.md and treat it as authoritative.
2) Create the required bundle structure and filenames exactly as specified.
3) Ensure any "latest" pointer files/symlinks are updated as required by the contract.
4) Re-run the UI verify step (or at minimum regenerate the bundle) and validate that downstream tooling can read it.

**Prevention**:
- Add a "bundle validation" checklist item: verify required files exist before declaring DONE.

**References**:
- agents/options/openclaw/_ui_verify.md (artifact contract)

---

## EX-2026-02-04-08: All UI automation blocked -> offer smoketest-based verification path

**Tags**: `blocked`, `fallback`, `smoketest`, `no-manual`
**Trigger phrases**:
- "browser tools unavailable"
- "OpenClaw gateway down"
- "cannot run UI automation"
- "allowlist blocked"
- "permission denied"

**Date**: 2026-02-04

**Problem**:
OpenClaw browser tooling is unavailable (gateway down, allowlist prevents exec, missing permissions),
and Anti-Gravity analysis cannot run (quota exhausted or not configured).

**Impact**:
You cannot perform UI verification through automation.

**Cause**:
Tooling/environment blockers, not a product defect.

**Fix**:
1) Attempt minimal troubleshooting (one pass):
   - verify OpenClaw runner health (use openclaw-olad-runner skill)
   - verify UI_VERIFY_BROWSER_PROFILE exists and is accessible
2) If still blocked, do NOT guess.
3) Classify UI_VERIFY as BLOCKED and update agents/status.md with the minimal next action.
4) Offer switching to smoketest-based verification:
   - locate the no-manual docs under agents/options/ui-verify/
   - propose a command-only verification path that does not require browser automation

**Prevention**:
- Keep a low-cost smoketest verification path available for when UI automation is blocked.

**References**:
- agents/options/ui-verify/ui_verify_option.md (look for no-manual path)
- agents/options/openclaw/_ui_verify.md (BLOCKED semantics)
