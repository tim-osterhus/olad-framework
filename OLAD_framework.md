# Orchestrative Lean Agentic Development (OLAD) Framework

This document describes the current, repo-specific workflow. It is role-driven, artifact-driven, and designed to keep changes minimal, auditable, and easy to validate in headless runs.

## 1) Entry points (how work starts)

- **Active task source:** `agents/tasks.md` is the single source of truth for the current task.
- **Builder entry:** `agents/_start.md` is the Builder entrypoint.
- **Mini Builder entry (optional):** `agents/_ministart.md` is an optional compact Builder entrypoint for TRIVIAL/BASIC cards when Spark-routing mode is enabled.
- **QA entry:** `agents/_check.md` is the QA entrypoint.
- **Hotfix entry:** `agents/_hotfix.md` is the Builder entrypoint for quickfix cycles.
- **Doublecheck entry:** `agents/_doublecheck.md` is the QA entrypoint for quickfix cycles.
- **Integration entry:** `agents/_integrate.md` for integration sweeps and reports (manual use always allowed; orchestration only if enabled).
- **Advisor entry:** `agents/_advisor.md` for freeform advisory or scoping work.
- **Orchestrator entry:** `agents/_orchestrate.md` for headless orchestration across tasks.
- **Update entry (optional loop finalizer):** `agents/_update.md` for backlog-empty documentation reconciliation.
- **Local orchestrator loop (optional):** `agents/orchestrate_loop.sh` for long-running, foreground backlog draining outside a chat session (tmux-friendly).
- **Articulate entry (optional research loop):** `agents/_articulate.md` for raw -> articulated idea normalization.
- **Analyze entry (optional research loop):** `agents/_analyze.md` for viability/dependency routing.
- **Clarify entry (optional research loop):** `agents/_clarify.md` for staging -> spec generation.
- **Taskmaster entry (optional research loop):** `agents/_taskmaster.md` for spec -> pending task generation.
- **Taskaudit entry (optional research loop):** `agents/_taskaudit.md` for pending-task merge/audit into backlog.
- **Local research loop (optional):** `agents/research_loop.sh` for long-running, foreground idea processing and backlog feed.

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

Prompt artifacts live in `agents/prompts/tasks/` and capture a task’s plan and constraints. The Builder always ensures a prompt artifact exists before planning (even if brief).

- Create the prompt artifact via `agents/prompts/create_prompt.md` before Builder planning.
- Execution follows `agents/prompts/run_prompt.md`.
- Completed prompt artifacts are moved to `agents/prompts/completed/`.

## 5) Status signaling (authoritative flags)

`agents/status.md` is the authoritative signaling file for headless orchestration.

Expected flags:
- `### BUILDER_COMPLETE`
- `### QA_COMPLETE`
- `### QUICKFIX_NEEDED`
- `### BLOCKED`
- `### IDLE`

The Orchestrator treats the latest flag as authoritative and clears it to `### IDLE` after acting.

Optional flags (only if the related option is enabled and installed):
- `### INTEGRATION_COMPLETE`
- `### TROUBLESHOOT_COMPLETE`
- `### UPDATE_COMPLETE`

Optional research status file (separate contract; do not cross-talk with `agents/status.md`):
- `agents/research_status.md` (overwrite-only current marker)

## 6) Builder cycle (build workflow)

The Builder cycle is defined in `agents/prompts/builder_cycle.md` and `agents/_start.md`.

1) **Read context**
   - Read `agents/outline.md` and `agents/tasks.md`.
2) **Select skills**
   - Scan `agents/skills/skills_index.md` and choose up to three relevant skills.
3) **Create prompt artifact (always)**
   - Create the prompt artifact via `agents/prompts/create_prompt.md`, save it to `agents/prompts/tasks/###-slug.md`, and use it as the authoritative plan.
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

If the optional "manual queue" feature is enabled during customization, manual UI verification must be non-blocking:
- QA appends checklist items to `agents/manualtasks.md`
- QA continues validating headlessly
- QA must NOT set `### BLOCKED` solely because a manual UI check is needed

If the optional "no-manual QA" feature is enabled during customization, the QA cycle must replace manual verification steps with tracked smoketest artifacts under `agents/prompts/tests/` (Quick or Thorough mode; see `agents/options/no-manual/no_manual_option.md`).

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
3) Spawn QA with the exact prompt: `Open agents/_check.md and follow instructions.`
4) If QA signals `### QUICKFIX_NEEDED`, run Hotfix then Doublecheck.
5) On `### QA_COMPLETE`, archive the task card and continue to the next one.
6) If `RUN_UPDATE_ON_EMPTY=On` and backlog is empty, run `agents/_update.md` once as a final maintenance cycle.

Optional cycles (e.g., Integration) are installed into `agents/_orchestrate.md` during customization based on selected options.

Models and runners are configured in `agents/options/model_config.md`.
Headless permissions are configured in `agents/options/workflow_config.md` and applied by the headless templates in `agents/options/orchestrate/orchestrate_options_bash.md`.
Orchestrator behavior is configured during customization via `agents/options/`.

Preset options:
- Default: OpenAI models (Codex runner) for all cycles.
- Hybrid: Codex for Integration/Builder/Hotfix, Claude for QA/Doublecheck.
- Hybrid Performance: Hybrid with higher-reasoning Claude QA/Doublecheck.
- All Codex: Codex for all cycles.
- All Claude: Claude for all cycles.
- All OpenClaw: OpenClaw for all cycles.
- Custom: per-cycle runner + model ids (plus optional complexity-routing keys).
Performance variants: each preset can be upgraded to higher-reasoning models/settings via `agents/options/model_config.md`.

### Optional: Local Foreground Orchestrate Loop (`agents/orchestrate_loop.sh`)

For long-running work where a chat-based orchestrator might get interrupted (session limits, lost context, etc.), OLAD also ships a deterministic local runner:

- Script: `agents/orchestrate_loop.sh`
- Purpose: drain `agents/tasksbacklog.md` by promoting the next `##` card into `agents/tasks.md`, then run Builder → (optional) Integration → QA → (optional) Hotfix/Doublecheck until the backlog is empty.
- Optional backlog-empty update mode (`RUN_UPDATE_ON_EMPTY=On`): when no cards remain, run `agents/_update.md` once to reconcile key informational docs before idle/exit.
- Optional complexity-routing mode (`COMPLEXITY_ROUTING=On`): route TRIVIAL/BASIC cards through `agents/_ministart.md`, optionally use Spark-first model chains with cooldown fallback, and auto-upscope non-usage blockers to MODERATE.
- Optional daemon behavior: when backlog is empty, stay alive and wait for backlog edits before resuming.
- Outputs:
  - Run logs: `agents/runs/<RUN_ID>/` (`*.stdout.log`, `*.stderr.log`, `*.last.md`, `runner_notes.md`)
  - Diagnostics bundle on blocker: `agents/diagnostics/<TIMESTAMP>/` (snapshot of run folder + key artifacts)
  - Hard-blocker demotion queue: `agents/tasksbackburner.md` (auto-demoted cards with blocker metadata)
  - Temporary state: `agents/.tmp/current_run.txt`

Troubleshoot-on-blocker compatibility:
- If Troubleshoot-on-blocker is enabled (i.e. `agents/_troubleshoot.md` is installed), `agents/orchestrate_loop.sh` attempts **one** Troubleshooter run per blocker only for MODERATE/INVOLVED/HEAVY cards. If the blocker remains, the card is auto-demoted to `agents/tasksbackburner.md` and the loop continues.
- For TRIVIAL/BASIC cards, non-usage blockers auto-upscope the active card to MODERATE instead of invoking Troubleshooter.
- If Troubleshoot-on-blocker is disabled, use the no-troubleshooter variant instead: `agents/options/troubleshoot/orchestrate_loop_no_ts.sh` (it skips Troubleshooter and auto-demotes hard blockers directly to `agents/tasksbackburner.md`).

Daemon and idle settings:
- `DAEMON_MODE` (default `false`): if `true`, do not exit when backlog is empty.
- `IDLE_MODE` (default `auto`): `auto|watch|poll`.
- `IDLE_POLL_SECS` (default `3600`): poll interval for `poll` mode and `auto` fallback.
- `IDLE_DEBOUNCE_SECS` (default `300`): quiet period after backlog change before resuming.
- `IDLE_MODE=watch` is strict and requires `inotifywait` or `fswatch`.
- `IDLE_MODE=auto` prefers `inotifywait`/`fswatch` when present and falls back to polling when absent.

Example daemon run:

```bash
DAEMON_MODE=true IDLE_MODE=auto IDLE_DEBOUNCE_SECS=300 bash agents/orchestrate_loop.sh
```

#### Tool requirements (Linux/WSL)

- `bash`
- `python3`
- `rg`
- `timeout`
- For `IDLE_MODE=watch`: `inotifywait` (usually from `inotify-tools`) or `fswatch`
- Runner binaries (per `agents/options/model_config.md`): `codex` and/or `claude` and/or `curl` (OpenClaw)
- OpenClaw runner only: `OPENCLAW_GATEWAY_TOKEN` or `openclaw`/`openclaw.exe` (for token lookup)
- Optional: `gh` (GitHub issue notification on blockers; only used if installed and authenticated)
- Optional: `tmux` (recommended for long-running foreground runs)

#### Tool requirements (macOS)

- Everything in the Linux/WSL list above, plus:
- Provide a `timeout` command on PATH (macOS doesn’t ship GNU `timeout`; Homebrew `coreutils` provides `gtimeout`).
- For `IDLE_MODE=watch`: install `fswatch` (or provide `inotifywait` if available).

### Optional: Local Foreground Research Loop (`agents/research_loop.sh`)

For continuous idea intake and decomposition, OLAD can run a companion research loop that feeds execution backlog work without reusing orchestration status flags.

- Script: `agents/research_loop.sh`
- Purpose: process ideas through `agents/ideas/` state folders and produce pending task cards for backlog merge.
- Stage order:
  1) `raw/` -> `_articulate.md` (one file per cycle)
  2) `articulated/` -> `_analyze.md` (one file per cycle)
  3) `staging/` -> `_clarify.md` (one file per cycle)
  4) `ideas/specs/` -> `_taskmaster.md` (all queued specs in one run)
  5) `_taskaudit.md` merges `agents/taskspending.md` into `agents/tasksbacklog.md`, verifies merge success, and retries once on mismatch
- Stable specs:
  - Queue specs: `agents/ideas/specs/` (transient)
  - Stable specs: `agents/specs/stable/` (authoritative path for task references)
- Signaling:
  - Research loop writes `agents/research_status.md` only
  - Execution loop writes `agents/status.md` only
- Deduping:
  - `Spec-ID` checks span `agents/tasksbacklog.md`, `agents/tasks.md`, `agents/tasksarchive.md`, and `agents/tasksbackburner.md`
- Default runner config keys:
  - `ARTICULATE_RUNNER` / `ARTICULATE_MODEL` / `ARTICULATE_EFFORT`
  - `ANALYZE_RUNNER` / `ANALYZE_MODEL` / `ANALYZE_EFFORT`
  - `CLARIFY_RUNNER` / `CLARIFY_MODEL` / `CLARIFY_EFFORT`
  - `TASKMASTER_RUNNER` / `TASKMASTER_MODEL` / `TASKMASTER_EFFORT`
  - `TASKAUDIT_RUNNER` / `TASKAUDIT_MODEL` / `TASKAUDIT_EFFORT`

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

- Entry points: `agents/_integrate.md`, `agents/_start.md`, `agents/_check.md`, `agents/_hotfix.md`, `agents/_doublecheck.md`, `agents/_advisor.md`, `agents/_orchestrate.md` (optional: `agents/_troubleshoot.md` when enabled)
- Optional maintenance entrypoint: `agents/_update.md` (used by local loop when update-on-empty is enabled)
- Research entry points (optional): `agents/_articulate.md`, `agents/_analyze.md`, `agents/_clarify.md`, `agents/_taskmaster.md`, `agents/_taskaudit.md`
- Optional compact entrypoint: `agents/_ministart.md` (used by local loop only when complexity routing is enabled)
- Local runner: `agents/orchestrate_loop.sh` (optional; long-running foreground loop)
- Local research runner (optional): `agents/research_loop.sh`
- OpenClaw Supervisor (optional): `agents/_supervisor.md`
- Tasks: `agents/tasks.md`, `agents/tasksbacklog.md`, `agents/tasksarchive.md`, `agents/tasksbackburner.md`
- Research task staging: `agents/taskspending.md`
- Ideas pipeline: `agents/ideas/{raw,articulated,staging,specs,finished,later,nonviable,ambiguous,archived}/`
- Prompt artifacts: `agents/prompts/tasks/`, `agents/prompts/run_prompt.md`
- Manual UI verification queue (optional): `agents/manualtasks.md` (enabled only if installed during customization)
- QA smoketest artifacts (optional): `agents/prompts/tests/` (enabled only if installed during customization)
- UI verification (optional, OpenClaw): `agents/options/openclaw/_ui_verify.md`, `agents/ui_verification_spec.yaml`, `agents/options/ui-verify/`, `agents/options/antigravity/`
- Signals/logs: `agents/status.md`, `agents/research_status.md`, `agents/quickfix.md`, `agents/expectations.md`, `agents/historylog.md`
- Options/config: `agents/options/`, `agents/options/model_config.md`, `agents/options/workflow_config.md`, `agents/options/permission/perm_config.md`, `agents/options/orchestrate/orchestrate_options_bash.md`
- Spark-routing option (optional): `agents/options/spark-routing/spark_routing_option.md`
- Update-on-empty option (optional): `agents/options/update/update_option.md`
- OpenClaw runner integration (optional): `agents/options/openclaw/`
- Skills: `agents/skills/skills_index.md`, `agents/skills/**/SKILL.md`, `agents/skills/**/EXAMPLES.md`

---

This framework is intentionally strict: it prevents drift, keeps changes reviewable, and makes QA reproducible.
