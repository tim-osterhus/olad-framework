# Examples: OpenClaw OLAD Runner

This file stores detailed, real-world examples for the **openclaw-olad-runner** skill.

**CRITICAL:** Append new examples to the END of this file (to keep line references stable).

---

## Example 1: Run QA via OpenClaw Gateway (Bash/WSL)

**Tags**: `runner`, `gateway`, `openresponses`, `wsl`, `bash`, `olad`, `qa`

**Trigger phrases** (grep these to find this example):
- "QA_RUNNER=openclaw"
- "POST /v1/responses"
- "<cycle>.openclaw.response.json"

**Date**: 2026-01-31

**Problem**:
You want to run OLAD’s QA cycle using OpenClaw as the runner so you can keep OLAD’s file-based flow, but still use OpenClaw tooling (exec/UI verification/sub-agents). The orchestrator must call the Gateway’s OpenResponses-compatible `POST /v1/responses` endpoint and write logs for evidence.

**Impact**:
- Without this working, OLAD cannot run headlessly via OpenClaw.
- You lose OpenClaw-only capabilities (exec, browser/UI verification, Telegram remote control) during the cycle.

**Root cause**:
Not a single bug — it’s missing wiring:
- `/v1/responses` endpoint is disabled by default.
- OLAD runner config isn’t pointing at the correct Gateway URL/agent.
- Auth (token/password) isn’t being supplied to the HTTP request.

**Fix**:

1) **Confirm OpenClaw version + Gateway is running**

- Check version (expect `2026.1.30` or later):
  - `openclaw --version`
- Ensure the Gateway is up:
  - `openclaw gateway status`
  - If needed: `openclaw gateway start`

2) **Enable the OpenResponses HTTP endpoint**

Enable `gateway.http.endpoints.responses.enabled`:

- Preferred (CLI):
  - `openclaw config set gateway.http.endpoints.responses.enabled true`
  - `openclaw gateway restart`

3) **Get the Gateway auth token safely (do not commit it)**

Choose ONE:

- Export for the current shell:
  - `export OPENCLAW_GATEWAY_TOKEN="<token>"`

- Or read it locally (same machine) if configured:
  - `openclaw config get gateway.auth.token --raw`

4) **Run a minimal `/v1/responses` healthcheck**

Set the base URL (adjust host/port as needed):

- `export OPENCLAW_GATEWAY_URL="http://127.0.0.1:18789"`

Non-streaming:

```bash
curl -sS "$OPENCLAW_GATEWAY_URL/v1/responses" \
  -H "Authorization: Bearer $OPENCLAW_GATEWAY_TOKEN" \
  -H "Content-Type: application/json" \
  -H "x-openclaw-agent-id: main" \
  -d '{"model":"openai-codex/gpt-5.2","input":"ping"}' \
  | tee /tmp/openclaw_ping.json
```

Extract final text robustly (handles both `output_text` convenience field and nested output items):

```bash
python3 - <<'PY'
import json
p=json.load(open('/tmp/openclaw_ping.json','r',encoding='utf-8'))
# Prefer OpenAI-style convenience field if present
if isinstance(p, dict) and isinstance(p.get('output_text'), str) and p['output_text'].strip():
  print(p['output_text'])
  raise SystemExit(0)
# Fallback: traverse output items
out=[]
for item in p.get('output', []) if isinstance(p, dict) else []:
  for part in item.get('content', []) if isinstance(item, dict) else []:
    if part.get('type') in ('output_text','text') and isinstance(part.get('text'), str):
      out.append(part['text'])
print(''.join(out).strip())
PY
```

Expected outcome:
- HTTP 200
- JSON response saved to `/tmp/openclaw_ping.json`
- The printed text includes a response to “ping” (often “ping” → “pong” or a short greeting).

5) **Wire OLAD to OpenClaw**

Repo-side settings (typical):

- `agents/options/workflow_config.md`
  - `OPENCLAW_GATEWAY_URL=http://127.0.0.1:18789` (or a host-reachable URL)
  - `OPENCLAW_AGENT_ID=main`

- `agents/options/model_config.md`
  - `QA_RUNNER=openclaw`
  - Set the model value your orchestrator passes:
    - recommended (Gateway/provider model id): `QA_MODEL=openai-codex/gpt-5.2`
    - optional (only if your Gateway supports it): `QA_MODEL=openclaw`

Shell-side (do not commit):
- `export OPENCLAW_GATEWAY_TOKEN="..."`

6) **Run the QA cycle and confirm evidence logs exist**

Run the normal OLAD orchestrate command/script you use for QA (the repo’s orchestrate options should:
- call `POST /v1/responses`
- write `<cycle>.stdout.log`, `<cycle>.stderr.log`, and `<cycle>.openclaw.response.json`

Validate:
- `<cycle>.stderr.log` is empty or contains only non-fatal notes.
- `<cycle>.stdout.log` contains the assistant’s final report.
- `<cycle>.openclaw.response.json` contains the raw response payload.

**Prevention**:
- Keep a 5-second “gateway ping” command in your runbook and run it before any long OLAD cycle.
- Avoid `OPENCLAW_GATEWAY_URL=http://127.0.0.1:18789` when the orchestrator runs on a different host/VM/WSL instance.

**References**:
- `agents/options/workflow_config.md`
- `agents/options/model_config.md`
- `agents/options/orchestrate/orchestrate_options_bash.md`

---

## Example 2: 404 from /v1/responses (endpoint disabled or config mismatch)

**Tags**: `gateway`, `openresponses`, `troubleshooting`, `config`, `service`, `profiles`

**Trigger phrases**:
- "404"
- "Not Found"
- "/v1/responses"
- "responses.enabled"

**Date**: 2026-01-31

**Problem**:
The orchestrator (or a manual curl test) hits the Gateway but gets `404 Not Found` from `POST /v1/responses`.

**Impact**:
- OLAD cannot use OpenClaw as a headless runner.
- Debugging is confusing because the Gateway is “up,” but the endpoint does not exist.

**Root cause**:
One of these:
1) The OpenResponses endpoint is disabled by default (`gateway.http.endpoints.responses.enabled=false`).
2) You enabled it, but the Gateway service is running a different profile/config than the one you edited.

**Fix**:

1) **Confirm the Gateway you’re talking to is the one you’re configuring**

- Check service status + resolved port/config:
  - `openclaw gateway status --json`

If it shows a config mismatch (CLI config path differs from service config path):
- Reinstall or restart the service from the profile you intend to use.
  - `openclaw gateway install --force` (run from the intended profile)
  - `openclaw gateway restart`

2) **Enable the endpoint in the same profile the service uses**

- `openclaw config set gateway.http.endpoints.responses.enabled true`
- `openclaw gateway restart`

If you use named profiles:
- Use the same `--profile <name>` everywhere:
  - `openclaw --profile <name> config set ...`
  - `openclaw --profile <name> gateway restart`

3) **Re-test**

- Run the minimal curl healthcheck from Example 1.
- Expect HTTP 200.

**Prevention**:
- Standardize on ONE OpenClaw profile for OLAD (document it in your repo’s `workflow_config.md`).
- When debugging, always capture `openclaw status --all` and `openclaw gateway status --json` so you can see profile/port drift immediately.

**References**:
- `openclaw gateway status --json`
- `openclaw config set gateway.http.endpoints.responses.enabled true`
- `openclaw gateway restart`

---

## Example 3: WSL can’t reach the Windows-hosted Gateway (connection refused)

**Tags**: `wsl`, `windows`, `networking`, `gateway`, `connection-refused`, `runner`

**Trigger phrases**:
- "Connection refused"
- "Failed to connect"
- "OPENCLAW_GATEWAY_URL=http://127.0.0.1:18789"

**Date**: 2026-01-31

**Problem**:
OLAD orchestration runs in WSL (Bash), but OpenClaw Gateway is running on the Windows host. Using `OPENCLAW_GATEWAY_URL=http://127.0.0.1:18789` from WSL fails with connection refused.

**Impact**:
The OpenClaw runner appears “broken” even though the Gateway is healthy from Windows.

**Root cause**:
`127.0.0.1` is “this network namespace.” In WSL, that can refer to WSL itself, not the Windows host. Depending on how OpenClaw is bound and how WSL port-forwarding is configured, loopback may not traverse from WSL → Windows.

**Fix**:

1) **Confirm what OpenClaw is bound to**

On Windows:
- `openclaw gateway status` should show bind mode and port.

If it’s loopback-only, it may not be reachable from WSL. Options:

A) **Keep loopback-only and run orchestration on Windows**
- Use the PowerShell orchestrate option templates.

B) **Bind the Gateway to LAN and keep auth on** (only if you accept the risk)
- `openclaw config set gateway.bind lan`
- Ensure auth is enabled:
  - `openclaw config set gateway.auth.mode token`
  - (Set/rotate token via `gateway.auth.token` or env)
- `openclaw gateway restart`
- Set `OPENCLAW_GATEWAY_URL` in WSL to the Windows LAN IP (not 0.0.0.0).

2) **Re-test from WSL**

- `curl -sS http://<windows-lan-ip>:18789/v1/responses ...`

**Stop / BLOCKED behavior**:
If you cannot change Gateway bind settings (policy/security constraints), mark BLOCKED and ask for one of:
- permission to run orchestration on the same host as the Gateway, or
- a LAN/tailnet URL that is reachable from the orchestrator environment.

**Prevention**:
- Decide early whether “the orchestrator shell” and “the OpenClaw Gateway host” are the same machine. If not, treat it as a networked service and configure binds/auth deliberately.

**References**:
- `openclaw config set gateway.bind lan`
- `openclaw gateway restart`

---

## Example 4: Stream output (SSE) and keep a stable session for follow-ups

**Tags**: `streaming`, `sse`, `openresponses`, `session`, `runner`, `debugging`

**Trigger phrases**:
- '"stream": true'
- "response.output_text.delta"
- "data: [DONE]"

**Date**: 2026-01-31

**Problem**:
You want intermediate output events (token deltas / item events) and you want to run follow-up prompts in the *same* OpenClaw session so the agent keeps conversational context.

**Impact**:
- Without streaming you only get the final payload, making debugging slow.
- Without stable session routing, each call behaves like a fresh chat (context resets).

**Root cause**:
- The OpenResponses endpoint is stateless per request by default.
- Streaming only happens when `stream: true` is set.

**Fix**:

1) Use `stream: true` and a stable `user` key.

```bash
export OPENCLAW_GATEWAY_URL="http://127.0.0.1:18789"
export OPENCLAW_GATEWAY_TOKEN="<token>"
export OPENCLAW_USER_KEY="olad:qa:repo-xyz"  # any stable string

curl -N "$OPENCLAW_GATEWAY_URL/v1/responses" \
  -H "Authorization: Bearer $OPENCLAW_GATEWAY_TOKEN" \
  -H "Content-Type: application/json" \
  -H "x-openclaw-agent-id: main" \
  -d "$(cat <<JSON
{
  \"model\": \"openclaw\",
  \"stream\": true,
  \"user\": \"$OPENCLAW_USER_KEY\",
  \"input\": \"Summarize the current OLAD task card.\"
}
JSON
)"
```

2) For the follow-up prompt, keep the same `user` value:

```bash
curl -sS "$OPENCLAW_GATEWAY_URL/v1/responses" \
  -H "Authorization: Bearer $OPENCLAW_GATEWAY_TOKEN" \
  -H "Content-Type: application/json" \
  -H "x-openclaw-agent-id: main" \
  -d "$(cat <<JSON
{
  \"model\": \"openclaw\",
  \"user\": \"$OPENCLAW_USER_KEY\",
  \"input\": \"Now list the concrete next actions and risks.\"
}
JSON
)" \
  | tee /tmp/openclaw_followup.json
```

**Prevention**:
- Pick a deterministic `user` key format for OLAD runs (e.g., `olad:<cycle>:<repo>:<branch>`).
- When debugging, prefer `stream: true` so you can see tool calls and deltas as they happen.

**References**:
- `POST /v1/responses` streaming event types and `user` session behavior (OpenClaw docs)

---

## Example 5: Attach a file (diff/spec) to /v1/responses without leaking secrets

**Tags**: `input_file`, `attachments`, `openresponses`, `security`, `runner`

**Trigger phrases**:
- "input_file"
- "media_type"
- "allowedMimes"

**Date**: 2026-01-31

**Problem**:
You want the OpenClaw runner to receive a local file (task card, diff, or spec) as context without copy/pasting huge blobs into the prompt.

**Impact**:
- Copy/paste increases mistakes and loses provenance.
- If you paste secrets, they may end up in logs.

**Root cause**:
The OpenResponses request needs an `input` array with an `input_file` item whose `source` is base64 (or a URL if allowed).

**Fix**:

1) Base64-encode the file locally (shell-side):

```bash
FILE_PATH="agents/tasks/2026-01-31_my_task.md"
B64="$(python3 - <<'PY'
import base64,sys
p=sys.argv[1]
print(base64.b64encode(open(p,'rb').read()).decode('ascii'))
PY
"$FILE_PATH")"

curl -sS "$OPENCLAW_GATEWAY_URL/v1/responses" \
  -H "Authorization: Bearer $OPENCLAW_GATEWAY_TOKEN" \
  -H "Content-Type: application/json" \
  -H "x-openclaw-agent-id: main" \
  -d "$(cat <<JSON
{
  \"model\": \"openclaw\",
  \"input\": [
    { \"type\": \"message\", \"role\": \"user\", \"content\": \"Read the attached task card and produce a plan.\" },
    {
      \"type\": \"input_file\",
      \"source\": {
        \"type\": \"base64\",
        \"media_type\": \"text/markdown\",
        \"data\": \"$B64\",
        \"filename\": \"my_task.md\"
      }
    }
  ]
}
JSON
)" \
  | tee /tmp/openclaw_with_file.json
```

2) If the Gateway rejects the file:
- Check `gateway.http.endpoints.responses.files.allowedMimes` and `files.maxBytes` in OpenClaw config.
- Avoid sending large PDFs unless you’ve tuned `files.pdf.maxPages` appropriately.

**Prevention**:
- Treat attached files as untrusted input; never attach secrets.
- Prefer attaching small, scoped artifacts (task card, spec section, diff) rather than entire repos.

**References**:
- `gateway.http.endpoints.responses.files.*` limits and allowed MIME types (OpenClaw docs)
