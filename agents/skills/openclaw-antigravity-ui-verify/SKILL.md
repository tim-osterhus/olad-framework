---
name: openclaw-antigravity-ui-verify
description: >
  Orchestrates deterministic UI verification via OpenClaw browser.act, producing OLAD UI verify artifacts.
  Use when manual UI verification is requested during headless orchestration, when a UI_VERIFY_BROWSER_PROFILE must be explicitly set for OpenClaw automation, or when Anti-Gravity/Gemini probe-call selection with exhaustion flags is needed as an optional analysis layer.
tags: ["openclaw", "ui-verify", "antigravity", "gemini", "qa"]
compatibility:
  runners: ["openclaw", "codex-cli", "claude-code"]
  tools: ["Read", "Grep", "Bash", "Write"]
  offline_ok: false
---

# OpenClaw + Anti-Gravity UI Verify (Deterministic)

## Purpose
Produce deterministic UI_VERIFY artifacts (PASS/FAIL/BLOCKED) via OpenClaw browser automation, with optional Anti-Gravity analysis that never overrides the deterministic result.

## Quick start
Goal:
- Produce UI_VERIFY: PASS/FAIL/BLOCKED + report path + evidence folder per agents/options/openclaw/_ui_verify.md, using OpenClaw browser.act with an explicit UI_VERIFY_BROWSER_PROFILE and optional Anti-Gravity analysis with quota guard.

Use when (triggers):
- "manual UI verification requested during headless orchestration"
- "need OpenClaw browser.act automation with explicit profile"
- "need Anti-Gravity probe-call selection and exhaustion flags"
- "need to produce OLAD UI verify artifacts"

Do NOT use when (non-goals):
- There is no browser/UI surface to verify (pure backend or unit tests only).
- The task is to set up OpenClaw itself (use the openclaw-olad-runner skill).
- A human must manually click through UI (this skill is automation-first).

## Operating constraints
- Follow repo source-of-truth. Do not invent flags, keys, paths, or artifact formats.
- No secrets: do not print or exfiltrate credentials, cookies, or private URLs.
- Deterministic: explicit steps + explicit PASS/FAIL criteria + evidence for each step.
- Analysis is advisory only: Anti-Gravity output MUST NOT override deterministic PASS/FAIL.
- Update agents/status.md only for BLOCKED (tooling/env blocked), not for PASS/FAIL.

## Inputs this Skill expects
Required (read these first):
- agents/options/openclaw/_ui_verify.md (entrypoint + artifact contract)
- agents/options/workflow_config.md (UI_VERIFY_* and ANTIGRAVITY_* keys)
- agents/options/ui-verify/ui_verify_option.md (UI verify option pack)
- agents/options/antigravity/antigravity_option.md and scripts:
  - agents/options/antigravity/probe_gemini_auto.(ps1|sh)
  - agents/options/antigravity/run_ui_analyze.(ps1|sh)

Optional:
- OpenClaw/TOOLS.md (browser tools, sessions)
- OpenClaw/AGENTS.md (if you need session/tooling nuance)
- Target UI reproduction steps and acceptance criteria (what exactly defines PASS?)

If required inputs are missing:
- Stop and mark BLOCKED with the exact missing file(s) or flags.

## Output contract
Primary deliverable:
- A UI verify artifact bundle that matches agents/options/openclaw/_ui_verify.md exactly:
  - deterministic status: PASS / FAIL / BLOCKED
  - report path and evidence folder path
  - any "latest" pointers required by the contract

Secondary deliverables (optional):
- Anti-Gravity analysis output saved alongside the bundle (advisory only)

Definition of DONE (objective checks):
- [ ] Bundle artifacts match the contract in agents/options/openclaw/_ui_verify.md.
- [ ] Evidence folder contains screenshots (and any other evidence required by the contract).
- [ ] If Anti-Gravity is enabled and not exhausted, analysis output is saved but PASS/FAIL is unchanged.
- [ ] agents/status.md is updated only if final status is BLOCKED.

## Procedure (copy into working response and tick off)
Progress:
- [ ] 1) Read contracts and flags (no guessing)
- [ ] 2) Decide automation path (OpenClaw-only vs OpenClaw + Anti-Gravity)
- [ ] 3) Run OpenClaw browser.act deterministically with evidence capture
- [ ] 4) Determine PASS/FAIL/BLOCKED (deterministic)
- [ ] 5) Optional: run Anti-Gravity analysis with quota guard
- [ ] 6) Write artifacts + finalize summary

### 1) Read contracts and flags (no guessing)
- Open agents/options/openclaw/_ui_verify.md and extract:
  - artifact locations
  - required filenames (result.json, report.md, etc.)
  - required fields and status enum
  - any "latest" pointer rules
- Open agents/options/workflow_config.md and locate:
  - UI_VERIFY_* flags (including UI_VERIFY_BROWSER_PROFILE)
  - ANTIGRAVITY_* flags (enablement, probe preference order, exhaustion flag paths, cooldown if any)

### 2) Decide automation path
- If UI verify is not requested/enabled by flags: exit this skill.
- Confirm UI_VERIFY_BROWSER_PROFILE is explicitly set.
  - If missing: do NOT guess a profile; mark BLOCKED and report the required value.
- Determine whether Anti-Gravity analysis is enabled via ANTIGRAVITY_* flags.
  - If disabled: plan OpenClaw-only verification.

### 3) Run OpenClaw browser.act deterministically (flake-resistant)
Preflight:
- Start a fresh browser session/context using the configured UI_VERIFY_BROWSER_PROFILE.
- Use stable locators: roles/labels/test-ids over brittle CSS/XPath.
- Avoid fixed sleeps; prefer "wait for selector/condition" with explicit timeouts.

Execution pattern:
- (a) Navigate to the target URL.
- (b) Capture a "start" screenshot.
- (c) Perform each action step (click/type/navigate) one at a time.
- (d) After each critical step, capture evidence (screenshot + any available DOM snapshot).
- (e) At the end, validate explicit acceptance criteria and capture "end" evidence.

If flake occurs:
- Retry the single step once (not the whole flow).
- If still failing, classify as FAIL unless the environment/tooling is blocked (then BLOCKED).

### 4) Determine deterministic status (PASS/FAIL/BLOCKED)
- PASS: automation ran and acceptance criteria are met.
- FAIL: automation ran but acceptance criteria are not met OR the UI shows the defect.
- BLOCKED: automation cannot run due to environment/tooling constraints (auth wall, network unreachable,
  browser profile missing/corrupt, OpenClaw browser tool unavailable).

Only for BLOCKED:
- Set agents/status.md to "### BLOCKED" with:
  - the minimal evidence
  - the specific blocker
  - the next action required (one step)

For PASS/FAIL:
- Do NOT touch agents/status.md.

### 5) Optional: Anti-Gravity analysis with quota guard (advisory only)
Use the existing probe script; do not reimplement quota logic:
- agents/options/antigravity/probe_gemini_auto.(ps1|sh)

Ladder behavior (conceptual; confirm exact implementation in the script):
- Prefer Flash -> then Pro-low -> then Pro-high (or the preference order defined in workflow_config.md).
- If a model returns quota/rate-limit (often HTTP 429 / RESOURCE_EXHAUSTED):
  - write/update that model's exhaustion flag with a timestamp rounded/truncated to the minute
  - immediately fall back to the next model in the ladder
- If a model is marked exhausted recently (per cooldown rules in workflow_config.md or the script):
  - skip probing it and move to the next model
- If all models are exhausted:
  - skip Anti-Gravity and continue OpenClaw-only (do not mark BLOCKED)

If a model is available:
- Run agents/options/antigravity/run_ui_analyze.(ps1|sh) against the evidence bundle.
- Save analysis output alongside the UI verify artifacts.

Hard rule:
- Anti-Gravity analysis may add notes or suspected root cause, but MUST NOT change PASS/FAIL.

### 6) Write artifacts + finalize summary
- Write the artifact bundle exactly as specified in agents/options/openclaw/_ui_verify.md.
- Ensure the report includes:
  - status (PASS/FAIL/BLOCKED)
  - artifact bundle path
  - evidence folder path
  - short timeline of actions + key screenshots
  - if analysis ran: which model was used and whether exhaustion flags were set

If all UI automation paths are blocked and cannot be fixed quickly:
- Offer the smoketest-based verification path (find and point to the "no-manual" option docs under agents/options/ui-verify/).

## Pitfalls / gotchas (brutally honest)
- Profile not explicit -> browser.act fails or runs in the wrong state. See EXAMPLES.md (EX-2026-02-04-01).
- Evidence too sparse -> results are not auditable. See EXAMPLES.md (EX-2026-02-04-02).
- Treating 429 as "retry forever" -> causes retry storms; always fall back and mark exhausted. See EXAMPLES.md (EX-2026-02-04-03).
