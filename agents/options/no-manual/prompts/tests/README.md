# QA Smoketest Artifacts (`agents/prompts/tests/`)

Tracked smoketest artifacts live here while they are active (in-progress or being used by QA).

## Naming

- Use `NNN-<slug>.md` (zero-padded), starting at `001`.
- This numbering is independent from task prompt artifacts in `agents/prompts/tasks/`.

## Format

Use a small Markdown checklist + commands:

- Goal (1-2 bullets)
- Setup prerequisites (services/env vars/fixtures)
- Commands (copy/paste)
- Expected results (explicit)

## Lifecycle

1) Create or update a smoketest artifact here.
2) Run the commands during QA and record evidence.
3) Only when QA ends with `### QA_COMPLETE`, move the smoketest artifact to:
   - `agents/prompts/tests/completed/`

If QA does NOT complete successfully (e.g., `### QUICKFIX_NEEDED` or `### BLOCKED`), keep the smoketest artifact in this folder (it is not "completed" yet).

## Reuse rule

Never edit files under `agents/prompts/tests/completed/` in place.
If you want to reuse a completed smoketest, copy it back into this folder with a NEW number/name, then edit the copy.
