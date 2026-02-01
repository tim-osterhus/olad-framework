---
name: openclaw-olad-runner
description: >
  Run OLAD entrypoint cycles through an OpenClaw Gateway (OpenResponses-compatible /v1/responses) or by driving OpenClaw chat (Web UI/Telegram). This skill should be used when OLAD is configured with *_RUNNER=openclaw, when troubleshooting /v1/responses (401/404/connection errors), or when you need OpenClaw-only capabilities (exec, browser/UI verification, sub-agent sessions) during an OLAD cycle.
version: "0.1.0"
tags: ["runner", "openclaw", "gateway", "olad", "orchestrate"]
---

# Run OLAD via OpenClaw Gateway

## Quick start
Goal:
- Run an OLAD cycle using OpenClaw as the runner and capture deterministic logs + the raw gateway JSON response.

Use when (triggers):
- You see or need to set `*_RUNNER=openclaw` in `agents/options/model_config.md`.
- You need to call OpenClaw’s `POST /v1/responses` (OpenResponses-compatible) from a headless runner.
- You need OpenClaw tooling during an OLAD cycle (e.g., `exec`, browser/UI verification, or `sessions_spawn`).
- You’re debugging OpenClaw runner failures (common: `401`, `404`, connection refused, token/config mismatch).

Do NOT use when (non-goals):
- You are running OLAD directly with Codex CLI / Claude Code and do not need OpenClaw features.
- You cannot reach the OpenClaw Gateway and you do not have permission to change OpenClaw config/service state.

## Operating constraints
- No secrets: never commit gateway tokens/passwords; never paste them into repo logs.
- Keep the Gateway private by default: prefer loopback binds; if LAN/tailnet is required, enforce auth.
- Be minimal: touch only the OLAD runner config needed for OpenClaw.
- Be explicit: record exact endpoint URL, agent id, and which shell is orchestrating (Bash/WSL vs PowerShell).

## Inputs this Skill expects
Required:
- OLAD entrypoints in `agents/` (e.g., `_start.md`, `_check.md`, `_advisor.md`, `_orchestrate.md`).
- Runner config files:
  - `agents/options/model_config.md`
  - `agents/options/workflow_config.md`
  - one of:
    - `agents/options/orchestrate/orchestrate_options_bash.md`
    - `agents/options/orchestrate/orchestrate_options_powershell.md`
- A running OpenClaw Gateway that is reachable from the orchestrator shell.

Optional:
- OpenClaw adapter docs under `agents/options/openclaw/` (quickstart + runner notes).
- OpenClaw CLI access on the same machine as the Gateway (for `openclaw config …`, `openclaw gateway …`).

If required inputs are missing:
- Proceed with safest defaults (loopback URL + token auth), and list assumptions.
- If the Gateway is unreachable, stop and mark BLOCKED with the minimum missing info to proceed.

## Output contract
Primary deliverable:
- A repeatable “OpenClaw runner” setup that includes:
  - OLAD config values (runner + gateway URL + agent id)
  - A minimal `/v1/responses` healthcheck command
  - Evidence logs from one completed OLAD cycle (stdout/stderr + raw JSON)

Definition of DONE (objective checks):
- [ ] Gateway healthcheck succeeds (HTTP 200 from `POST /v1/responses`).
- [ ] At least one OLAD cycle runs end-to-end via OpenClaw and produces the expected runner logs.
- [ ] No secrets were committed or pasted into repo artifacts.

## Procedure (copy into working response and tick off)
Progress:
- [ ] 1) Confirm scope + constraints
- [ ] 2) Locate runner config + entrypoints
- [ ] 3) Make the OpenClaw Gateway callable
- [ ] 4) Wire OLAD to OpenClaw (runner + URL + agent)
- [ ] 5) Validate with a minimal healthcheck
- [ ] 6) Run an OLAD cycle + capture evidence

### 1) Confirm scope + constraints
- Restate the target cycle(s) (Builder/QA/Advisor/Orchestrate) in one sentence.
- Confirm where OpenClaw runs vs where orchestration runs (same host, Windows↔WSL, or LAN).
- Confirm the required OpenClaw capabilities for this run (minimum: `/v1/responses`; optional: `exec`, browser, sub-agents).

### 2) Locate runner config + entrypoints
Search terms:
- `OPENCLAW_GATEWAY_URL`
- `OPENCLAW_AGENT_ID`
- `RUNNER=openclaw`
- `/v1/responses`

Inspect first:
1) `agents/options/workflow_config.md` (Gateway URL + agent id)
2) `agents/options/model_config.md` (`*_RUNNER` + `*_MODEL`)
3) `agents/options/orchestrate/orchestrate_options_*` (how requests/logs are emitted)

### 3) Make the OpenClaw Gateway callable
- Ensure the Gateway is running and reachable.
- Ensure auth is configured (token or password).
- Enable the OpenResponses HTTP endpoint if needed: `gateway.http.endpoints.responses.enabled=true`.

### 4) Wire OLAD to OpenClaw (runner + URL + agent)
- Set the relevant `*_RUNNER=openclaw` values.
- Ensure the runner knows:
  - `OPENCLAW_GATEWAY_URL` (http base URL)
  - how to authenticate (bearer token or password)
  - which agent id to target (either `model: openclaw:<agentId>` or header `x-openclaw-agent-id: <agentId>`)

### 5) Validate with a minimal healthcheck
- Run a minimal `POST /v1/responses` call.
- Verify you can extract the assistant’s final text deterministically from the JSON payload.

### 6) Run an OLAD cycle + capture evidence
- Run one OLAD entrypoint through the OpenClaw runner.
- Follow the entrypoint file exactly (do not paraphrase its constraints or required output headers).
- Capture:
  - `<cycle>.stdout.log`
  - `<cycle>.stderr.log`
  - `<cycle>.openclaw.response.json`
- Summarize what happened and link the evidence logs.

## Pitfalls / gotchas
- `POST /v1/responses` returns `404`: endpoint is disabled by default; you must enable it in OpenClaw config.
- `401` / auth failures: you’re missing `Authorization: Bearer …` or using the wrong auth mode.
- Wrong config/profile: the CLI and the Gateway service can be reading different `~/.openclaw-*` profiles.
- Windows↔WSL loopback confusion: `127.0.0.1` might point at the wrong host from the orchestrator shell.

## Progressive disclosure
- Full walkthroughs + failure modes: `./EXAMPLES.md`

## Example References (concise summaries only)
1. **Run QA via OpenClaw (WSL/Bash) end-to-end** — enable `/v1/responses`, set OLAD runner vars, run cycle, and capture logs. See EXAMPLES.md:9-139
2. **Fix 404 on /v1/responses (endpoint disabled or wrong profile)** — enable endpoint + restart Gateway, confirm config mismatch. See EXAMPLES.md:142-200
3. **Fix Windows↔WSL connection issues** — resolve host/port routing and avoid loopback traps. See EXAMPLES.md:204-258
4. **Stream SSE output and reuse session context** — use `stream: true` and a stable `user` key for multi-turn runs. See EXAMPLES.md:262-332
5. **Attach local files safely** — pass diffs/specs as `input_file` without leaking secrets. See EXAMPLES.md:335-403
