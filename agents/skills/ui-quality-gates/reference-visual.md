# Reference: Visual Regression Gate (distilled)

Source pin:
- frontend-packet/Front-End-Design-Checklist-master/README.md (local copy, 2024-12-10) for state coverage and responsive expectations.

Note:
- Visual regression tool specifics (Playwright/Chromatic snapshot workflows, thresholds) are included because this skill is explicitly about visual regression gating; they are not present in the four source folders inside `frontend-packet/`.

## What visual regression is (baseline -> diff)
Visual regression compares a "current" screenshot/render to a known-good baseline:
- baseline: what main (or last approved build) looks like
- current: what the PR/build produces
- diff: per-pixel (or per-snapshot) changes between baseline and current

## Baselines (where they live)
Common baseline storage patterns:
- Committed snapshots in the repo (e.g., Playwright snapshot files)
- Hosted baselines in a service (e.g., Chromatic) tied to a main-branch build

Rule:
- Baselines are production-critical. Only update them when diffs are intentional and approved.

## Thresholds (what "PASS" means)
Common threshold knobs:
- max changed pixels (absolute): "allow <= N pixels changed"
- max diff ratio (percentage): "allow <= X% changed"
- pixelmatch threshold (sensitivity): controls what counts as "different"

Practical guidance:
- Default to strict thresholds (often zero unexpected diffs).
- If you must allow tolerance, document the exact threshold and why (fonts/antialiasing differences, subpixel layout).

## Snapshot update workflow (deterministic)
1) Run visual tests on the PR branch.
2) If diffs are unexpected, fix UI.
3) If diffs are expected, update snapshots using the tool's snapshot update mechanism (e.g., an "update snapshots" flag) and commit them.
4) Treat baseline updates as "requires review" changes.

## Flake reduction checklist (make diffs stable)
Most "false diffs" come from instability. Mitigate before trusting PASS/FAIL:
- Fix viewport sizes and DPR across environments.
- Disable animations and transitions during snapshot runs.
- Freeze time and randomness (date/time, seeded RNG).
- Use deterministic test data/fixtures; avoid live data.
- Ensure fonts are stable (self-host where possible; avoid late-loading causing layout shifts).
- Hide or mock dynamic widgets (ads, external embeds, personalization).

## State and responsive coverage (from the design checklist)
- Capture interactive states where applicable: hover, focus, active, disabled.
- Capture responsive layouts: at least mobile + desktop; add tablet when required.
