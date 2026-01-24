# Lean Agentic Development (OLAD) Framework

This document describes the current, repo-specific workflow. It is role-driven, artifact-driven, and designed to keep changes minimal, auditable, and easy to validate in headless runs.

## 1) Entry points (how work starts)

- **Active task source:** `agents/tasks.md` is the single source of truth for the current task.
- **Builder entry:** `agents/_start.md` is the Builder entrypoint.
- **QA entry:** `agents/_check.md` is the QA entrypoint.
- **Hotfix entry:** `agents/_hotfix.md` is the Builder entrypoint for quickfix cycles.
- **Doublecheck entry:** `agents/_doublecheck.md` is the QA entrypoint for quickfix cycles.
- **Integration entry:** `agents/_integrate.md` for integration sweeps and reports.
- **Advisor entry:** `agents/_advisor.md` for freeform advisory or scoping work.
- **Orchestrator entry:** `agents/_orchestrate.md` for headless orchestration across tasks.

Optional (manual) utilities:

- **Decomposer prompt:** `agents/prompts/decompose.md` to turn a raw idea into a spec + ordered backlog task cards.
- **Role Builder prompt:** `agents/prompts/roleplay.md` to generate a new, repo-consistent role file.
- **Skill Builder prompt:** `agents/prompts/skill_issue.md` to generate a new, repo-consistent skill folder + index entry.

If there is no active task, the agent must stop and request one.

## 2) Roles and specialization (how work is executed)

Roles live in `agents/roles/`. Only one role should be active at a time, and role switches must be explicit.

- **Planner/Architect:** converts task requirements into a scoped plan and checkpoints.
- **Specialist roles:** perform implementation or validation (e.g., frontend, QA).
- **QA/Test Engineer:** validation role for QA and doublecheck runs.
- **Orchestrator/Runner:** spawns headless runs and moves task cards; does not implement changes.

## 3) Skills (how reusable guidance is applied)

Skills live in `agents/skills/` and are indexed in `agents/skills/skills_index.md`.

- At the start of a cycle, the agent scans the index and selects up to three relevant skills.
- Skills are applied during the workflow to guide decisions and reduce regressions.
- If a repeatable lesson emerges, the agent updates the skill examples and references.

## 4) Prompt artifacts (how plans are executed)

Prompt artifacts live in `agents/prompts/tasks/` and capture a task’s plan and constraints when you choose a prompt-driven flow.

- Create a prompt artifact via `agents/prompts/create_prompt.md` when needed.
- Execution follows `agents/prompts/run_prompt.md`.
- Completed prompt artifacts are moved to `agents/prompts/completed/`.

## 5) Status signaling (authoritative flags)

`agents/status.md` is the authoritative signaling file for headless orchestration.

Expected flags:
- `### INTEGRATION_COMPLETE`
- `### BUILDER_COMPLETE`
- `### QA_COMPLETE`
- `### QUICKFIX_NEEDED`
- `### BLOCKED`
- `### IDLE`

The Orchestrator treats the latest flag as authoritative and clears it to `### IDLE` after acting.

## 6) Builder cycle (build workflow)

The Builder cycle is defined in `agents/prompts/builder_cycle.md` and `agents/_start.md`.

1) **Read context**
   - Read `agents/outline.md` and `agents/tasks.md`.
2) **Select skills**
   - Scan `agents/skills/skills_index.md` and choose up to three relevant skills.
3) **PROMPT gate (if present)**
   - If `**Gates:** PROMPT` is set, create a prompt artifact via `agents/prompts/create_prompt.md`, save it to the task-specified path, and use it as the authoritative plan.
4) **Plan**
   - Activate Planner/Architect and produce a scoped plan with checkpoints.
5) **Implement**
   - Keep diffs minimal and scoped to checkpoints.
6) **Verification**
   - Run small, targeted verification commands when applicable.
7) **Completion signal**
   - Write `### BUILDER_COMPLETE` to `agents/status.md`.
8) **Blockers**
   - If blocked, write `### BLOCKED` to `agents/status.md` and stop.

Builder runs must stay strictly within this repo and must not read/write outside it.

## 7) QA cycle (validation workflow)

The QA cycle is defined in `agents/_check.md` and `agents/prompts/qa_cycle.md`.

1) **Read requirements only**
   - Read `agents/outline.md` and `agents/tasks.md`.
   - Do not inspect diffs or history yet.
2) **Write expectations**
   - Create/overwrite `agents/expectations.md`.
3) **Inspect implementation**
   - Review history and diffs after expectations are locked.
4) **Validate**
   - Run required commands and verify constraints.
5) **Outcome signaling**
   - If all expectations are met: write `### QA_COMPLETE` to `agents/status.md`.
   - If gaps exist: update `agents/quickfix.md` and write `### QUICKFIX_NEEDED`.
   - If blocked: write `### BLOCKED`.

QA runs must stay strictly within this repo and must not read/write outside it.

## 8) Quickfix flow (hotfix + doublecheck)

Quickfix is triggered only when QA writes `### QUICKFIX_NEEDED`.

1) **Hotfix (Builder)**
   - Primary input: `agents/quickfix.md`
   - Context: `agents/tasks.md`
   - Signal completion via `### BUILDER_COMPLETE` in `agents/status.md`.
2) **Doublecheck (QA)**
   - Primary input: `agents/quickfix.md`
   - Context: `agents/tasks.md`
   - Signal `### QA_COMPLETE` or `### QUICKFIX_NEEDED`.

Hotfix and Doublecheck runs must stay strictly within this repo and must not read/write outside it.

## 9) Orchestrator flow (headless automation)

The Orchestrator (`agents/_orchestrate.md`) runs the full loop:

1) Ensure an active task exists in `agents/tasks.md`; promote from `agents/tasksbacklog.md` if empty.
2) Spawn Builder with the exact prompt: `Open agents/_start.md and follow instructions.`
3) Run Integration based on the configured integration behavior or when `**Gates:** INTEGRATION` is set.
4) Spawn QA with the exact prompt: `Open agents/_check.md and follow instructions.`
5) If QA signals `### QUICKFIX_NEEDED`, run Hotfix then Doublecheck.
6) On `### QA_COMPLETE`, archive the task card and continue to the next one.

Models and runners are configured in `agents/model_config.md`.
Integration behavior is configured during customization.

Preset options:
- Default: Codex for Integration/Builder/Hotfix, Claude for QA/Doublecheck.
- All Codex: Codex for all cycles.
- All Claude: Claude for all cycles.
- Custom: per-cycle runner + model ids.
Performance variants: each preset can be upgraded to higher-reasoning models/settings via `agents/model_config.md`.

## 10) Logs and reporting (continuity layer)

- **Status:** `agents/status.md` is the authoritative orchestration signal.
- **Quickfix log:** `agents/quickfix.md` tracks open QA gaps.
- **Expectations:** `agents/expectations.md` captures QA success criteria.
- **History log:** `agents/historylog.md` is used when tasks explicitly require logging or when manual runs document outcomes.

## 11) Safety and guardrails

- **Environment constraints:** respect deployment limits (offline, air-gap, latency, cost).
- **Data handling:** follow privacy, security, and compliance requirements.
- **Quality gates:** do not ship without required verification and review.
- **No secrets** in repo or logs.

Agents must stop if requirements are unclear or if verification is blocked by missing setup.

## 12) Stop conditions

Stop and signal blockers when:
- Tasks are unclear or incomplete.
- Required tests cannot be run.
- A dependency is missing.
- Any requirement conflicts with guardrails.

## 13) Files to know

- Entry points: `agents/_integrate.md`, `agents/_start.md`, `agents/_check.md`, `agents/_hotfix.md`, `agents/_doublecheck.md`, `agents/_advisor.md`, `agents/_orchestrate.md`
- Tasks: `agents/tasks.md`, `agents/tasksbacklog.md`, `agents/tasksarchive.md`
- Prompt artifacts: `agents/prompts/tasks/`, `agents/prompts/run_prompt.md`
- Signals/logs: `agents/status.md`, `agents/quickfix.md`, `agents/expectations.md`, `agents/historylog.md`
- Skills: `agents/skills/skills_index.md`, `agents/skills/**/SKILL.md`, `agents/skills/**/EXAMPLES.md`

---

This framework is intentionally strict: it prevents drift, keeps changes reviewable, and makes QA reproducible.
