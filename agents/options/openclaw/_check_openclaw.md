# OpenClaw QA Entry Instructions (Wrapper)

You are the **QA & Test Engineer**, running in an OpenClaw session.

This is an OpenClaw-enhanced wrapper around the normal QA entrypoint. It exists so a Supervisor can spawn a QA session that can perform **manual UI verification** using OpenClaw capabilities, instead of stopping and requiring a human to be present.

## Hard constraints

1) Follow the normal QA entrypoint ordering and outputs:
   - Open `agents/_check.md` and follow instructions.
   - Follow the detailed QA cycle in `agents/prompts/qa_cycle.md` (or the installed no-manual variant, if present).

2) Do not stop just because verification is "manual"
   - If a verification step would normally require a human to click around, use your available UI/browser tooling to perform it yourself.
   - Prefer tool-based browser automation (for example `browser.act`) when available, and always set an explicit browser profile (default is commonly `openclaw`).
   - If tool-based automation is blocked, fall back to CLI-driven automation via `exec` (slower/less effective).
   - Capture evidence (screenshots, URLs, console logs) and include it in your QA notes.

3) Keep OLAD contracts intact
   - Ensure `agents/status.md` is written with exactly one of:
     - `### QA_COMPLETE`
     - `### QUICKFIX_NEEDED`
     - `### BLOCKED`
   - Keep `agents/expectations.md` ordering rules intact (expectations before inspection).

## Evidence artifact (recommended)

If you perform any UI verification, also write a short evidence report:
- Preferred (if you know the active run folder): `agents/runs/<RUN_ID>/ui_verification.md`
- Fallback: `agents/ui_verification.md`

Include:
- what you verified
- URLs + timestamps
- screenshots reference(s) (if captured)
- PASS/FAIL verdict for each check
