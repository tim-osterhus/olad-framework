---
name: librechat-customization-workflow-submodule-safe
description: >
  Applies and maintains LibreChat UI changes using an existing git submodule workflow without
  contaminating the parent repo history or breaking production builds.
---

# LibreChat Customization Workflow (Submodule-safe)

## Quick start
Goal:
- Make a targeted LibreChat change that remains updatable via submodule pulls and reproducible for production builds.

Use when (triggers):
- Changing LibreChat UI components, tool visibility, or provider configuration
- Updating LibreChat upstream while retaining a local customization branch
- Fixing UI integration with a backend API (endpoints, citations, doc viewer)

Do NOT use when (non-goals):
- Editing generated build artifacts or vendored node_modules
- Forking LibreChat into a non-submodule directory

## Operating constraints
- No secrets: never embed API keys, tokens, passwords, private URLs.
- Be minimal: smallest diffs; no drive-by refactors unless required.
- Be explicit: state assumptions and verify them where possible.
- Be deterministic: prefer exact commands/checklists over vague guidance.
- Keep SKILL.md short: if you exceed ~500 lines, split details into linked files.

## Inputs this Skill expects
Required:
- LibreChat submodule present at `librechat/LibreChat` on a customization branch
- Relevant docs (if any) and current `librechat/librechat.yaml`

Optional:
- Specific UI file path under `librechat/LibreChat/client/src/` to edit
- Screenshots of the current broken UI state

If required inputs are missing:
- Ask for the MINIMUM missing info OR proceed with safest defaults and list assumptions.

## Output contract
Primary deliverable:
- A minimal commit in the LibreChat submodule + parent repo pointer update, with build/run verification.

Secondary deliverables (only if needed):
- Optional: doc update if workflow changes
- Optional: historylog entry at the top of `agents/historylog.md` (newest first) including the exact git submodule commands used

Definition of DONE (objective checks):
- [ ] Submodule is clean (no uncommitted changes) and points to the intended commit
- [ ] LibreChat container builds successfully
- [ ] UI starts and key surfaces work (uploads, citations, settings)

## Procedure (copy into working response and tick off)
Progress:
- [ ] 1) Confirm scope + constraints
- [ ] 2) Locate entrypoints + relevant files
- [ ] 3) Plan smallest safe change set
- [ ] 4) Implement changes
- [ ] 5) Validate locally
- [ ] 6) Summarize changes + next steps

### 1) Confirm scope + constraints
- Restate objective in ONE sentence.
- List constraints (security, offline/LAN-only, no new deps, etc.).
- List assumptions explicitly.

### 2) Locate entrypoints + relevant files
Run targeted searches:
- Search terms:
  - git submodule
  - librechat.yaml
  - client/src
  - docker compose librechat build
- Files to inspect first (prioritized):
   1) docs or runbook for LibreChat customization (if present)
   2) librechat/librechat.yaml
   3) librechat/LibreChat/.gitmodules
   4) infra/compose/docker-compose.librechat.yml

### 3) Plan smallest safe change set
Rules:
- Touch the minimum number of files.
- Prefer additive changes over rewrites.
- If multiple approaches exist, choose the simplest that satisfies DONE checks.
- If risk is medium/high, write a micro-plan artifact before coding (see “Verification pattern”).
- Never modify LibreChat code from the parent repo root; `cd librechat/LibreChat` first.
- Keep custom changes as a small patch stack (few commits) on the customization branch.
- When updating upstream: merge/rebase inside submodule, then run full UI smoke.

### 4) Implement changes
Implementation checklist:
- [ ] Follow repo conventions (naming, formatting, module boundaries).
- [ ] Add or adjust any needed configuration.
- [ ] Update tests where applicable.
- [ ] Update docs where user-facing behavior changes.
- [ ] If changing providers/tools, ensure restricted features remain disabled when required.

### 5) Validate locally (choose what exists in the repo)
Run validations in this order:
1) Fast static checks:
   - git submodule status
   - cd librechat/LibreChat && git status
2) Unit/targeted tests:
   - Run UI tests if they exist
3) Integration smoke test:
   - docker compose -f infra/compose/docker-compose.librechat.yml build librechat
   - docker compose -f infra/compose/docker-compose.librechat.yml up -d librechat
   - docker logs <librechat-container> -n 50

If validation fails:
- Do not guess. Inspect error output, fix, re-run until green.
- If blocked by missing deps or environment, document the exact missing item and minimal install/run step.

### 6) Summarize changes + next steps
Include:
- What changed (bullets)
- Why (bullets)
- How to verify (exact commands)
- Next steps (1–3 max)

## Pitfalls / gotchas (keep this brutally honest)
- Committing submodule changes in the parent repo accidentally → commits must be inside `librechat/LibreChat`.
- Upstream update breaks customizations → keep the patch stack small and re-run UI smoke after merges.
- Accidentally enabling web-search/plugins → re-check config/UI toggles after every update.

## Progressive disclosure (one level deep)
If this Skill needs detail, link it directly from HERE (avoid chains of references):
- Examples: ./EXAMPLES.md

## Verification pattern (recommended for medium/high risk)
Use this when changes touch infra, retrieval logic, licensing, or security:
1) Analyze
2) Write a machine-checkable plan artifact (e.g. report.md / changes.json)
3) Validate assumptions (paths, versions, config)
4) Execute changes
5) Verify DONE checks

## Example References (concise summaries only)

**How to reference examples:**
- Keep summaries SHORT (1-2 sentences max)
- Include line number reference to EXAMPLES.md
- Agents will load full examples only when symptoms match

**Example summaries:**

1. **Hide a UI feature** - Use config/flags or modify UI components, rebuild and verify. See EXAMPLES.md:7-56
2. **Update upstream while keeping custom features** - Fetch in submodule, merge carefully, test custom features. See EXAMPLES.md:59-117

**Note:** Full examples with tags and trigger phrases are in `./EXAMPLES.md`.
