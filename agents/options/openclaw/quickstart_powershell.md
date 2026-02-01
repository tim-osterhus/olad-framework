# OpenClaw Quickstart (PowerShell)

This is a practical way to run OLAD cycles through OpenClaw (web UI, Telegram, or CLI) using
**PowerShell** commands.

If you want OpenClaw to be a first-class runner (selected via `agents/options/model_config.md`
and launched from the headless orchestrator templates), start with:
- `agents/options/openclaw/runner_integration_powershell.md`

## Assumptions

- OpenClaw is running on a machine that has this repo checked out.
- OpenClaw can run shell commands (for example via an `exec` tool).

If OpenClaw can "open files" directly, great. If not, just use shell commands to read files.

## Minimal setup checklist (recommended per session)

1) In OpenClaw, run `/status` and confirm tools are available (at least `exec`).
2) Optional: run `/reasoning` if you want higher reasoning for this session.
3) Confirm repo location (example):
   - Run: `Get-Location`
   - Then: `Get-ChildItem -Force agents`

## Run an OLAD cycle

Pick the entrypoint you want and instruct OpenClaw to open it and follow it.

Builder:
- Read: `Get-Content -Path "agents\\_start.md" -TotalCount 220`
- Then follow the instructions in that file exactly.

QA:
- Read: `Get-Content -Path "agents\\_check.md" -TotalCount 260`
- Then follow the instructions in that file exactly.

Advisor:
- Read: `Get-Content -Path "agents\\_advisor.md" -TotalCount 240`
- Then follow the instructions in that file exactly.

Hotfix:
- Read: `Get-Content -Path "agents\\_hotfix.md" -TotalCount 240`
- Then follow the instructions in that file exactly.

Doublecheck:
- Read: `Get-Content -Path "agents\\_doublecheck.md" -TotalCount 260`
- Then follow the instructions in that file exactly.

Orchestrate (multi-cycle runner):
- Read: `Get-Content -Path "agents\\_orchestrate.md" -TotalCount 320`
- Then follow the instructions in that file exactly.

## Capturing results (lightweight)

At minimum:
- Paste OpenClaw's final report into the relevant run log or PR body.
- Ensure any files the workflow expects (for example prompt artifacts, expectations updates,
  historylog updates) are present in the repo.
