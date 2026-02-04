---
name: ui-quality-gates
description: >
  Run one or more UI gates (a11y / perf / visual) deterministically and produce a single PASS/FAIL
  summary. Use when automated UI quality checks are required before merge or release.
compatibility:
  runners: ["codex-cli", "claude-code", "openclaw"]
  tools: ["Read", "Bash", "Write"]
  offline_ok: true
---

# UI Quality Gates

## Purpose
Run deterministic a11y/perf/visual gates and emit an auditable PASS/FAIL (or BLOCKED) report with saved artifacts.

## Quick start
Goal:
- Run one or more UI gates (a11y, perf, visual) deterministically and produce a single PASS/FAIL summary.

Use when (triggers):
- A PR or release requires automated a11y, performance, or visual regression checks.
- CI requires gate evidence before merge.
- You need impact counts, CWV metrics, or visual diff artifacts for a release.

Do NOT use when (non-goals):
- The task is a manual WCAG audit or screen-reader test (use accessibility-qa).
- The task is a design handoff review or code compliance review (use frontend-review).
- The task is a usability evaluation (use ui-heuristics-scorecard).

## Operating constraints
- No secrets: never embed API keys, tokens, passwords, private URLs.
- Be minimal: use existing harness commands and configs; do not add new dependencies unless forced.
- Be explicit: every threshold and policy must be stated in the report.
- Be deterministic: each gate has a fixed run configuration; record environment details.
- Keep SKILL.md short: gate-specific details live in the reference files linked below.

## Inputs this Skill expects
Required:
- `targets`: URLs/routes/components + states to check.
- `gates_to_run`: subset of `[a11y, perf, visual]`.
- Existing harness commands or config (don't add new deps unless forced).
- Thresholds/policies per selected gate:
  - **a11y:** impact thresholds + incomplete handling policy. See `./reference-axe.md`.
  - **perf:** score + CWV metric thresholds + environment settings. See `./reference-lighthouse.md`.
  - **visual:** baseline reference + diff threshold/approval policy + viewport matrix. See `./reference-visual.md`.

Optional:
- Baseline reports for comparison (perf/visual).
- Device or throttling overrides.

If required inputs are missing:
- Ask for the minimum missing item. If not provided, mark BLOCKED.

## Output contract

### Unified reports
- `ui_gates.md` — single report, one section per gate that ran. Each section: thresholds stated, artifact path, PASS/FAIL status.
- `ui_gates.json` — machine-readable mirror, one schema.

### Artifact layout
```
artifacts/ui-gates/
  a11y/     ← axe raw results (axe-results.json, HTML report if produced)
  perf/     ← Lighthouse report HTML + JSON
  visual/   ← diff images / snapshots
```

### Definition of DONE
- [ ] Each selected gate has artifacts saved.
- [ ] Each selected gate has explicit thresholds stated.
- [ ] Each selected gate has PASS/FAIL computed.
- [ ] Overall status: PASS only if all selected gates PASS (or per your policy).

## Procedure (copy into working response and tick off)
- [ ] 1) Confirm scope + thresholds/policies per gate
- [ ] 2) Locate existing scripts/configs for selected gates
- [ ] 3) Run gates (a11y → perf → visual, or parallel if harness supports it)
- [ ] 4) Save artifacts into per-gate folders under `artifacts/ui-gates/`
- [ ] 5) Compute PASS/FAIL per gate
- [ ] 6) Write `ui_gates.md` and `ui_gates.json`
- [ ] 7) Summarize regressions + next steps

### 1) Confirm scope + thresholds/policies
- List target URLs/routes/components and states.
- For each selected gate, state the thresholds and policies explicitly. If any are missing, mark BLOCKED and request them.

### 2) Locate existing scripts/configs
- Search for existing a11y, Lighthouse/LHCI, and visual regression scripts or configs.
- Prefer existing CI commands over new tooling.

### 3) Run gates
- Execute each selected gate using existing commands.
- Default order: a11y → perf → visual. Run in parallel only if the harness explicitly supports it.

### 4) Save artifacts
- a11y: save raw results to `artifacts/ui-gates/a11y/`.
- perf: save Lighthouse HTML + JSON to `artifacts/ui-gates/perf/`.
- visual: save diff images/snapshots to `artifacts/ui-gates/visual/`.

### 5) Compute PASS/FAIL per gate
- **a11y:** group violations by `cat.*` tags; count by impact; apply thresholds. Handle `incomplete` items per policy (never silently pass). See `./reference-axe.md`.
- **perf:** compare metrics to thresholds; record environment details (device, throttling, Chrome version). See `./reference-lighthouse.md`.
- **visual:** apply diff thresholds or approval policy; flag flaky diffs if detected. See `./reference-visual.md`.

### 6) Write reports
- `ui_gates.md`: one section per gate. Each section: gate name, thresholds, artifact path, result (PASS/FAIL), summary of issues.
- `ui_gates.json`: mirrors the report structure. Include gate name, status, issue counts, artifact paths.

### 7) Summarize regressions + next steps
- Top issues per gate, prioritized by severity/impact.
- Any gates that are BLOCKED and why.
- Recommended next steps (fixes, re-runs, escalations).

## Pitfalls / gotchas
- Treating a11y `incomplete` items as PASS hides manual review gaps.
- Changing throttling/device between perf runs makes results non-comparable.
- Missing visual baselines invalidate the comparison entirely.
- Running axe in JSDOM produces unreliable results for gating (notably `color-contrast`). Use a real browser.
- Single perf run variance can be high — prefer LHCI or multiple runs when possible.
- Unstable UI (animations, time-based content, random IDs) creates noisy visual diffs. Stabilize before trusting PASS/FAIL.

## Progressive disclosure
- a11y gate config (axe tags, runOnly, impact levels): `./reference-axe.md`
- perf gate config (LH metrics, CWV thresholds, determinism rules): `./reference-lighthouse.md`
- visual gate config (baselines, thresholds, flake reduction): `./reference-visual.md`

## Example References (concise summaries only)
1. **All three gates ran; mixed result** — a11y PASS, perf FAIL (LCP regression), visual PASS. See EXAMPLES.md (EX-2026-02-04-01).
2. **Blocked: visual baselines missing** — Gate could not run visual comparison without a baseline build. See EXAMPLES.md (EX-2026-02-04-02).
3. **Blocked: CI/perf config mismatch** — Local and CI throttling differed; perf results were not comparable. See EXAMPLES.md (EX-2026-02-04-03).
4. **Blocked: JSDOM/a11y incomplete policy** — axe in JSDOM produced unreliable `incomplete` set; gate could not determine PASS/FAIL. See EXAMPLES.md (EX-2026-02-04-04).

**Note:** Full examples with tags and trigger phrases are in `./EXAMPLES.md`.
