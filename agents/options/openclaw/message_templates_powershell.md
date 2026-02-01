# OpenClaw Message Templates (PowerShell)

These are copy/paste stubs you can send via OpenClaw's web UI or Telegram.

## Session setup

Use this once at the start of a session:

```
Use shell commands (exec tool) when you need to read files or run tests.
Work from repo root. First run:
Get-Location
Get-ChildItem -Force agents
Then run /status and report which tools are available.
```

## Run a specific entrypoint

Builder:

```
Run: Get-Content -Path "agents\\_start.md" -TotalCount 220
Then follow that file exactly and implement the active task card(s).
```

QA:

```
Run: Get-Content -Path "agents\\_check.md" -TotalCount 260
Then follow that file exactly.

IMPORTANT: orchestration reads `agents/status.md` (not chat output). Ensure you set `agents/status.md` to exactly one of:
- ### QA_COMPLETE
- ### QUICKFIX_NEEDED
- ### BLOCKED

If any "manual verification" is requested, use your available UI/browser tooling if present; otherwise replace it with a reproducible smoketest (commands + checklist).
If the OpenClaw `browser.act` tool is unreliable in your environment, prefer using `exec` + OpenClaw CLI browser automation (example: `openclaw browser --browser-profile openclaw snapshot --interactive`).
```

Advisor (spec to tasks):

```
Run: Get-Content -Path "agents\\_advisor.md" -TotalCount 260
Then follow that file exactly. If the user is asking to turn a spec into tasks, run the decompose prompt it points to.
```
