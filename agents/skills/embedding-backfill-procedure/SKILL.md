---
name: embedding-backfill-procedure
description: >
  Regenerates missing or stale embeddings for a collection using the existing embedding pipeline and
  documents the operation for repeatability in constrained environments.
---

# Embedding/Backfill Procedure

## Quick start
Goal:
- Backfill embeddings safely, verify vector counts, and avoid corrupting tenant isolation.

Use when (triggers):
- Changing chunking params (size/overlap) or embedding model
- New corpus seeded or imported
- Vector table has missing rows or retrieval returns empty results

Do NOT use when (non-goals):
- Switching to a new embedding provider without explicit approval
- Rebuilding the entire DB schema unless required

## Operating constraints
- No secrets: never embed API keys, tokens, passwords, private URLs.
- Be minimal: smallest diffs; no drive-by refactors unless required.
- Be explicit: state assumptions and verify them where possible.
- Be deterministic: prefer exact commands/checklists over vague guidance.
- Keep SKILL.md short: if you exceed ~500 lines, split details into linked files.

## Inputs this Skill expects
Required:
- Target collection name (e.g., `global_corpus` or `tenant_<id>`)
- Current embedding model settings (env/config)

Optional:
- Batch size constraint (default 100)
- Maintenance window note (if this runs on limited hardware)

If required inputs are missing:
- Ask for the MINIMUM missing info OR proceed with safest defaults and list assumptions.

## Output contract
Primary deliverable:
- A completed backfill run + evidence (row counts / logs) that embeddings exist for the target collection.

Secondary deliverables (only if needed):
- Optional: historylog entry at the top of `agents/historylog.md` (newest first) with the exact command + settings used
- Optional: retrieval spot-check (3–5 queries) confirming citations appear

Definition of DONE (objective checks):
- [ ] Backfill command completes without errors
- [ ] Vector row count matches chunk count for the target collection (or discrepancy explained)
- [ ] A sample query returns citations for that collection

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
  - backfill_embeddings
  - document_embeddings
  - document_chunks
  - EMBED_MODEL
  - MAX_CHUNK_SIZE
- Files to inspect first (prioritized):
   1) Embedding config or env file
   2) Embedding service code/config
   3) DB schema for embeddings
   4) Any existing smoke checklist

### 3) Plan smallest safe change set
Rules:
- Touch the minimum number of files.
- Prefer additive changes over rewrites.
- If multiple approaches exist, choose the simplest that satisfies DONE checks.
- If risk is medium/high, write a micro-plan artifact before coding.
- If changing embedding model or chunking, backfill into a NEW collection name first (safety), then swap.
- Record model name + vector dimension to avoid mismatched vectors.

### 4) Implement changes
Implementation checklist:
- [ ] Follow repo conventions (naming, formatting, module boundaries).
- [ ] Add or adjust any needed configuration.
- [ ] Update tests where applicable.
- [ ] Update docs where user-facing behavior changes.
- [ ] Use the existing backfill entrypoint (do not create a new one).

### 5) Validate locally (choose what exists in the repo)
Run validations in this order:
1) Fast static checks:
   - Verify embedding service is reachable (repo-specific command)
2) Unit/targeted tests:
   - Run repo-native DB tests if available
3) Integration smoke test:
   - Start only required services
   - Run backfill command with batch size
   - Query DB for embedding counts

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
- Running backfill with the wrong collection → double-check the exact collection string before executing.
- Mismatched vector dimension after changing embedding model → verify schema expects the dimension.
- Long-running backfills on weak hardware → use smaller batch size and document runtime expectations.

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

1. **Tenant re-embedding after chunk size change** - Backup, backfill with recorded settings, verify counts and spot-check. See EXAMPLES.md:7-68
2. **Global corpus missing citations after DB restore** - Check for NULL embeddings, backfill with checkpoints, verify citations. See EXAMPLES.md:71-136

**Note:** Full examples with tags and trigger phrases are in `./EXAMPLES.md`.
