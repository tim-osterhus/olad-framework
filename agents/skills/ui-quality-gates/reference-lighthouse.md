# Reference: Lighthouse Performance Gate (distilled)

Source pin:
- frontend-packet/Front-End-Design-Checklist-master/README.md (local copy, 2024-12-10) for the "watch for heavy shadows/gradients" performance note.

Note:
- Lighthouse and Core Web Vitals specifics below are included because this skill is explicitly about Lighthouse gating; they are not present in the four source folders inside `frontend-packet/`.

## What Lighthouse measures (performance-focused)
Lighthouse runs a lab (synthetic) performance audit and reports:
- A Performance score (0-100) based on weighted lab metrics.
- Lab metrics typically include: FCP, LCP, Speed Index, TBT, CLS.

Score interpretation (common shorthand):
- 90-100: good
- 50-89: needs improvement
- 0-49: poor

## Core Web Vitals (definitions + thresholds)
Core Web Vitals are user-experience metrics with standard thresholds:

LCP (Largest Contentful Paint): how quickly primary content appears
- good: <= 2.5s
- needs improvement: 2.5s - 4.0s
- poor: > 4.0s

CLS (Cumulative Layout Shift): visual stability
- good: <= 0.1
- needs improvement: 0.1 - 0.25
- poor: > 0.25

INP (Interaction to Next Paint): responsiveness (replaced FID)
- good: <= 200ms
- needs improvement: 200ms - 500ms
- poor: > 500ms

Lab vs field note:
- Lighthouse is lab-based; it reports lab metrics like TBT that correlate with responsiveness.
- Use Web Vitals thresholds as targets, but keep the "lab vs field" distinction explicit in reports.

## LHCI vs single Lighthouse runs
Single run:
- Best for ad-hoc local checks.
- Higher variance if environment changes (throttling, CPU load, cache state).

LHCI (Lighthouse CI):
- Best for gating.
- Usually runs in CI with a committed config and can enforce assertions.
- Often collects multiple runs and reports a representative value (implementation depends on config/tooling).

## Determinism rules for a performance gate
To make PASS/FAIL meaningful and repeatable:
- Fix the test environment (device emulation, throttling, CPU/network settings).
- Run the same URLs/routes, same build output, and same config.
- Record environment details in the report (Chrome version, throttling, CI runner).
- Prefer multiple runs or CI-driven runs when variance is high.

## Practical checklist (what to record in the perf section of `ui_gates.md`)
- Target URL(s)
- Tooling used (Lighthouse CLI vs LHCI)
- Config source (path + key settings)
- Performance score
- LCP, CLS, TBT (and any other gated metrics)
- PASS/FAIL thresholds (explicit)
- Any known variance sources (dynamic content, slow backend, cold cache)
