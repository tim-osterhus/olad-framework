# Workflow config

## INTEGRATION_COUNT=0
## INTEGRATION_TARGET=4
## INITIALIZED=false
## INTEGRATION_MODE=Medium

---

## Purpose

This file controls integration thoroughness and orchestration behavior.
Only `_customize.md` and `_orchestrate.md` should modify the top flags.

---

## Integration modes

### Manual
- Integration never runs automatically.
- Use `agents/_integrate.md` only when the user explicitly asks.
- Revamp steps:
  - Remove INTEGRATION gating guidance from `agents/prompts/decompose.md`.
  - Remove INTEGRATION gating guidance from `agents/skills/task-card-authoring-repo-exact/SKILL.md`.
  - Update `_orchestrate.md` to skip Integration unconditionally.

### Low
- Integration runs only when a task is explicitly tagged `INTEGRATION`.
- Decompose/task authoring should add the gate only for exceptionally complex tasks.
- No periodic (3-6 task) sweeps.
- Revamp steps:
  - Update `_orchestrate.md` to run Integration only when `INTEGRATION` gate is present.
  - Keep decompose/task authoring guidance narrowly scoped to exceptional tasks.

### Medium
- Integration runs when a task is tagged `INTEGRATION`.
- Also runs periodically every 3-6 tasks using `INTEGRATION_COUNT` + `INTEGRATION_TARGET`.
- Decompose/task authoring should add `INTEGRATION` for cross-cutting or feature clusters.
- Revamp steps:
  - Update `_orchestrate.md` to run Integration when `INTEGRATION` gate is present or when `INTEGRATION_COUNT >= INTEGRATION_TARGET`.
  - Update `_orchestrate.md` to advance `INTEGRATION_TARGET` 3→4→5→6→3 when Integration runs.
  - Keep gating guidance for cross-cutting tasks/feature clusters.

### High
- Integration runs every other task, regardless of tagging.
- Decompose/task authoring may still tag `INTEGRATION` when extra emphasis is needed.
- Revamp steps:
  - Update `_orchestrate.md` to run Integration when `INTEGRATION_COUNT >= 1` (every other task).
  - Keep `INTEGRATION_TARGET=1`.
  - Keep gating guidance for emphasis if desired.

---

## Mode change instructions (revamp checklist)

When switching modes, ensure all related files align:
- `_orchestrate.md` uses the selected mode logic.
- `agents/prompts/decompose.md` applies the correct gating guidance.
- `agents/skills/task-card-authoring-repo-exact/SKILL.md` reflects the current gate policy.
