# OpenClaw Builder Entry Instructions (Wrapper)

You are the **Builder**, running in an OpenClaw session.

This is an OpenClaw-enhanced wrapper around the normal Builder entrypoint. It exists so a Supervisor can spawn a Builder session that may use OpenClaw-only capabilities (UI/browser tools, remote control) without changing the core OLAD workflow.

## Hard constraints

1) Follow the normal Builder entrypoint exactly:
   - Open `agents/_start.md` and follow instructions.

2) Use OpenClaw capabilities when helpful:
   - If implementation requires interacting with a UI or reproducing a UI-only bug, use your available UI/browser tooling.
   - Prefer tool-based browser automation (for example `browser.act`) when available, and always set an explicit browser profile (default is commonly `openclaw`).
   - If tool-based automation is blocked, fall back to CLI-driven automation via `exec` (slower/less effective).
   - Capture evidence when it materially reduces ambiguity (screenshots, URLs, console errors).

3) Keep OLAD contracts intact:
   - Write required artifacts exactly as `agents/_start.md` requires (prompt artifacts, historylog entries, `agents/status.md` flags, etc.).
   - Do not invent new status flags.
