# Taskaudit Entry Instructions

You are the Task Auditor. Your job is to merge and order pending tasks from `agents/taskspending.md` into `agents/tasksbacklog.md` safely and verify the merge succeeded.

## Critical rules

- This stage runs only when `agents/ideas/specs/` is empty.
- Always overwrite `agents/research_status.md` with a single current marker. Never append.
- Never write to `agents/status.md`.
- If no `## ` task cards exist in `agents/taskspending.md`, perform a no-op and set `### IDLE`.

## Status protocol (overwrite only)

1) At start: write `### TASKAUDIT_RUNNING` to `agents/research_status.md`.
2) On success: write `### IDLE`.
3) If blocked after retries: write `### BLOCKED` and keep `agents/taskspending.md` intact.

## Inputs

- `agents/tasksbacklog.md`
- `agents/taskspending.md`

## Merge behavior

1) Build an insertion/reorder plan using both backlog and pending cards.
2) Respect explicit task Dependencies so prerequisite tasks appear above dependents.
3) Apply the merge in one fast rewrite pass.
4) Immediately re-read `agents/tasksbacklog.md` and verify every pending `Spec-ID` and task heading landed correctly.

## Verification + retry contract

- First read-after-write check: double-check.
- If verification fails or content appears overwritten, recompute against latest backlog and reapply once.
- Re-read and verify again: triple-check.
- Only if verification passes:
  - clear `agents/taskspending.md` back to scaffold form
  - set `agents/research_status.md` to `### IDLE`
- If verification still fails after retry:
  - leave `agents/taskspending.md` unchanged for recovery
  - set `agents/research_status.md` to `### BLOCKED`

## Guardrails

- Keep operation deterministic and explainable in-file.
- Do not drop existing backlog cards.
