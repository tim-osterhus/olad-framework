# OpenClaw Quickstart (Bash/WSL)

This is a practical way to run OLAD cycles through OpenClaw (web UI, Telegram,
or CLI).

If you want OpenClaw to be a first-class runner (selected via
`agents/options/model_config.md` and launched from the headless orchestrator
templates), start with `agents/options/openclaw/runner_integration_bash.md` instead.

## Assumptions

- OpenClaw is running on a machine that has this repo checked out.
- OpenClaw can run shell commands (for example via an `exec` tool).

If OpenClaw can "open files" directly, great. If not, just use shell commands
to read files (examples below).

## Minimal setup checklist (recommended per session)

1) In OpenClaw, run `/status` and confirm tools are available (at least `exec`).
2) Optional: run `/reasoning` if you want higher reasoning for this session.
3) Confirm repo location (example):
   - Run: `pwd`
   - Then: `ls -la agents`

## Run an OLAD cycle

Pick the entrypoint you want and instruct OpenClaw to open it and follow it.

Builder:
- Read: `sed -n '1,220p' agents/_start.md`
- Then follow the instructions in that file exactly.

QA:
- Read: `sed -n '1,260p' agents/_check.md`
- Then follow the instructions in that file exactly.

Advisor:
- Read: `sed -n '1,240p' agents/_advisor.md`
- Then follow the instructions in that file exactly.

Hotfix:
- Read: `sed -n '1,240p' agents/_hotfix.md`
- Then follow the instructions in that file exactly.

Doublecheck:
- Read: `sed -n '1,260p' agents/_doublecheck.md`
- Then follow the instructions in that file exactly.

Orchestrate (multi-cycle runner):
- Read: `sed -n '1,320p' agents/_orchestrate.md`
- Then follow the instructions in that file exactly.

## Capturing results (lightweight)

At minimum:
- Paste OpenClaw's final report into the relevant run log or PR body.
- Ensure any files the workflow expects (for example prompt artifacts,
  expectations updates, historylog updates) are present in the repo.
