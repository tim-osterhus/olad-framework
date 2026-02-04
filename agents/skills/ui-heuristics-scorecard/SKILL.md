---
name: ui-heuristics-scorecard
description: >
  Performs a Nielsen heuristics usability review and produces a scored report with severity ratings. Use when you need a structured usability audit of a UI, flow, or page set.
# tags: ["ui", "heuristics", "usability"]
compatibility:
  runners: ["codex-cli", "claude-code", "openclaw"]
  tools: ["Read", "Write"]
  offline_ok: true
---

# UI Heuristics Scorecard

## Purpose
Provide a deterministic Nielsen-heuristics usability review with severity-scored issues and evidence, producing `ui_heuristics.md` / `ui_heuristics.json` artifacts.

## Quick start
Goal:
- Deliver a Nielsen heuristics review with issue severity ratings and evidence.

Use when (triggers):
- Asked to perform a usability or heuristic evaluation.
- Reviewing a flow for user control, feedback, and error handling.
- Preparing a structured UX audit report for stakeholders.
- Comparing multiple UI options for usability risks.

Do NOT use when (non-goals):
- The request is purely visual design fidelity / design-system conformance (use frontend-review).
- The request is automated accessibility/perf/visual gating (use ui-quality-gates).

## Operating constraints
- No secrets: never embed API keys, tokens, passwords, private URLs.
- Be minimal: smallest diffs; no drive-by refactors unless required.
- Be explicit: state assumptions and verify them where possible.
- Be deterministic: use the fixed 10 heuristics in ./reference.md.
- Keep SKILL.md short: details live in ./reference.md and ./EXAMPLES.md.

## Inputs this Skill expects
Required:
- Target UI pages or flows (URLs, routes, or screens).
- User goals for the flow (what the user is trying to accomplish).

Optional:
- Screenshots, recordings, or an interactive snapshot (OpenClaw if available).
- Known user complaints or support tickets.

If required inputs are missing:
- Ask for the minimum missing targets or proceed with assumptions and mark BLOCKED sections.

## Output contract
Primary deliverable:
- `ui_heuristics.md` with a section per heuristic and severity-tagged issues.
- `ui_heuristics.json` with heuristic IDs, issue counts, and severity ratings.

Secondary deliverables (only if needed):
- Evidence folder path(s) for screenshots or annotated images.

Definition of DONE (objective checks):
- [ ] Each of the 10 heuristics in ./reference.md has a pass/issue entry.
- [ ] Every issue has a severity rating (1-3) and evidence reference.
- [ ] `ui_heuristics.json` matches the report structure and counts.

## Procedure (copy into working response and tick off)
Progress:
- [ ] 1) Confirm scope and user goals
- [ ] 2) Capture evidence
- [ ] 3) Score against heuristics
- [ ] 4) Write report artifacts
- [ ] 5) Validate severity ratings
- [ ] 6) Summarize fixes

### 1) Confirm scope and user goals
- Restate the flow and user goal in one sentence.
- List the pages/screens reviewed.

### 2) Capture evidence
- Collect screenshots or recordings for each key step.
- Note error states and alternate paths.

### 3) Score against heuristics
- Use the 10 heuristics in ./reference.md as fixed categories.
- Assign severity 1-3 using the definitions and calibration examples in ./reference.md.

### 4) Write report artifacts
- Write `ui_heuristics.md` with per-heuristic findings.
- Write `ui_heuristics.json` with counts and severity totals.

### 5) Validate severity ratings
- Ensure severity reflects user impact and priority to fix.
- Flag any missing evidence or uncertain claims as BLOCKED.

### 6) Summarize fixes
- List top 3 usability risks and recommended fixes.

## Pitfalls / gotchas (keep this brutally honest)
- Mixing visual polish feedback into usability scores dilutes the report.
- Skipping evidence makes severity ratings hard to trust.
- Using non-standard heuristics breaks comparability across reviews.

## Progressive disclosure (one level deep)
- Heuristics and severity scale: ./reference.md

## Verification pattern (recommended for medium/high risk)
1) Capture evidence
2) Score each heuristic
3) Review severity consistency
4) Produce report artifacts
5) Confirm DONE checks

## Example References (concise summaries only)
1. **Worked evaluation** - Real heuristic-to-severity mappings used to calibrate severity assignment. See EXAMPLES.md (EX-2026-02-03-01).
2. **Blocked: redesign decision** - Severity-3 remediation required owner/design sign-off. See EXAMPLES.md (EX-2026-02-03-02).

**Note:** Full examples with tags and trigger phrases are in `./EXAMPLES.md`.
