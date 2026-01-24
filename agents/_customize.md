# One-Time Customization Prompt

You are onboarding this agentic framework to a new project repo. Your job is to generate a project spec sheet and fill in the project-specific files so the system becomes immediately usable.

## Output Targets

Create or update these files:
- `agents/spec.md` (new) — context-heavy spec sheet
- `README.md` — project overview, guardrails, workflow (Project Context + Non-negotiables)
- `agents/outline.md` — repo outline and stack
- `agents/tasks.md` — initial task entry or placeholder
- `agents/roadmap.md` — high-level roadmap template filled for this repo
- `agents/expectations.md` — success criteria and verification notes
- `agents/model_config.md` — model + runner assignments for all cycles

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

Ask the user which model preset they want for the agentic cycles, then apply it.

### Presets

1) **Default (recommended)**
   - CCC / Integration / Builder / Hotfix: `gpt-5.2-codex`
   - QA / Doublecheck: `claude-sonnet-4-5`
   - If chosen: **do not modify** `agents/model_config.md`.

1.5) **Default Performance**
   - CCC / Integration / Builder / Hotfix: `gpt-5.2-codex`
   - QA / Doublecheck: `claude-opus-4-5`
   - If chosen: update `agents/model_config.md` values accordingly.

2) **All Codex**
   - All cycles use `gpt-5.2-codex`.
   - If chosen: update `agents/model_config.md` values accordingly.

2.5) **All Codex Performance**
   - CCC / Integration / Builder / Hotfix: `gpt-5.2-codex`
   - QA / Doublecheck: `gpt-5.2`
   - If chosen: update `agents/model_config.md` values accordingly.

3) **All Claude**
   - All cycles use `claude-sonnet-4-5`.
   - If chosen: update `agents/model_config.md` values accordingly.

3.5) **All Claude Performance**
   - All cycles use `claude-opus-4-5`.
   - If chosen: update `agents/model_config.md` values accordingly.

4) **Custom**
   - Ask what models they want for:
     - CCC
     - Integration
     - Builder
     - QA
     - Hotfix
     - Doublecheck
   - Then update `agents/model_config.md` values to match.

### How to edit `agents/model_config.md` (mechanical rules)

- Only change the `KEY=value` lines under **Active config**.
- Set each `*_RUNNER` to `codex` or `claude`.
- Set each `*_MODEL` to a model id (Codex) or a model id/alias (Claude).
- Do not edit `agents/_orchestrate.md` for model changes.

### Known-good model options (shortlist)

Use this list when asking, and keep it short. The user's account/tooling may not support every option.

- **Codex CLI**
  - `gpt-5.2-codex` (default)
  - `gpt-5.2`
  - `gpt-5.1-codex-mini`

- **Claude Code CLI**
  - `claude-sonnet-4-5` (default)
  - `claude-opus-4-5`
  - `claude-haiku-4-5`

If the user wants something else, ask them to provide the exact model id they already know works in their environment.

### What to ask (single message)

Ask exactly:
- Which preset: Default / All Codex / All Claude / Custom?
- If Custom: model id for Builder/Hotfix and model id for QA/Doublecheck.
- Whether they want Claude Code runs to use `--dangerously-skip-permissions` (yes/no). If unknown, default to **yes** and note it in `agents/spec.md`.

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
- `README.md`: update `Project Context` + `Non-negotiables` with the project summary, constraints, and guardrails.
- `agents/outline.md`: include repo structure, stack, and verification commands.
- `agents/tasks.md`: add a single starter task or placeholder that reflects current priorities.
- `agents/roadmap.md`: add 2-4 realistic themes and near-term goals.
- `agents/expectations.md`: list verification expectations, evidence types, and quality gates.
- `agents/model_config.md`: apply the chosen preset or custom per-cycle models.

Use the user's answers to drive the edits:
- Product description, constraints, guardrails, review gates -> `README.md` Project Context + Non-negotiables.
- Repo scan results (stack, commands) -> `agents/outline.md` and `agents/expectations.md`.
- Current priorities from the user -> `agents/tasks.md` and `agents/roadmap.md`.

Avoid changing files not listed above.

## Step 5: Create Project-Specific Roles and Skills (Required)

1) If the repo needs new roles, use `agents/prompts/roleplay.md` to generate them.
2) If the repo needs new skills, use `agents/prompts/skill_issue.md` to generate them.
3) Update `agents/roles/` and `agents/skills/skills_index.md` accordingly.
4) If no new roles/skills are needed, write a short note in `agents/spec.md` explaining why.

## Step 6: Confirm Completion

Summarize what you updated and list the files touched. Ask if the user wants to revise any sections.
