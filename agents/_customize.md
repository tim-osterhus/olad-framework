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

## Step 2.5: Model + Runner Baseline (Required)

Default baseline is OpenAI models for all cycles (the "Default" active config in `agents/options/model_config.md`).

Ask the user:
- Keep the default model config as-is? (yes/no)

If yes:
- Leave `agents/options/model_config.md` Active config unchanged.

If no:
- Ask which preset they want: Hybrid / Hybrid Performance / All Codex / All Claude / All OpenClaw / Custom.
- If Custom: ask model ids for Integration, Builder, QA, Hotfix, Doublecheck, and Update.
- Then edit **only** the `KEY=value` lines under "Active config" in `agents/options/model_config.md`.

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

This controls whether QA is allowed to request human/manual verification (and whether manual UI checks should block the workflow).

Ask the user to choose one:
- Manual Allowed (default): QA may request manual verification (headless runs may stop).
- Manual Queue (Non-blocking): QA must NOT block on manual UI verification. If a manual UI check is required, append a checklist item to `agents/manualtasks.md` and proceed with the rest of QA.
- Quick Smoketests: QA must NOT request manual verification; replace manual checks with smoketest artifacts under `agents/prompts/tests/`.
- Thorough Smoketests: same as Quick, but QA prefers applying/creating stack-specific smoketest skills when needed.

Then:
- Set `## QA_MANUAL_POLICY=<ManualAllowed|ManualQueue|QuickSmoketests|ThoroughSmoketests>` in `agents/options/workflow_config.md`.

If Manual Queue:
- Open `agents/options/manual-queue/manual_queue_option.md` and follow its instructions (install/wire the non-blocking manual UI verification queue).

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

## Step 2.9b: Spark-Routing Mode (Optional)

This adds optional complexity-aware routing for the local foreground orchestrator loop
(`agents/orchestrate_loop.sh`), with optional Spark-first small-task chains plus cooldown fallback.

Ask the user:
- Enable Spark-routing mode? (yes/no)
- If yes, what Spark cooldown window in minutes? (default `360`)

Then:
- Set `## COMPLEXITY_ROUTING=<On|Off>` in `agents/options/workflow_config.md`.
- Set `## SPARK_COOLDOWN_MINUTES=<N>` in `agents/options/workflow_config.md`.
- If enabling this mode, open `agents/options/spark-routing/spark_routing_option.md` and follow it.

## Step 2.9c: Update-on-Empty Mode (Optional)

This controls whether the local foreground orchestrator loop runs a final documentation
update cycle when it finds no remaining task cards in `agents/tasksbacklog.md`.

Ask the user:
- Enable update-on-empty mode? (yes/no)

Then:
- Set `## RUN_UPDATE_ON_EMPTY=<On|Off>` in `agents/options/workflow_config.md`.
- If enabling this mode, open `agents/options/update/update_option.md` and follow it.

## Step 2.10: Shell Templates (Required)

Ask the user:
- Which shell should OLAD use for all copy/paste command templates?
  - Bash/WSL (default)
  - PowerShell (Windows PowerShell 5.1 / PowerShell 7)

Then:
- Set `## SHELL_TEMPLATES=<Bash|PowerShell>` in `agents/options/workflow_config.md`.
- Wire docs/entrypoints to the selected templates by making minimal, mechanical reference edits:
  - If Bash:
    - Use `agents/options/orchestrate/orchestrate_options_bash.md`
    - Use `agents/options/openclaw/*_bash.md` docs (if using OpenClaw)
  - If PowerShell:
    - Use `agents/options/orchestrate/orchestrate_options_powershell.md`
    - Use `agents/options/openclaw/*_powershell.md` docs (if using OpenClaw)

Wiring targets (update references to point at the selected shell variant):
- `agents/_orchestrate.md` (headless templates pointer)
- `quickstart.md` (headless templates pointer)
- `OLAD_framework.md` (templates pointer + files-to-know list)
- `agents/options/openclaw/README.md` and any OpenClaw links (`runner_integration_*`, `quickstart_*`, `message_templates_*`)
- `agents/options/model_config.md` (OpenClaw sanity-check link)

Do not list both shell variants in user-facing docs; reference only the selected one.

If the user later switches shells, they can:
- Update `## SHELL_TEMPLATES=...` and rerun this wiring step (or do the same mechanical reference swap by hand).

## Step 2.11: Orchestrator Templates (Optional)

Ask the user:
- Will you run orchestration headlessly? (yes/no)

If yes, templates live in the shell-specific file referenced by `agents/_orchestrate.md`.

No repo edits are required for this step.

## Step 2.12: OpenClaw Supervisor Mode (Optional)

This controls whether the OpenClaw Supervisor entrypoint is kept as a first-class entrypoint.

Ask the user:
- Do you want OpenClaw Supervisor mode enabled? (On/Off)

Then:
- Set `## OPENCLAW_MODE=<On|Off>` in `agents/options/workflow_config.md`.
- If On:
  - Ensure `agents/_supervisor.md` exists in `agents/` (if it was previously moved out, move it back).
  - Patch `agents/_orchestrate.md` (minimal, mechanical):
    - Preflight: remove any requirement for `gh` (GitHub CLI) and any "diagnostics PR" preflight checks.
    - Blocker handler: replace the "Diagnostics PR + @codex" behavior with "Supervisor escalation":
      - Keep the local diagnostics bundle creation (folder + snapshots).
      - Remove all steps that:
        - create a branch
        - commit/push
        - open a PR
        - tag external services (for example `@codex`)
      - End the Orchestrator's output with a single Supervisor-facing summary that includes:
        - where it blocked (builder / QA / hotfix / doublecheck / integration)
        - why it blocked
        - diagnostics bundle path
        - run folder path
      - Stop.
    - (The Supervisor will spawn UI verification / Troubleshooter sessions as needed.)
- If Off:
  - Move `agents/_supervisor.md` to `agents/options/openclaw/_supervisor.md` so it does not appear as a default entrypoint.
  - Do not add Supervisor references to user-facing docs.

## Step 2.13: UI Verification (OpenClaw / Anti-Gravity) (Optional)

This enables structured UI verification artifacts and (optionally) Anti-Gravity/Gemini-based analysis during OpenClaw runs.

Ask the user which UI verification preset they want:
- Off (default): no automated UI verification wiring (manual only).
- OpenClaw UI Verify: deterministic UI verification via OpenClaw browser tooling + a short report.
- Anti-Gravity Analyzer: OpenClaw UI verification + quota-safe Gemini/Anti-Gravity analysis.

Then update flags in `agents/options/workflow_config.md` (flags only):
- Always set:
  - `## UI_VERIFY_MODE=<manual|deterministic|hybrid>`
  - `## UI_VERIFY_EXECUTOR=<playwright|openclaw_browser|antigravity_agent>`
  - `## UI_VERIFY_ANALYZER=<antigravity|openclaw|none>`
  - `## UI_VERIFY_COVERAGE=<smoke|standard|broad>`
  - `## UI_VERIFY_QUOTA_GUARD=<on|off>`
  - `## UI_VERIFY_BROWSER_PROFILE=<profile>` (default `openclaw`)
- If Anti-Gravity Analyzer is selected:
  - Set `## ANTIGRAVITY_MODEL_PREF=<auto|flash|pro_low|pro_high>`
  - Ensure the model id keys exist (fill them only if the user knows the correct ids for their install):
    - `## ANTIGRAVITY_G3_FLASH_MODEL=...`
    - `## ANTIGRAVITY_G3_PRO_LOW_MODEL=...`
    - `## ANTIGRAVITY_G3_PRO_HIGH_MODEL=...`
  - Leave the `ANTIGRAVITY_G3_*_EXHAUSTED_AT=` flags blank (they are set automatically on quota errors).

For full details and wiring rules, open only as needed:
- `agents/options/ui-verify/ui_verify_option.md`
- `agents/options/antigravity/antigravity_option.md`

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
