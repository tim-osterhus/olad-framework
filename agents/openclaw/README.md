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
- OpenClaw can be used as a **first-class runner** by setting `*_RUNNER=openclaw`
  in `agents/options/model_config.md` and configuring the Gateway in
  `agents/options/workflow_config.md`.
- This folder also provides **procedures + copy/paste templates** for driving
  OLAD entrypoints through OpenClaw's web UI/Telegram when you want more direct control.

## Key OpenClaw capabilities (as reported in `openclaw_response.txt`)

- Toggle "reasoning" via `/reasoning`; check status via `/status`.
- Run shell commands via an `exec` tool (including background processes).
- Spawn sub-agent sessions via `sessions_spawn` and coordinate via
  `sessions_list` / `sessions_history` / `sessions_send`.

## Next

Start with:
- `agents/openclaw/runner_integration_bash.md` (this repo defaults to Bash/WSL templates; you can switch during customization)
- `agents/openclaw/quickstart_bash.md`
- `agents/openclaw/message_templates_bash.md`
