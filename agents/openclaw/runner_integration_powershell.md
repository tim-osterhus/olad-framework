# OpenClaw Runner Integration (PowerShell)

This repo can treat **OpenClaw** as a first-class runner for any OLAD cycle
(Builder / QA / Hotfix / Doublecheck / Integration), the same way it can use
Codex CLI or Claude Code.

## How OLAD talks to OpenClaw

The headless runner templates in:

- `agents/options/orchestrate/orchestrate_options_powershell.md`

support a runner value of `openclaw`. When selected, the templates call the
OpenClaw **Gateway** OpenResponses-compatible endpoint:

- `POST /v1/responses`

and write:

- `<cycle>.stdout.log` (assistant text)
- `<cycle>.stderr.log` (HTTP/PowerShell errors)
- `<cycle>.openclaw.response.json` (raw JSON response for debugging)

## Prereqs

- PowerShell 5.1 or 7
- OpenClaw Gateway reachable from the machine/shell running orchestration

## 1) Enable the OpenResponses endpoint

OpenClaw's `/v1/responses` endpoint may be disabled by default. Enable it in
OpenClaw config:

```json
{
  "gateway": {
    "http": {
      "endpoints": {
        "responses": { "enabled": true }
      }
    }
  }
}
```

If you do not enable this endpoint, the `openclaw` runner templates will fail
with an HTTP error.

## 2) Configure Gateway URL + Agent ID (repo-side)

Edit `agents/options/workflow_config.md` (commented `## KEY=value` lines):

- `## OPENCLAW_GATEWAY_URL=http://127.0.0.1:18789`
- `## OPENCLAW_AGENT_ID=main`

Notes:

- If orchestration runs on Windows but OpenClaw runs elsewhere, you may need to
  set `OPENCLAW_GATEWAY_URL` to a LAN-accessible address instead of `127.0.0.1`.
- `OPENCLAW_AGENT_ID` selects which OpenClaw agent configuration/policy to use.

## 3) Provide the Gateway token (shell-side)

Do NOT commit tokens to this repo.

The orchestrator templates will use either:

1) An environment variable (current PowerShell session):
   - `$env:OPENCLAW_GATEWAY_TOKEN="..."`
2) Or (preferred) auto-read the token if `openclaw` / `openclaw.exe` is on PATH:
   - `openclaw config get gateway.auth.token --raw`

## 4) Select OpenClaw per cycle (model_config)

Edit `agents/options/model_config.md`:

- Set any `*_RUNNER` to `openclaw`.
- Set the corresponding `*_MODEL` to the string you want passed as `model` to
  `/v1/responses` (often `openclaw`, unless your Gateway accepts provider model
  ids directly).

Example (QA via OpenClaw):

```text
QA_RUNNER=openclaw
QA_MODEL=openclaw
```

## Troubleshooting

- If you see `404` from `/v1/responses`, confirm the endpoint is enabled in the
  OpenClaw config.
- If you see auth errors, confirm the bearer token is correct and that the
  Gateway is expecting `Authorization: Bearer <token>`.
- If you get JSON parsing errors, inspect the raw response saved to
  `<cycle>.openclaw.response.json`.

