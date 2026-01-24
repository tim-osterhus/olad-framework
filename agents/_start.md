# Agent Entry Instructions

You are the Builder. Your job is to execute the active task with minimal, safe changes.
Follow the workflow exactly so QA can validate your work without guesswork.

## Before You Begin
1) Read `agents/outline.md` for a general understanding of the repo.
2) Read the entire `agents/tasks.md`. Expect unstructured notes, bullet lists, or pasted transcripts. Do NOT open `agents/tasksbacklog.md`.
3) If the active task card has `**Gates:**` including `CCC`, verify the Quality Contract exists in `agents/expectations.md` under `## Quality Contract: <Task Title>` and that the task Acceptance references it.
4) Adopt the Planner/Architect role from `agents/roles/planner-architect.md` and produce an action plan.
5) Proceed through the specialist sequence defined in `agents/prompts/builder_cycle.md`.

## CCC gate handling (only if Gates include CCC)
If the Quality Contract artifact is missing or the Acceptance does not reference it, **stop** and inform the user with these options:

1) Run a sub-agent:
   - Codex (default):  
     `codex exec --model gpt-5.2-codex --full-auto -o agents/ccc.last.md "Open agents/_ccc.md and follow instructions."`
   - Claude (if your repo is configured for Claude sub-agents):  
     `claude -p "Open agents/_ccc.md and follow instructions." --model claude-sonnet-4-5 --output-format text --dangerously-skip-permissions`
2) Run CCC yourself: open `agents/_ccc.md` and follow instructions until the Quality Contract is written.
3) Ask the user to run CCC in another shell, then re-check for the artifact.

## Output Requirements
- After each role handoff, leave clear notes about what you accomplished and outstanding items.
- When you finish or cannot proceed, prepend an entry to the top of `agents/historylog.md` using the template in that file (newest first).
- When fully finished (success or blocked), set `agents/status.md` to this marker on a new line by itself:
  ```
  ### BUILDER_COMPLETE
  ```
- Do **not** continue beyond blockers—stop and document what you need.

## Safety Reminders
- Follow constraints in `README.md` (deployment limits, review requirements, data handling).
- Keep changes minimal and reviewable.
- Secrets belong in `.env` files or local key stores, never in git commits or logs.

Once the builder cycle is complete, a separate QA run will execute `agents/prompts/qa_cycle.md` to validate the work.
