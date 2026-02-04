# Anti-Gravity Option (Gemini 3 quota-safe UI analysis)

This option is intended to be used by `agents/_customize.md` in combination with:
- `agents/options/ui-verify/ui_verify_option.md`
- `agents/options/openclaw/_ui_verify.md`

Goal: safely use Gemini 3 (Flash / Pro-low / Pro-high) as an analysis layer during UI verification without blocking OLAD runs on quota surprises.

## Core rule: probe-call only (no quota API)

Anti-Gravity/Gemini quotas are treated as *unknown* until verified by an authoritative probe call:
- Make a tiny, cheap request using the **same provider/model** you are about to use.
- If it succeeds: proceed.
- If it fails due to quota/rate-limit: fall back to the next model.

## Model set + exhaustion flags

OLAD treats these as three independently quota'd "models":
- Gemini 3 Flash
- Gemini 3 Pro (low)
- Gemini 3 Pro (high)

When a model hits quota, write a flag in `agents/options/workflow_config.md` with a timestamp-to-the-minute:
- `## ANTIGRAVITY_G3_FLASH_EXHAUSTED_AT=YYYY-MM-DDTHH:MM`
- `## ANTIGRAVITY_G3_PRO_LOW_EXHAUSTED_AT=YYYY-MM-DDTHH:MM`
- `## ANTIGRAVITY_G3_PRO_HIGH_EXHAUSTED_AT=YYYY-MM-DDTHH:MM`

These are temporary hints; they should be cleared automatically on a successful probe, or manually if desired.

## Required workflow flags

All flags live in `agents/options/workflow_config.md`:
- `UI_VERIFY_QUOTA_GUARD=on|off`
- `ANTIGRAVITY_MODEL_PREF=auto|flash|pro_low|pro_high`
- `ANTIGRAVITY_PROBE_MODE=probe_call`
- `ANTIGRAVITY_G3_*_EXHAUSTED_AT=` flags

Optional (recommended): model ids/aliases for your environment.

Because Anti-Gravity installs differ, OLAD keeps these as configurable strings:
- `ANTIGRAVITY_G3_FLASH_MODEL=<MODEL_ID>`
- `ANTIGRAVITY_G3_PRO_LOW_MODEL=<MODEL_ID>`
- `ANTIGRAVITY_G3_PRO_HIGH_MODEL=<MODEL_ID>`

If your Anti-Gravity integration does not require model ids (for example it uses fixed names),
you can still set these to the same values as the pref tokens; the probe scripts treat them as opaque.

## Scripts provided by this option pack

The scripts here implement the "probe call" + flag persistence. They are designed to be called
from an OpenClaw UI verification session (via tool-based exec), or from a local runner shell.

- `probe_gemini_auto.(sh|ps1)`:
  - reads config + exhaustion flags
  - tries models in the selected order
  - performs a tiny probe call
  - on quota error: sets the model's exhausted flag and tries the next
  - on success: prints the chosen model id and exits 0
  - if all fail: exits 2 (treat as "all quotas exhausted")

- `probe_gemini_flash.(sh|ps1)`, `probe_gemini_pro_low.(sh|ps1)`, `probe_gemini_pro_high.(sh|ps1)`:
  - helper wrappers around the same probe function (useful for debugging)

## Probe implementation (default)

By default, the probe scripts use the OpenClaw Gateway (`POST /v1/responses`) to execute the probe call.
This keeps OLAD generic and avoids baking in a private Anti-Gravity API.

If your environment uses a dedicated Anti-Gravity CLI/API instead of OpenClaw Gateway routing:
- Replace the probe function body in the scripts with your Anti-Gravity invocation.
- Keep the same exit codes and exhaustion-flag behavior.

## Fallback behavior (required)

If ALL three models are exhausted or blocked:
- UI verification must fall back to OpenClaw-native UI automation (no Anti-Gravity).

If OpenClaw UI automation is also blocked and troubleshooting cannot fix it:
- The Supervisor must ask the user whether to switch to smoketest-based UI verification.

## Files this option may touch

During execution (not install), scripts/agents may update:
- `agents/options/workflow_config.md` (only the exhaustion timestamp keys, and optional model-id keys if you choose to store them there)

During install/wiring:
- `agents/options/workflow_config.md` (add the new keys)
- `agents/_customize.md` (ask for UI verification + Anti-Gravity preferences)

