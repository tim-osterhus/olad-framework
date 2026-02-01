# OLAD Framework Revamp (Upgrade Guide)

Use this guide to upgrade an existing OLAD installation without overwriting
repo-specific content. The goal is to refresh framework files (entrypoints,
prompts, skills, options, docs) while preserving project state and history.

## Assumptions (layout)

You have staged the updated framework at repo root as:
- `./olad-framework/` (the incoming, updated framework snapshot)

And you have an existing (already customized) OLAD installation at repo root as:
- `./agents/` (the installed framework + project artifacts)

Your job during a revamp is to copy/merge *framework-owned* updates from
`olad-framework/` into the live repo root **without** overwriting repo-specific
artifacts (tasks/history/spec/etc.).

## When to use
- You are updating an older OLAD folder to a newer version.
- You need to add new framework options, skills, or entrypoints.
- You must keep project-specific artifacts intact.

## Hard rules (do not violate)
- Do **not** edit or delete repo-specific files.
- Do **not** touch task/history artifacts.
- Do **not** rewrite user configuration values.
- If unsure, stop and ask.

## Files to preserve (never edit)
These are repo-specific and must remain untouched:
- `README.md` (project context + guardrails)
- `agents/spec.md`
- `agents/outline.md`
- `agents/tasks.md`
- `agents/tasksbacklog.md`
- `agents/tasksarchive.md`
- `agents/historylog.md`
- `agents/expectations.md`
- `agents/roadmap.md`
- `agents/quickfix.md`
- Any `agents/runs/`, `agents/diagnostics/`, `agents/prompts/tests/`, or `agents/specs/` content

If any of the above are missing, **do not create them** during a revamp.
Instead, stop and ask whether the repo should be re-onboarded via `_customize.md`.

## Safe-to-update framework areas
These are framework-owned and may be upgraded:
- Entry points: `agents/_*.md`
- Prompt templates: `agents/prompts/*.md` (excluding `agents/prompts/tests/`)
- Roles and skills: `agents/roles/`, `agents/skills/`
- Options packets: `agents/options/**`
- Framework docs: `OLAD_framework.md`, `quickstart.md`, `CHANGELOG.md`
- Adapter packs: `agents/options/openclaw/**` (if present)

Note on path migrations:
- Some framework upgrades may move files/folders (example: OpenClaw pack moved from
  `agents/openclaw/` to `agents/options/openclaw/`).
- If the live repo still has legacy paths, migrate them and update any doc links.

## Configuration preservation rules
- `agents/options/model_config.md`: preserve the **Active config** values; only
  add new presets/notes below or above without changing existing KEY=value lines.
- `agents/options/workflow_config.md`: preserve existing `## KEY=value` lines;
  if new keys are required, add them as **commented defaults** only.

## Procedure (minimal, safe)
1) **Inventory current state**
   - Confirm the incoming snapshot exists (`olad-framework/agents/`, `olad-framework/OLAD_framework.md`, etc.).
   - List framework files that will change.
   - Identify any user-modified framework files (treat as merge conflicts).
2) **Plan the upgrade**
   - Prefer small, reviewable updates.
   - Avoid renames unless absolutely required.
3) **Update framework entrypoints**
   - Apply only generic improvements.
   - Keep prompts and status flags consistent.
4) **Update prompts, roles, skills**
   - Add new skills/roles without deleting custom ones.
   - Update templates and indexes carefully.
5) **Update options packets**
   - Add new optional features as opt-in packets.
   - Do not change any installed choices by default.
6) **Update docs**
   - Ensure docs reference the correct files.
   - Keep language generic and pre-customization.
7) **Preserve config values**
   - Verify `model_config.md` Active config is unchanged.
   - Verify `workflow_config.md` values are unchanged.
8) **Sanity check**
   - Confirm none of the “Files to preserve” were modified.
   - Spot-check that entrypoints still point to valid files.

## If conflicts appear
- Do not overwrite user edits silently.
- Flag the conflict and propose the smallest, safest resolution.
- Ask before applying any structural changes.

## Definition of Done
- Framework files upgraded without touching repo-specific artifacts.
- No changes to task/history files.
- Config values preserved; only new defaults added as comments.
- Docs remain generic and pre-customization.
