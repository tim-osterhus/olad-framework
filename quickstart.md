# Quickstart

This guide shows how to use the OLAD framework end-to-end, exactly as intended.

## 1) Install the Framework in a Repo

1) Copy the contents of `olad-framework/` into the root of your target repo.
2) Ensure the `agents/` folder exists at repo root.
   - Example: `<repo-root>/README.md` and `<repo-root>/agents/_start.md`

If you already have an `agents/` directory, merge carefully and keep one set of entrypoints.

## 2) One-Time Customization (Recommended)

1) Start an agentic coding session at the root of your target repo.
2) Say: `Open agents/_customize.md and follow instructions.`
3) The agent scans the repo, asks any missing questions, and writes/edits:
   - `agents/spec.md`
   - `README.md`
   - `agents/outline.md`
   - `agents/tasks.md`
   - `agents/roadmap.md`
   - `agents/expectations.md`

After this step, the framework is tailored to your project.

Note: during customization, the agent will also ask which **model preset** you want and update `agents/model_config.md`. Performance variants are available for higher-reasoning models/settings.

## 3) Create or Update a Task

1) Edit `agents/tasks.md` and describe the current task.
2) If the work is large, ask the Advisor to break it into backlog task cards in `agents/tasksbacklog.md`.

## 4) Run the Orchestrated Workflow (Recommended)

1) Start an orchestration session at repo root.
2) Say: `Open agents/_orchestrate.md and follow instructions.`
3) The Orchestrator will run Builder → QA → (optional) Quickfix and archive completed tasks.

## 5) Manual Workflow (No Orchestration)

### A) Builder / Quickfix Agent

1) Start a dedicated agentic session at repo root.
2) Say: `Open agents/_start.md and follow instructions.`
3) The Builder creates a detailed prompt artifact under `agents/prompts/tasks/` and executes it.

Quickfix cycle:
- Builder hotfix: `Open agents/_hotfix.md and follow instructions.`

CCC gate (if `**Gates:** CCC` is set on the task):
- `Open agents/_ccc.md and follow instructions.`

Integration gate (if `**Gates:** INTEGRATION` is set on the task):
- `Open agents/_integrate.md and follow instructions.`

### B) QA Agent

1) Start a second dedicated agentic session at repo root.
2) Say: `Open agents/_check.md and follow instructions.`
3) The QA agent verifies the work and logs evidence.

Doublecheck cycle:
- QA doublecheck: `Open agents/_doublecheck.md and follow instructions.`

### C) Advisor Agent (Freeform)

1) Start a third session at repo root.
2) Say: `Open agents/_advisor.md and follow instructions.`
3) Use this agent for scoping, research, explanations, backlog task-card creation, and any other odd jobs.
   - If you want a structured flow that produces a detailed spec + ordered backlog cards, use `agents/_decompose.md`.
4) The Advisor should rely on `agents/outline.md` for repo context and only log to `agents/historylog.md` when performing concrete actions beyond writing task cards (prepend new entries at the top).
5) If you need new roles or skills:
   - Role: `agents/_roleplay.md` (interactive) or `agents/prompts/role_create.md` (minimal)
   - Skill: `agents/_skillissue.md` (interactive) or `agents/prompts/skill_create.md` (minimal)

## 6) Change Model Assignments (Optional)

If you use a runner or orchestration tool, update model assignments in its config.
For manual runs, change the model in your agentic tool or CLI before starting a session.
