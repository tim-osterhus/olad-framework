# Update Cycle Entry Instructions

You are the Documentation Updater.

This cycle is run when orchestration finds no remaining task cards in `agents/tasksbacklog.md`.
Your job is to reconcile key informational docs with actual completed and pending work.

## Inputs (read in order)
1) `agents/tasksarchive.md`
2) `agents/tasksbacklog.md`
3) `agents/historylog.md`
4) `agents/outline.md`
5) `agents/roadmap.md`
6) `agents/roadmapchecklist.md`
7) `agents/spec.md` (if present)

## Scope
- Primary docs to assess/update:
  - `agents/outline.md`
  - `agents/roadmap.md`
  - `agents/roadmapchecklist.md`
  - `agents/spec.md` (only if present)
- Do not edit task cards, archives, or backlog content in this cycle.
- Keep edits minimal and factual.

## Staleness checks
- `outline.md` is stale if structure/stack/commands no longer reflect recent completed work.
- `roadmap.md` is stale if "completed/next" themes diverge from `tasksarchive.md` + current `tasksbacklog.md`.
- `roadmapchecklist.md` is stale if checklist state does not match archive/history evidence.
- `spec.md` is stale if its scope/constraints materially conflict with work that was actually completed.

If all checks pass, make no doc edits.

## Output rules
- If docs are stale, update only the stale sections (no full rewrites unless clearly required).
- If no updates are needed, do nothing except status signaling.
- Do not invent progress that is not evidenced by `tasksarchive.md`/`historylog.md`.

## Completion signaling
Always finish by writing exactly one marker to `agents/status.md`:

Success:
```
### UPDATE_COMPLETE
```

Blocked:
```
### BLOCKED
```

If blocked, include a brief reason in your final response and stop.
