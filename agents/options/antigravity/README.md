# Anti-Gravity (Option Pack)

This option pack adds a quota-safe way to use Anti-Gravity/Gemini 3 as part of
UI verification (typically as a *report/analyzer* layer) during OpenClaw runs.

Key idea:
- Do NOT rely on "remaining sessions" API counters.
- Use an authoritative **probe call** on the exact model/provider you are about to use.
- Persist temporary exhaustion flags in `agents/options/workflow_config.md` with minute timestamps.

Start here: `agents/options/antigravity/antigravity_option.md`.

