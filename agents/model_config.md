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

### 4) Custom

- Set each `*_RUNNER` to `codex` or `claude`.
- Set each `*_MODEL` to a model id (Codex) or a model id/alias (Claude).

---

## Known-good Codex model IDs

These are listed as recommended/alternative models in OpenAI’s Codex Models docs:

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

---

## Sanity checks

- Codex: `codex -m <model> "say hi"` (or run a trivial `codex exec --model <model> ...`)
- Claude: `claude --model <model-or-alias> -p "say hi"`
