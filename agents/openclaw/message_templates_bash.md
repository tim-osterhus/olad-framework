# OpenClaw Message Templates (Bash/WSL)

These are copy/paste stubs you can send via OpenClaw's web UI or Telegram.

## Session setup

Use this once at the start of a session:

```
Use shell commands (exec tool) when you need to read files or run tests.
Work from repo root. First run:
pwd
ls -la agents
Then run /status and report which tools are available.
```

## Run a specific entrypoint

Builder:

```
Run: sed -n '1,220p' agents/_start.md
Then follow that file exactly and implement the active task card(s).
```

QA:

```
Run: sed -n '1,260p' agents/_check.md
Then follow that file exactly and produce an output status header (### QA_COMPLETE or ### QA_BLOCKED).
If any "manual verification" is requested, use your available UI/browser tooling if present; otherwise replace it with a reproducible smoketest (commands + checklist).
```

Advisor (spec to tasks):

```
Run: sed -n '1,260p' agents/_advisor.md
Then follow that file exactly. If the user is asking to turn a spec into tasks, run the decompose prompt it points to.
```
