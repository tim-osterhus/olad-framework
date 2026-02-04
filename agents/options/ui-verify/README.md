# UI Verify (Option Pack)

This option pack adds a structured, repeatable UI verification pipeline to OLAD.

It is designed to be *installed/wired* by `agents/_customize.md` (progressive disclosure):
- `_customize.md` is the UX/menu layer.
- Full instructions and file packets live here.

Key idea:
- **Deterministic outputs** (`PASS|FAIL|BLOCKED`) should come from automation (Playwright/OpenClaw tooling), not LLM opinion.
- LLM analysis may explain failures, but must not override the deterministic result.

Start here: `agents/options/ui-verify/ui_verify_option.md`.

