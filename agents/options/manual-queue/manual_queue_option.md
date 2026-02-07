# Manual Queue Option (Non-blocking UI Verification)

Goal: keep orchestration moving when QA needs human UI verification by offloading those checks into a tracked checklist file.

This option changes QA behavior:
- QA must NOT stop the workflow solely because a manual UI check is needed.
- Instead, QA appends a checklist item to `agents/manualtasks.md` and continues validating everything else headlessly.

## Behavior rules (required)

- If a check requires human UI verification and cannot be automated with the current tooling:
  - Do NOT set `agents/status.md` to `### BLOCKED` for that reason alone.
  - Append a checklist item to `agents/manualtasks.md`.
  - Continue QA as normal.
- Manual tasks must map to a specific feature/work unit so failures are easy to trace and fix.
- Only set `### BLOCKED` for true blockers (failing build, missing deps, cannot run required commands, missing credentials that block all validation, etc.).

## Manual task format (checklist)

```
- [ ] <feature/work unit> — <what to verify> (refs: <files>, <run folder>, <bundle>, <commit>)
```

Example:

```
- [ ] Login page — verify error states & loading spinner match spec (refs: ui/login.md, agents/runs/2026-02-07_120102/, commit abc123)
```

## Install

### A) Create the canonical manual tasks file

If `agents/manualtasks.md` does not exist:
- Copy `agents/options/manual-queue/manualtasks_template.md` -> `agents/manualtasks.md`

### B) Install the QA cycle variant

Replace:
- `agents/prompts/qa_cycle.md`

With:
- `agents/options/manual-queue/qa_cycle_manual_queue.md`

### C) Patch QA entrypoints to reflect the policy (recommended)

Add a single bullet under "Execute validation" in each file:
- `agents/_check.md`
- `agents/_doublecheck.md`

Add:
- `Manual UI verification is non-blocking in this repo. If a manual UI check is required, append it to \`agents/manualtasks.md\` and continue QA.`

## Notes

- `agents/manualtasks.md` is a tracked repo artifact (like `agents/historylog.md`): it should be kept high-signal and easy to triage.
- This option is compatible with smoketest modes:
  - If you later enable Quick/Thorough smoketests, prefer smoketests to replace manual checks, and use `agents/manualtasks.md` only for truly non-automatable checks.

