# Skills Index

Use this registry to discover and apply relevant skills. Pick up to 3 per task.

| Skill | When to use (triggers) | Inputs | Outputs |
| --- | --- | --- | --- |
| [Task Card Authoring (Repo-Exact)](./task-card-authoring-repo-exact/SKILL.md) | Converting vague requests into a single task card | `agents/tasks.md`, `agents/tasksbacklog.md` | Updated `agents/tasks.md` with DONE checks |
| [Small-Diff Discipline](./small-diff-discipline/SKILL.md) | Any code change; especially infra/librechat/rag_api | Scope, target files | Minimal diff plan + change set |
| [Historylog Entry (High Signal)](./historylog-entry-high-signal/SKILL.md) | After any builder/QA run | Change summary, commands run | Prepend to `agents/historylog.md` |
| [Compose Stack Change Protocol](./compose-stack-change-protocol/SKILL.md) | Docker compose or infra changes | `infra/compose/`, compose commands | Updated compose + validation |
| [Codebase Safe Cleanup (Strict)](./codebase-safe-cleanup/SKILL.md) | Behavior-preserving cleanup/refactor with verification gates | Build/test commands, target areas | Cleanup plan + verified change batches |
| [Codebase Audit + Documentation](./codebase-audit-doc/SKILL.md) | Security/correctness/maintainability audit and doc-only plan | Repo context, run commands | Audit report + doc-only patch plan |
| [OpenClaw OLAD Runner](./openclaw-olad-runner/SKILL.md) | Run OLAD cycles via OpenClaw Gateway (/v1/responses) or OpenClaw chat; runner troubleshooting (401/404/connection); when OpenClaw-only tooling is needed (exec, browser/UI verification, sub-agents) | `agents/options/workflow_config.md`, `agents/options/model_config.md`, gateway URL + auth, agent id | Repeatable runner setup + healthcheck + completed cycle logs + raw response JSON |
