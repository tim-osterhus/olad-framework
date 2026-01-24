# Changelog

## [1.1.0] - 2026-01-24

### Added
- CCC preflight gate with `_ccc.md` status flagging
- Integration gate and Integration Steward entrypoint (`agents/_integrate.md`)
- Integration Steward role (`agents/roles/integration-steward.md`)
- Centralized model config (`agents/model_config.md`) with presets
- Decomposition/role/skill prompts (`agents/prompts/decompose.md`, `agents/prompts/roleplay.md`, `agents/prompts/skill_issue.md`)

### Changed
- Orchestrator now supports CCC/Integration cycles and config-driven runners/models
- QA now consumes CCC contracts and integration reports
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
