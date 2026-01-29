# No-Manual QA Option (Smoketests)

Goal: optionally prevent QA from requesting human/manual verification during headless runs by replacing manual checks with tracked smoketest artifacts.

This option installs a QA-side "prompt artifact" pipeline:
- Staging: `agents/prompts/tests/`
- Archive: `agents/prompts/tests/completed/` (archive only on `### QA_COMPLETE`)

## Modes

Choose exactly one:

1) Manual Allowed (default)
- No changes. QA may request manual verification.

2) Quick Smoketests
- QA must NOT request manual verification.
- If a manual check would be required, QA creates/updates a smoketest artifact directly in `agents/prompts/tests/` (Markdown checklist + commands).
- No new skills are authored during QA.

3) Thorough Smoketests
- QA must NOT request manual verification.
- If a manual check would be required, QA tries to apply a relevant smoketest skill (stack-specific).
- If no relevant smoketest skill exists, QA authors one via `agents/prompts/skill_issue.md` **without asking clarifying questions** (assume conservative defaults, document assumptions), then applies it to produce the smoketest artifact.

## Install (Quick or Thorough)

### A) Install the smoketest artifact folders

Create:
- `agents/prompts/tests/`
- `agents/prompts/tests/completed/`

Copy these files from this option packet into the new folders:
- `agents/options/no-manual/prompts/tests/README.md` -> `agents/prompts/tests/README.md`
- `agents/options/no-manual/prompts/tests/completed/README.md` -> `agents/prompts/tests/completed/README.md`

### B) Install the Smoketest Engineer role

Copy:
- `agents/options/no-manual/roles/smoketest-engineer.md` -> `agents/roles/smoketest-engineer.md`

### C) Install the QA cycle variant

Replace `agents/prompts/qa_cycle.md` with ONE of:
- Quick: `agents/options/no-manual/qa_cycle_quick.md`
- Thorough: `agents/options/no-manual/qa_cycle_thorough.md`

### D) Patch QA entrypoints to reflect the policy

If you enabled Quick or Thorough, add a single bullet to each file under "Execute validation":
- `agents/_check.md`
- `agents/_doublecheck.md`

Add:
- `Do not request human/manual verification. Use smoketests under \`agents/prompts/tests/\` per \`agents/prompts/qa_cycle.md\`.`

## Notes

- Smoketest artifacts are tracked repo files. Keep them small and deterministic.
- Reuse policy:
  - Never edit anything under `agents/prompts/tests/completed/`.
  - If reusing a completed smoketest, copy it back into `agents/prompts/tests/` with a NEW number/name, then edit the copy.
- The no-manual policy should keep `agents/expectations.md` unbiased:
  - If a smoketest is needed, create it and reference its commands BEFORE inspecting implementation.
