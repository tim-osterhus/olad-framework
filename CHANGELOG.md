# Changelog

## [1.5.0] - 2026-02-04

### Added
- UI verification option pack: `agents/options/ui-verify/` (workflow flags + artifact contract + YAML spec template)
- Anti-Gravity option pack: `agents/options/antigravity/` (Gemini 3 probe-call scripts + quota exhaustion timestamp flags + analyzer runner)
- UI verification spec template: `agents/ui_verification_spec.yaml`
- Skill linter: `agents/skills/lint_skills.py` (guards against skill drift and brittle example references)
- New UI skills:
  - `agents/skills/playwright-ui-verification/`
  - `agents/skills/openclaw-antigravity-ui-verify/`
  - `agents/skills/ui-quality-gates/`
  - `agents/skills/frontend-review/`
  - `agents/skills/ui-heuristics-scorecard/`

### Changed
- Supervisor is now allowed to write ONLY `agents/status.md` (all other repo writes remain sub-session-only)
- Bash headless templates now ignore unknown config keys (warn/ignore) to reduce breakage as new flags are added
- OpenClaw UI verification guidance now prefers tool-based browser automation with an explicit browser profile; CLI automation is a fallback
- `_customize.md` now includes an optional UI verification (OpenClaw/Anti-Gravity) configuration step
- Skills now include `compatibility` metadata in YAML frontmatter (supported runners/tools + offline_ok)
- Skill examples are now referenced by stable Example IDs (EX-YYYY-MM-DD-NN), not EXAMPLES.md line numbers

## [1.4.1] - 2026-02-01

### Fixed
- OpenClaw token retrieval docs/templates no longer rely on `openclaw config get ... --raw`; they now prefer `--json` (parse `value`) with a robust fallback
- OpenClaw UI verification guidance now explicitly prefers CLI-driven browser automation via `exec` when `browser.act` is unreliable and clarifies managed-profile + `snapshot` element handle usage
- OpenClaw runner skill no longer suggests a `model: openclaw:<agentId>` convention; it standardizes on `x-openclaw-agent-id` header routing

## [1.4.0] - 2026-02-01

### Added
- OpenClaw Supervisor entrypoint: `agents/_supervisor.md` (session manager; no repo writes; auto-remediation ladder + auto-resume)
- OpenClaw UI verification entrypoint: `agents/options/openclaw/_ui_verify.md`
- OpenClaw-enhanced wrappers for Supervisor-driven sessions:
  - Builder: `agents/options/openclaw/_start_openclaw.md`
  - QA: `agents/options/openclaw/_check_openclaw.md`
- OpenClaw mode flag (`OPENCLAW_MODE`) in `agents/options/workflow_config.md`
- OpenClaw runner skill: `agents/skills/openclaw-olad-runner/` (Gateway setup + troubleshooting)
- `_customize.md` can now install OpenClaw Supervisor mode behavior (including patching the Orchestrator blocker flow to stop with a Supervisor-facing summary instead of external escalation)

### Changed
- Moved the OpenClaw adapter pack to `agents/options/openclaw/` (was `agents/openclaw/`)
- Updated docs/templates to reference the new OpenClaw paths
- Revamp guide updated to reflect the new OpenClaw pack location and upgrade/migration expectations

## [1.3.1] - 2026-02-01

### Fixed
- Logical fixes: OpenClaw QA message templates now reference the correct orchestration statuses (`### QA_COMPLETE`, `### QUICKFIX_NEEDED`, `### BLOCKED`) and explicitly require writing `agents/status.md`
- Logical fixes: QA and Doublecheck entrypoints now explicitly instruct setting `agents/status.md` to `### BLOCKED` when stopping on a blocker
- Logical fixes: clarified that OpenClaw `*_MODEL` values must match your Gateway's accepted model id(s) (the `openclaw` alias is not guaranteed)
- Removed stale internal reference to an OpenClaw notes file that is not shipped in the framework repo
- Minor doc link fixes for OpenClaw + PowerShell paths

## [1.3.0] - 2026-02-01

### Added
- PowerShell headless templates in `agents/options/orchestrate/orchestrate_options_powershell.md`
- Shell templates selection (`SHELL_TEMPLATES`) in `agents/options/workflow_config.md`
- OpenClaw as a first-class runner:
  - `openclaw` runner support in headless templates
  - Gateway config flags (`OPENCLAW_GATEWAY_URL`, `OPENCLAW_AGENT_ID`) in `agents/options/workflow_config.md`
  - OpenClaw docs (Bash + PowerShell variants)
- "All OpenClaw" preset in `agents/options/model_config.md`

### Changed
- `_customize.md` now asks whether to use Bash or PowerShell templates and wires docs/entrypoints accordingly
- `_orchestrate.md` now keeps shell-specific command snippets out of the entrypoint (moved into the selected templates file)
- Troubleshoot option doc now points to the templates file instead of embedding a Bash-only invocation snippet
- Skill examples updated to avoid Bash-only formatting (shell-agnostic `text` blocks where appropriate)

## [1.2.0] - 2026-01-28

### Added
- `agents/options/` option packets (integrate, troubleshoot, orchestrate, permission)
- No-manual QA option packet (`agents/options/no-manual/`) with Quick/Thorough smoketest modes (opt-in)
- Headless permissions selection (`HEADLESS_PERMISSIONS`) in `agents/options/workflow_config.md`
- Bash/WSL headless templates in `agents/options/orchestrate/orchestrate_options_bash.md`
- Safe, block-scoped parsing for `agents/options/model_config.md` in WSL templates

### Changed
- Model/workflow configs moved under `agents/options/`
- `_customize.md` now drives options from `agents/options/` (menu + opt-in installs)
- `_orchestrate.md` slimmed; optional cycles are installed during customization
- Codex QA/Doublecheck headless templates enable `--search` by default
- Default task authoring guidance no longer includes `INTEGRATION` unless the option is enabled
- Prompt artifacts are now created by default for every task; PROMPT gate removed from workflows/docs
- Documentation updated for options, permissions, and new config paths

## [1.1.0] - 2026-01-24

### Added
- Integration gate and Integration Steward entrypoint (`agents/_integrate.md`)
- Integration Steward role (`agents/roles/integration-steward.md`)
- Centralized model config (`agents/options/model_config.md`) with presets
- Decomposition/role/skill prompts (`agents/prompts/decompose.md`, `agents/prompts/roleplay.md`, `agents/prompts/skill_issue.md`)

### Changed
- Orchestrator now supports Integration cycles and config-driven runners/models
- QA now consumes integration reports
- README is the canonical project context and guardrails source
- Skill creation prompts aligned with template guidance and EXAMPLES-first detail storage

### Removed
- `AGENTS.md`, `CLAUDE.md`, `GEMINI.md` legacy wrappers
- `docs/` supporting documents folder

## [1.0.0] - 2026-01-03

### Added
- Builder, QA, and Advisor entrypoints
- Prompt artifact workflow (create, run, archive)
- Expectations-first QA process
- Skills library and role library
- Quickstart and customization prompts
- Documentation set (architecture, philosophy, customization, tutorial, troubleshooting)
