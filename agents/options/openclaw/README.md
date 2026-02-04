# OpenClaw (Runner Integration)

This folder is a lightweight "adapter pack" for running OLAD workflows using an
external agent called **OpenClaw** (typically via a local webapp UI, Telegram,
or a CLI). The goal is to let you keep OLAD generic while still taking
advantage of OpenClaw's extra capabilities (for example: manual UI
verification, remote control, spawning sub-sessions, etc.).

## What this is (and is not)

- This folder does **not** change OLAD behavior by default (Codex/Claude remain the defaults).
- Core OLAD entrypoints remain in `agents/` (for example: `_start.md`, `_check.md`,
  `_hotfix.md`, `_doublecheck.md`, `_advisor.md`, `_orchestrate.md`).
- If you want a "remote-control" supervisor session (Telegram/web UI controlling OLAD runs),
  use `agents/_supervisor.md` (auto-remediation ladder + auto-resume on success).
- OpenClaw can be used as a **first-class runner** by setting `*_RUNNER=openclaw`
  in `agents/options/model_config.md` and configuring the Gateway in
  `agents/options/workflow_config.md`.
- `OPENCLAW_MODE` is a customization-time wiring flag: it persists whether the repo is set up for Supervisor usage (for example, patching the Orchestrator's blocker behavior). Changing the flag alone does not rewrite entrypoints.
- This folder also provides **procedures + copy/paste templates** for driving
  OLAD entrypoints through OpenClaw's web UI/Telegram when you want more direct control.

## Key OpenClaw capabilities (high level)

- Programmatic interfaces: CLI (`openclaw agent --json` / `openclaw sessions --json`) and a local Gateway (HTTP/WS).
- Tooling: can run shell commands and manage background processes (policy permitting).
- Sessions: can spawn and coordinate sub-agent sessions (policy permitting).

## UI/browser automation note (practical)

- Prefer tool-based browser automation (for example `browser.act`) when available.
- Always specify a browser profile explicitly (default profile is commonly `openclaw`).
- If tool-based automation is blocked in your environment, fall back to CLI-driven automation via `exec` (slower/less effective, but sometimes more reliable).

## Next

Start with:
- If using Bash/WSL templates:
  - `agents/options/openclaw/runner_integration_bash.md`
  - `agents/options/openclaw/quickstart_bash.md`
  - `agents/options/openclaw/message_templates_bash.md`
- If using PowerShell templates:
  - `agents/options/openclaw/runner_integration_powershell.md`
  - `agents/options/openclaw/quickstart_powershell.md`
  - `agents/options/openclaw/message_templates_powershell.md`

OpenClaw-only entrypoints:
- Supervisor: `agents/_supervisor.md` (auto-remediation ladder + auto-resume on success)
- UI verification: `agents/options/openclaw/_ui_verify.md` (artifact contract + optional Anti-Gravity analyzer)
- OpenClaw-enhanced wrappers (for Supervisor-driven sessions):
  - Builder: `agents/options/openclaw/_start_openclaw.md`
  - QA: `agents/options/openclaw/_check_openclaw.md`

Related option packs (wired by `agents/_customize.md`):
- UI verification flags + artifact contract: `agents/options/ui-verify/ui_verify_option.md`
- Anti-Gravity quota-safe probe behavior: `agents/options/antigravity/antigravity_option.md`
