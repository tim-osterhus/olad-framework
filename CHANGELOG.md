# Changelog

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
