# Model config

This file is the **only** place you should change model choices for OLAD cycles.
`agents/_orchestrate.md` reads these values and routes each cycle to the right runner.

## Active config (edit these KEY=value lines)

INTEGRATION_RUNNER=codex
INTEGRATION_MODEL=gpt-5.2-codex

BUILDER_RUNNER=codex
BUILDER_MODEL=gpt-5.2-codex

QA_RUNNER=claude
QA_MODEL=sonnet

HOTFIX_RUNNER=codex
HOTFIX_MODEL=gpt-5.2-codex

DOUBLECHECK_RUNNER=claude
DOUBLECHECK_MODEL=sonnet

---

## Presets (copy/paste over the Active config section)

### 1) Default (Codex Integration/Builder/Hotfix, Claude QA/Doublecheck)

INTEGRATION_RUNNER=codex
INTEGRATION_MODEL=gpt-5.2-codex

BUILDER_RUNNER=codex
BUILDER_MODEL=gpt-5.2-codex

QA_RUNNER=claude
QA_MODEL=sonnet

HOTFIX_RUNNER=codex
HOTFIX_MODEL=gpt-5.2-codex

DOUBLECHECK_RUNNER=claude
DOUBLECHECK_MODEL=sonnet

### 1.5) Default Performance (Codex Integration/Builder/Hotfix, Claude QA/Doublecheck on Opus)

INTEGRATION_RUNNER=codex
INTEGRATION_MODEL=gpt-5.2-codex

BUILDER_RUNNER=codex
BUILDER_MODEL=gpt-5.2-codex

QA_RUNNER=claude
QA_MODEL=opus

HOTFIX_RUNNER=codex
HOTFIX_MODEL=gpt-5.2-codex

DOUBLECHECK_RUNNER=claude
DOUBLECHECK_MODEL=opus

### 2) All Codex

INTEGRATION_RUNNER=codex
INTEGRATION_MODEL=gpt-5.2-codex

BUILDER_RUNNER=codex
BUILDER_MODEL=gpt-5.2-codex

QA_RUNNER=codex
QA_MODEL=gpt-5.2-codex

HOTFIX_RUNNER=codex
HOTFIX_MODEL=gpt-5.2-codex

DOUBLECHECK_RUNNER=codex
DOUBLECHECK_MODEL=gpt-5.2-codex

### 2.5) All Codex Performance (Codex everywhere, higher-reasoning for QA/Doublecheck)

INTEGRATION_RUNNER=codex
INTEGRATION_MODEL=gpt-5.2-codex

BUILDER_RUNNER=codex
BUILDER_MODEL=gpt-5.2-codex

QA_RUNNER=codex
QA_MODEL=gpt-5.2

HOTFIX_RUNNER=codex
HOTFIX_MODEL=gpt-5.2-codex

DOUBLECHECK_RUNNER=codex
DOUBLECHECK_MODEL=gpt-5.2

### 3) All Claude

INTEGRATION_RUNNER=claude
INTEGRATION_MODEL=sonnet

BUILDER_RUNNER=claude
BUILDER_MODEL=sonnet

QA_RUNNER=claude
QA_MODEL=sonnet

HOTFIX_RUNNER=claude
HOTFIX_MODEL=sonnet

DOUBLECHECK_RUNNER=claude
DOUBLECHECK_MODEL=sonnet

### 3.5) All Claude Performance (Claude everywhere on Opus)

INTEGRATION_RUNNER=claude
INTEGRATION_MODEL=opus

BUILDER_RUNNER=claude
BUILDER_MODEL=opus

QA_RUNNER=claude
QA_MODEL=opus

HOTFIX_RUNNER=claude
HOTFIX_MODEL=opus

DOUBLECHECK_RUNNER=claude
DOUBLECHECK_MODEL=opus

### 4) All OpenClaw

Use this if you want OpenClaw to run every cycle (Builder/QA/etc.).

INTEGRATION_RUNNER=openclaw
INTEGRATION_MODEL=<OPENCLAW_GATEWAY_MODEL_ID>

BUILDER_RUNNER=openclaw
BUILDER_MODEL=<OPENCLAW_GATEWAY_MODEL_ID>

QA_RUNNER=openclaw
QA_MODEL=<OPENCLAW_GATEWAY_MODEL_ID>

HOTFIX_RUNNER=openclaw
HOTFIX_MODEL=<OPENCLAW_GATEWAY_MODEL_ID>

DOUBLECHECK_RUNNER=openclaw
DOUBLECHECK_MODEL=<OPENCLAW_GATEWAY_MODEL_ID>

### 5) Custom

- Set each `*_RUNNER` to `codex`, `claude`, or `openclaw`.
- Set each `*_MODEL` to:
  - Codex: a model id (example: `gpt-5.2-codex`)
  - Claude: a model alias/id (example: `sonnet`)
  - OpenClaw: a model string passed to OpenClaw's OpenResponses endpoint (`/v1/responses`)
    (typically a Gateway/provider model id; some installs may also support an alias like `openclaw`)

---

## Known-good Codex model IDs

These are listed as recommended/alternative models in OpenAI's Codex Models docs:

- gpt-5.2-codex
- gpt-5.1-codex-max
- gpt-5.1-codex-mini
- gpt-5.2
- gpt-5.1
- gpt-5.1-codex
- gpt-5-codex
- gpt-5-codex-mini
- gpt-5

(Availability depends on your Codex authentication + plan.)

## Known-good Claude model aliases / IDs

Claude Code supports model **aliases** (e.g. `sonnet`, `opus`) and full model names.

- Alias: sonnet
- Alias: opus
- Alias: haiku
- Example full id: claude-sonnet-4-5-20250929

If a full id stops working, prefer using `sonnet`/`opus` aliases unless you need a pinned version.

## OpenClaw model strings

OpenClaw is a runner that sits behind a local Gateway. For OpenClaw cycles, OLAD
passes your `*_MODEL` string as the `model` field to the Gateway `/v1/responses`
request.

If you are unsure what to put here, start with:

- a model id your OpenClaw Gateway accepts (example: `openai-codex/gpt-5.2`)

If your Gateway supports an alias like `openclaw`, you can use that instead.

---

## Sanity checks

- Codex: `codex -m <model> "say hi"` (or run a trivial `codex exec --model <model> ...`)
- Claude: `claude --model <model-or-alias> -p "say hi"`
- OpenClaw: `openclaw agent --message "say hi" --json` (or see `agents/options/openclaw/runner_integration_bash.md`)
