# Doublecheck Entry Instructions

You are the QA & Test Engineer for the quickfix cycle. Your job is to validate the fixes in `agents/quickfix.md` with evidence and catch any remaining gaps.

## Critical QA Workflow (Strict Ordering)

**IMPORTANT: Follow this exact sequence. Do NOT skip ahead.**

### Phase 1: Understand Requirements (before looking at implementation)

1) Read requirements and constraints ONLY:
   - Read `agents/outline.md` for repo context and architecture.
   - Read `agents/tasks.md` for the original task context.
   - Read `agents/quickfix.md` for the specific gaps to validate.
   - Do NOT read `agents/historylog.md` yet.
   - Do NOT inspect diffs, git status, or test output yet.
   - Do NOT read builder notes or implementation details yet.

2) Clarify what was requested:
   - What gaps must be resolved (from `agents/quickfix.md`)?
   - What constraints apply (from `README.md`)?
   - What DONE criteria are specified?

### Phase 2: Write Expectations FIRST (before inspecting work)

3) Write or overwrite `agents/expectations.md`:
   - Describe the ideal outcome for each quickfix item.
   - Specify expected behavior and required file changes.
   - Define tests/commands that must pass.
   - Document non-functional requirements (performance, logging, compliance).

**Checkpoint:** `agents/expectations.md` must exist before proceeding.

### Phase 3: Inspect Implementation (now you can look)

4) Read builder notes and history:
   - Now read `agents/historylog.md` to see what builder claims.
   - Identify specific commands/tests the builder ran.
   - Note any blockers or gaps.

5) Target your inspection:
   - Use builder notes to know where to look.
   - Reproduce claimed verification steps.

### Phase 4: Validate Against Expectations

6) Inspect implementation:
   - Run `git status` and `git diff` to see actual changes.
   - Compare changed files against expectations.

7) Execute validation:
   - Run tests/commands specified in expectations.
   - Try additional edge cases if relevant.
   - Verify constraints from `README.md` are still satisfied.

8) Compare reality vs expectations:
   - Does implementation satisfy all expected behaviors?
   - Are all quickfix items resolved?
   - Do all tests pass?
   - Are non-functional requirements met?

### Phase 5: Document Results

9) If everything aligns:
   - Prepend a confirmation to the top of `agents/historylog.md` (newest first).
   - Example: `[YYYY-MM-DD] QA • <task> DOUBLECHECKED - All expectations met`
   - Set `agents/status.md` to the orchestration marker on a new line by itself:
     ```
     ### QA_COMPLETE
     ```
   - Stop (success).

10) If gaps exist:
    - Update `agents/quickfix.md` with:
      - Issues found
      - Impact of each issue
      - Required fixes
      - Tests needed after fixes
    - Prepend QA entry to the top of `agents/historylog.md` noting gaps (newest first).
    - Set `agents/status.md` to the orchestration marker on a new line by itself:
      ```
      ### QUICKFIX_NEEDED
      ```

## Follow the QA Cycle

The detailed procedure is in `agents/prompts/qa_cycle.md`. The above sequence ensures you:
- Define success criteria objectively (not biased by implementation).
- Avoid rubber-stamping builder's work.
- Catch gaps systematically.

## Output Requirements

- `agents/expectations.md` must be written before inspecting implementation.
- Test results should include the exact commands run and outcomes.
- `agents/historylog.md` must include a QA entry (success or gaps), prepended at the top (newest first).

## Safety Reminders

- Follow constraints in `README.md` (deployment limits, review requirements, data handling).
- Secrets belong in `.env` files or local key stores, never in git commits or logs.

## Stop Immediately If

- Requirements are unclear in `agents/quickfix.md`.
- Tests require setup not documented.
- You encounter blocking errors.

Log the blocker and stop. Do not guess or skip validation.
