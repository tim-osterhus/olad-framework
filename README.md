![License](https://img.shields.io/badge/license-Apache%202.0-blue)
![Status](https://img.shields.io/badge/status-active-success)
![Contributions by invite](https://img.shields.io/badge/Contributions-invite%20only-orange)

# OLAD Framework

Orchestrative Lean Agentic Development (OLAD) is a lightweight, project-agnostic framework for running agentic development with clear roles, repeatable prompts, deterministic orchestration, and consistent logging.

To get started ASAP, check out `quickstart.md`.

## What This Gives You

- A standard way to run multi-agent work without chaos.
- A stable structure for task prompts, QA, and history logging.
- A deterministic orchestration loop with clear status signaling.
- A repeatable onboarding flow that makes a repo “agent-ready.”

## How It Works (High Level)

The framework defines a small set of agent entrypoints and artifacts:

- **Builder**: implements tasks and small fixes quickly and safely.
- **QA**: verifies changes and records evidence.
- **Advisor**: handles freeform tasks like scoping work, explaining code, or drafting backlog task cards.
- **Orchestrator**: runs Builder → QA → (optional) Quickfix headlessly. Optional orchestration features (e.g., Integration cycles, Troubleshooter, no-manual QA smoketests) are enabled during customization.

Builder runs create and consume prompt artifacts by default, and every outcome is recorded at the top of `agents/historylog.md` (newest first). Orchestration uses `agents/status.md` as the sole signaling file.

Per-cycle runners (Codex CLI / Claude Code / OpenClaw) and model choices are configured in `agents/options/model_config.md`.

Operational spec: see `OLAD_framework.md`.

## Why It’s Useful

- **Clarity**: every agent knows where to look and how to proceed.
- **Traceability**: work is logged with context and evidence.
- **Repeatability**: you can reuse the workflow across repos and teams.
- **Determinism**: orchestration is driven by explicit status flags, not implicit heuristics.

## One-Time Setup (Recommended)

Use this once per repo to make the framework project-specific.

1) Start an agentic coding session at the root of your target repo.
2) Say: `Open agents/_customize.md and follow instructions.`
3) The agent generates `agents/spec.md` and fills out key project files.

During customization, the agent will also ask you which **model preset** you want and update `agents/options/model_config.md` accordingly. It will also set headless sub-agent permissions (Normal/Elevated/Maximum) in `agents/options/workflow_config.md`. Orchestrator behavior is configured during customization via `agents/options/`.

Optional feature packets and templates live under `agents/options/` to keep entrypoints small.

After setup, the repo is ready for day-to-day agentic work.

## Project Context (fill during customization)

- **What this repo is:** <one sentence describing the product/system and its purpose>.
- **Production target:** <deployment constraints, e.g., offline-only, regulated, latency goals>.
- **Guardrails:** <data handling, safety/compliance, or review requirements>.
- **Review gates:** <human review or QA gates required before shipping>.

## Non-negotiables (safety + quality)

- **Environment constraints:** respect deployment limits (offline, air-gap, latency, cost).
- **Data handling:** follow privacy, security, and compliance requirements.
- **Quality gates:** do not ship without required verification and review.
- **No secrets** in repo or logs.

## Detailed Features and Workflows (In Full-Cycle Order)

This section follows the sequence you would encounter in a real workflow cycle.

### 1) Scope the Work (Advisor Session)

The Advisor is a dedicated, freeform session used to make the rest of the cycle clean and scoped.

If you want a more structured, high-output scoping pass (raw idea -> spec -> ordered task cards), use:
- `agents/prompts/decompose.md` (via the Advisor)

Typical Advisor outputs:
- A set of task cards that are small and executable.
- A short explanation of how a subsystem works.
- A recommendation memo with options and tradeoffs.

If you want a more structured "idea -> spec -> ordered backlog" flow, use `agents/prompts/decompose.md` instead.

The Advisor should use `agents/_advisor.md`, rely on `agents/outline.md` as the primary repo overview, and place any task cards in `agents/tasksbacklog.md` (not `agents/prompts/tasks/`).
Advisor runs only log to `agents/historylog.md` when they perform concrete actions beyond writing task cards (prepend new entries at the top).
When needed, the Advisor can also generate new roles and skills using the dedicated creation prompts.

### 2) Orchestrate the Cycle (Orchestrator Session)

The Orchestrator runs Builder → QA → (optional) Quickfix automatically against the backlog. Optional steps (like Integration cycles or Troubleshooter) are installed during customization.

Key behavior:
- Pulls the next task from `agents/tasksbacklog.md` into `agents/tasks.md`.
- Runs Builder and QA in strict order, with optional steps installed by customization when enabled.
- Allows a Quickfix pass if QA finds gaps.
- Archives completed tasks to `agents/tasksarchive.md`.
- Clears `agents/status.md` to `### IDLE` after each action.

Use `agents/_orchestrate.md` for the exact runbook and guardrails.

### 3) Prompt Artifacts (Prompt Engineering Cycle)

Prompt artifacts are the default plan carrier for each task. They can be executed without re-planning.

Core flow:
1) Create a task prompt with `agents/prompts/create_prompt.md`.
2) Store it in `agents/prompts/tasks/`.
3) Execute it with `agents/prompts/run_prompt.md`.
4) Archive it to `agents/prompts/completed/` after execution.

This makes a prompt-driven workflow repeatable and reviewable.

### 4) Build and Quickfix (Builder Session)

The Builder executes the task and makes the smallest viable change set. It always creates a prompt artifact first and uses it as the authoritative plan.

Builder guidance:
- Use `agents/_start.md`.
- Keep changes minimal and scoped to the task.
- Prefer safe, reviewable diffs.

Quickfixes use `agents/_hotfix.md` and follow `agents/prompts/quickfix.md` for narrow, urgent changes.

### 5) QA and Verification (QA Session)

QA is a first-class session with its own entrypoint and verification flow.

Key pieces:
- `agents/_check.md` defines the QA flow.
- `agents/expectations.md` is an explicit expectations list used to anchor QA. This is a deliberate feature: it produces measurably stronger QA output because the agent verifies against concrete, written expectations rather than generic “check for issues.”
- QA results should be logged with evidence (commands, outputs, or screenshots).

Doublecheck QA uses `agents/_doublecheck.md` to validate quickfixes.

### 5.5) Integration (Optional)

- **Integration Steward:** `agents/_integrate.md` runs an integration sweep and writes an Integration Report. Orchestrated Integration runs only if enabled during customization, and tasks may use `**Gates:** INTEGRATION` only when Integration is installed.

### 5.6) No-Manual QA (Optional)

If enabled during customization, QA must not request human/manual verification and instead replaces manual checks with tracked smoketest artifacts under `agents/prompts/tests/`.

### 6) Roles and Specialization

Roles are defined in `agents/roles/` and used when a task benefits from a specific lens (security, infra, QA, etc.). Use one role at a time, and switch explicitly.

Roles make multi-agent collaboration more predictable and reduce churn.
If a new role is needed, use `agents/prompts/role_create.md` to generate a role file that matches the repo’s conventions.
Alternatively, use `agents/prompts/roleplay.md` for an interactive, ultra-detailed role generator.
Most roles are broadly reusable across projects.

### 7) Skills (Reusable Procedures)

Skills are reusable playbooks stored under `agents/skills/`.

How they work:
- Each skill defines a specific workflow, constraints, and outputs.
- If a task matches a skill, the agent should follow it rather than improvising.
- Skills are meant to reduce risk and improve consistency across repos.
If a new skill is needed, use `agents/prompts/skill_issue.md` for the full, interactive skill generator.
Note: several starter skills are often project-specific and can be removed during customization.

### 8) History Logging

Every session prepends to the top of `agents/historylog.md` (newest first) with a short summary, files touched, decisions, and follow-ups. This makes agent work auditable and easy to resume.

## Files Worth Reading

- `quickstart.md` — step-by-step usage guide
- `agents/_customize.md` — one-time onboarding prompt
- `agents/_orchestrate.md` — orchestration entrypoint
- `agents/_supervisor.md` — OpenClaw remote supervisor (optional)
- `agents/options/` — optional feature packets, configs, and headless templates
- `agents/options/openclaw/` — OpenClaw adapter pack (runner integration + message templates)
- `OLAD_framework.md` — detailed orchestration model and contracts
