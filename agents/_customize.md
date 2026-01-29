# One-Time Customization Prompt

You are onboarding this agentic framework to a new project repo. Your job is to generate a project spec sheet and fill in the project-specific files so the system becomes immediately usable.

## Key design: `agents/options/`

`agents/_customize.md` is the UX/menu layer.
Detailed option packets live under `agents/options/`.

Only open the option docs you need based on the user's choices.

## Output Targets

Create or update these files:
- `agents/spec.md` (new) - context-heavy spec sheet
- `README.md` - project overview, guardrails, workflow (Project Context + Non-negotiables)
- `agents/outline.md` - repo outline and stack
- `agents/tasks.md` - initial task entry or placeholder
- `agents/roadmap.md` - high-level roadmap template filled for this repo
- `agents/expectations.md` - success criteria and verification notes
- `agents/options/model_config.md` - model + runner assignments for all cycles
- `agents/options/workflow_config.md` - workflow flags (flags only; keep this file tiny)

Optional (only if enabled by a chosen option):
- `agents/_orchestrate.md` - patched to install optional orchestrator behaviors
- `agents/_troubleshoot.md` - installed if Troubleshoot-on-blocker is enabled
- Task-authoring guidance may be patched (e.g., `agents/prompts/decompose.md`, `agents/skills/task-card-authoring-repo-exact/SKILL.md`).

Keep all edits ASCII-only and minimal.

## Step 1: Repo Scan (fast)

Inspect the project repo to extract basics:
- Top-level folders and key entrypoints
- Primary languages/frameworks
- Build/test/lint commands (if present)
- Deployment or runtime constraints (from docs/configs)

If a README exists, skim it for setup and constraints.

If an `agents/outline.md` already exists, use it as the primary repo overview and only scan the repo directly if the outline is missing or outdated.

## Step 2: Ask for Missing Context

If any of the below are unknown, ask the user directly:
- One-sentence product description
- Deployment target (offline/online, regulated, SLAs)
- Data sensitivity and compliance constraints
- Review/approval gates (human review, QA, release)
- Critical non-negotiables (security, latency, cost)

Keep questions concise and in a single message.

## Step 2.5: Model + Runner Preset (Required)

Ask the user which model preset they want for the agentic cycles, then apply it by editing **only** the `KEY=value` lines under "Active config" in:
- `agents/options/model_config.md`

Ask:
- Which preset: Default / Default Performance / All Codex / All Claude / Custom?
- If Custom: model ids for Integration, Builder, QA, Hotfix, Doublecheck.

For preset blocks and known-good model ids, see:
- `agents/options/model_config.md`

## Step 2.6: Integration Thoroughness (Required)

Integration is an **orchestrator option**.
- Manual mode is equivalent to opting out of orchestrated Integration.
- `agents/_integrate.md` still exists for manual use.

Ask which integration mode they want:
- Manual: no orchestrated Integration cycles
- Low: run Integration only when tasks are gated `INTEGRATION`
- Medium: run on `INTEGRATION` tasks and periodically every 3-6 tasks
- High: run Integration every other task

Then:
- Update flags in `agents/options/workflow_config.md` (flags only):
  - Set `## INITIALIZED=true`
  - Set `## INTEGRATION_MODE=<Manual|Low|Medium|High>`
  - Reset `## INTEGRATION_COUNT=0`
  - Set `## INTEGRATION_TARGET`:
    - Manual: 0
    - Low: 0
    - Medium: 4
    - High: 1
- If the mode is Low/Medium/High, open `agents/options/integrate/integrate_option.md` and follow its instructions.
- If the mode is Manual, do not add Integration instructions to `agents/_orchestrate.md`.

## Step 2.7: Headless Sub-Agent Permissions (Required)

This controls how permissive headless sub-agents are when run by the orchestrator templates.

Ask the user to choose one:
- Normal (recommended): default `--full-auto` for Codex; no extra Claude flags.
  - Example: docs-only repos, CI-only tests, no local servers or Docker.
- Elevated: add Codex `--sandbox danger-full-access`; Claude uses `--permission-mode acceptEdits`.
  - Example: local dev servers, IPC pipes, or Docker socket access required.
- Maximum: Codex `--dangerously-bypass-approvals-and-sandbox`; Claude `--dangerously-skip-permissions`.
  - Example: fully trusted environment where headless runs must never prompt.

Then:
- Set `## HEADLESS_PERMISSIONS=<Normal|Elevated|Maximum>` in `agents/options/workflow_config.md`.
- Open `agents/options/permission/perm_config.md` and follow its instructions.

## Step 2.8: QA Manual Verification Policy (Optional)

This controls whether QA is allowed to request human/manual verification.

Ask the user to choose one:
- Manual Allowed (default): QA may request manual verification (headless runs may stop).
- Quick Smoketests: QA must NOT request manual verification; replace manual checks with smoketest artifacts under `agents/prompts/tests/`.
- Thorough Smoketests: same as Quick, but QA prefers applying/creating stack-specific smoketest skills when needed.

If Quick or Thorough:
- Open `agents/options/no-manual/no_manual_option.md` and follow its instructions (install the chosen mode).

If Manual Allowed:
- Do not install anything; leave QA behavior unchanged.

## Step 2.9: Troubleshoot-on-Blocker (Optional)

This adds an optional Troubleshooter step when orchestration hits a blocker.
It is expensive and intended for unattended/headless operation.

Ask the user:
- Do you want Troubleshoot-on-blocker enabled? (yes/no)

If yes:
- Open `agents/options/troubleshoot/troubleshoot_option.md` and follow its instructions.

If no:
- Do not install `agents/_troubleshoot.md`.
- Do not add Troubleshooter behavior to `agents/_orchestrate.md`.

## Step 2.10: Orchestrator Templates (Optional)

Ask the user:
- Will you run orchestration headlessly from WSL? (yes/no)

If yes, templates live in:
- `agents/options/orchestrate/orchestrate_options.md`

No repo edits are required for this step.

## Step 3: Write the Spec Sheet

Create `agents/spec.md` with this structure:

1) Project Summary (3-7 bullets)
2) Users and Use Cases
3) Runtime Constraints (offline/online, latency, cost)
4) Data and Compliance Requirements
5) Architecture Overview (services, databases, APIs)
6) Verification Commands (build/test/lint)
7) Operational Risks and Guardrails

Use concrete details from the repo or user answers. Mark unknowns explicitly as TODO.

## Step 4: Fill Project-Specific Files

Update the following using the spec sheet:
- `README.md`: update Project Context + Non-negotiables with the project summary, constraints, and guardrails.
- `agents/outline.md`: include repo structure, stack, and verification commands.
- `agents/tasks.md`: add a single starter task or placeholder that reflects current priorities.
- `agents/roadmap.md`: add 2-4 realistic themes and near-term goals.
- `agents/expectations.md`: list verification expectations, evidence types, and quality gates.

Use the user's answers to drive the edits:
- Product description, constraints, guardrails, review gates -> `README.md` Project Context + Non-negotiables.
- Repo scan results (stack, commands) -> `agents/outline.md` and `agents/expectations.md`.
- Current priorities from the user -> `agents/tasks.md` and `agents/roadmap.md`.

Avoid changing files not listed above unless required by an enabled option.

## Step 5: Create Project-Specific Roles and Skills (Required)

1) If the repo needs new roles, use `agents/prompts/roleplay.md` to generate them.
2) If the repo needs new skills, use `agents/prompts/skill_issue.md` to generate them.
3) Update `agents/roles/` and `agents/skills/skills_index.md` accordingly.
4) If no new roles/skills are needed, write a short note in `agents/spec.md` explaining why.

## Step 6: Confirm Completion

Summarize what you updated and list the files touched. Ask if the user wants to revise any sections.
