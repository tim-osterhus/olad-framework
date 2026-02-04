# Examples (UI Quality Gates)

Append new examples to the END of this file and never change existing Example IDs.

---

## EX-2026-02-04-01: All three gates ran - mixed result

**Tags**: `a11y`, `perf`, `visual`, `gate`, `mixed`

**Trigger phrases**:
- "all gates"
- "mixed gate result"
- "perf FAIL a11y PASS"
- "three gates ran"

**Date**: 2026-02-04

**Problem**:
A release required all three UI quality gates (a11y, perf, visual) before shipping. The gates were run in sequence against the same target routes.

**Impact**:
Shipping was blocked until the perf regression was addressed; the other two gates were green.

**Cause**:
A recent layout change introduced a larger hero image without lazy-loading, causing an LCP regression above the threshold. The a11y and visual gates were unaffected.

**Fix**:
- Ran all three gates using existing harness commands.
- Saved artifacts to `artifacts/ui-gates/{a11y,perf,visual}/`.
- Computed per-gate PASS/FAIL:
  - **a11y:** PASS — zero critical/serious violations against WCAG 2.1 AA; two `incomplete` items flagged for manual review per policy.
  - **perf:** FAIL — LCP = 3.2s, threshold = 2.5s. CLS and TBT within thresholds.
  - **visual:** PASS — zero unexpected diffs against committed baselines.
- Wrote `ui_gates.md` with one section per gate and overall status FAIL (perf blocked).
- Wrote `ui_gates.json` mirroring the report.

**Prevention**:
- Image optimization check (lazy-load, size budget) is part of the perf gate procedure.
- All three gates run on every release candidate.

**References**:
- `ui_gates.md`
- `ui_gates.json`
- `artifacts/ui-gates/`

---

## EX-2026-02-04-02: Blocked - visual baselines missing

**Tags**: `visual`, `blocked`, `baselines`

**Trigger phrases**:
- "baselines missing"
- "no baseline build"
- "visual gate blocked"
- "first run no baseline"

**Date**: 2026-02-04

**Problem**:
The visual gate was selected for a new feature branch, but no baseline screenshots existed (the feature introduced entirely new pages not present on main).

**Impact**:
The gate could not produce a meaningful diff. Running it would produce 100% "new" diffs with no signal, making PASS/FAIL meaningless.

**Cause**:
Baseline generation was not part of the feature's branch workflow. The visual gate assumes a known-good baseline exists.

**Fix**:
- Marked the visual gate BLOCKED.
- Ran a11y and perf gates normally (they do not depend on baselines).
- Generated baseline screenshots on the feature branch and committed them as the initial baseline.
- Re-ran the visual gate after baseline establishment — PASS (zero diffs against the just-committed baseline).
- Documented in `ui_gates.md`: visual gate was initially blocked, baseline was generated, gate re-run passed.

**Prevention**:
- New-page features must include a baseline-generation step before the visual gate is enforced.
- See `./reference-visual.md` (baselines section).

**References**:
- `ui_gates.md`
- `artifacts/ui-gates/visual/`

---

## EX-2026-02-04-03: Blocked - CI/perf config mismatch

**Tags**: `perf`, `blocked`, `lhci`, `ci`, `config`

**Trigger phrases**:
- "throttling mismatch"
- "CI config mismatch"
- "local perf differs from CI"
- "lhci assert failed"

**Date**: 2026-02-04

**Problem**:
A perf gate was requested, but local Lighthouse runs produced scores inconsistent with CI (LHCI). The throttling and device settings differed between environments, making local PASS meaningless against CI thresholds.

**Impact**:
PASS/FAIL was unreliable. A local "PASS" could still fail CI, or a local "FAIL" could be noise from environment drift.

**Cause**:
No single source-of-truth config for device emulation, throttling, and run count. Local and CI ran with different defaults.

**Fix**:
- Marked the perf gate BLOCKED.
- Identified the canonical LHCI config (committed in repo) and its environment settings.
- Re-ran the gate using the exact CI config locally (or required the run to happen in CI).
- Once results matched, computed PASS/FAIL against thresholds.

**Prevention**:
- Commit and document the canonical LHCI config and environment settings. See `./reference-lighthouse.md` (determinism rules).
- Never make PASS/FAIL claims from a local run unless the config matches CI exactly.

**References**:
- `ui_gates.md`
- `artifacts/ui-gates/perf/`

---

## EX-2026-02-04-04: Blocked - JSDOM/a11y incomplete policy

**Tags**: `a11y`, `blocked`, `jsdom`, `incomplete`

**Trigger phrases**:
- "JSDOM a11y"
- "color-contrast incomplete"
- "a11y gate blocked JSDOM"
- "incomplete policy"

**Date**: 2026-02-04

**Problem**:
The a11y gate was run in a Jest/JSDOM harness. Results included a large `incomplete` set and known-broken rules (notably `color-contrast`), making the output untrustworthy for gating.

**Impact**:
The gate could not produce a deterministic PASS/FAIL. Treating the output as authoritative would either block unnecessarily or silently miss real issues.

**Cause**:
JSDOM has limited axe-core support. Some rules are unsupported or yield "needs review" results, which breaks a deterministic gate.

**Fix**:
- Marked the a11y gate BLOCKED.
- Recommended switching to a real-browser harness (Playwright/WebDriver) for gating.
- If switching was not feasible short-term: disabled only the unsupported rule(s) with explicit justification, treated remaining `incomplete` items as FAIL per policy, and added a follow-up manual check requirement.

**Prevention**:
- a11y gating must use a real browser. See `./reference-axe.md` (practical notes).
- Pin `runOnly` tags and the `incomplete` policy so results are comparable across runs.

**References**:
- `ui_gates.md` (blocked status)
- `artifacts/ui-gates/a11y/`

<!--
Add new examples below this line.
-->
