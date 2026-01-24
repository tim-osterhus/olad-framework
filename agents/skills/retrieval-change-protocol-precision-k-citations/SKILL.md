---
name: retrieval-change-protocol-precision-k-citations
description: >
  Provides a strict protocol for modifying retrieval behavior (chunking, scoring, hybrid search, reranking) while preserving citation-backed answers and measuring precision@k on a fixed query set.
---

# Retrieval Change Protocol (precision@k + citations)

## Quick start
Goal:
- Change retrieval safely and prove it improved (or at least didn’t regress) precision@k and citation correctness.

Use when (triggers):
- Editing `rag_api/services/query.py` or retrieval pipeline files
- Changing `pgvector` indexes, `pg_trgm`, chunking, or reranker toggles
- Any change that affects citations shown to attorneys

Do NOT use when (non-goals):
- Pure UI/UX work not affecting retrieval
- Adding new ML tooling or external services

## Operating constraints
- No secrets: never embed API keys, tokens, passwords, private URLs.
- Be minimal: smallest diffs; no drive-by refactors unless required.
- Be explicit: state assumptions and verify them where possible.
- Be deterministic: prefer exact commands/checklists over vague guidance.
- Keep SKILL.md short: if you exceed ~500 lines, split details into linked files.

## Inputs this Skill expects
Required:
- Baseline query set (10–30 questions) with expected relevant sources (can be in a simple markdown list)
- Access to run the stack locally (docker) and run tests

Optional:
- Recent retrieval logs/audit entries (`audit_logs` table) for representative queries
- Prior retrieval report (if available)

If required inputs are missing:
- Ask for the MINIMUM missing info OR proceed with safest defaults and list assumptions.

## Output contract
Primary deliverable:
- Code changes to retrieval + a short retrieval report (markdown) documenting precision@k and citation checks before vs after.

Secondary deliverables (only if needed):
- Optional: update/extend `tests/test_rag_api.py` to lock in the retrieval behavior
- Optional: add an entry at the top of `agents/historylog.md` (newest first) pointing to the retrieval report

Definition of DONE (objective checks):
- [ ] Stack runs and `/query` returns citations for baseline queries (no empty-citation regressions)
- [ ] Precision@k computed on the fixed query set (k=5 recommended) with before/after
- [ ] Any changed knobs are documented (env vars / config) and have safe defaults

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
- List constraints (security, production offline/LAN-only, no new deps, etc.).
- List assumptions explicitly.

### 2) Locate entrypoints + relevant files
Run targeted searches:
- Search terms:
  - rag_api/services/query.py
  - pg_trgm
  - RERANK_ENABLED
  - MAX_CHUNK_SIZE
  - CHUNK_OVERLAP
  - citations
- Files to inspect first (prioritized):
   1) rag_api/services/query.py
   2) rag_api/config.py
   3) tests/test_rag_api.py
   4) infra/initdb/002_rag_schema.sql

### 3) Plan smallest safe change set
Rules:
- Touch the minimum number of files.
- Prefer additive changes over rewrites.
- If multiple approaches exist, choose the simplest that satisfies DONE checks.
- If risk is medium/high, write a micro-plan artifact before coding (see “Verification pattern”).
- Always write a micro-plan artifact FIRST: `docs/retrieval_reports/<date>_<slug>.md`.
- Define k, query set, and scoring changes before coding.
- Keep a rollback path: env toggle or small revertable patch.

### 4) Implement changes
Implementation checklist:
- [ ] Follow repo conventions (naming, formatting, module boundaries).
- [ ] Add or adjust any needed configuration.
- [ ] Update tests where applicable.
- [ ] Update docs where user-facing behavior changes.
- [ ] Preserve response schema and citation fields used by LibreChat integration.
- [ ] If adding lexical/hybrid, ensure it’s tenant-safe and respects `tenant_id` isolation.

### 5) Validate locally (choose what exists in the repo)
Run validations in this order:
1) Fast static checks:
   - docker compose -f infra/compose/docker-compose.pgvector.yml config >/dev/null
2) Unit/targeted tests:
   - pytest tests/test_database.py tests/test_rag_api.py -v
3) Integration smoke test:
   - docker compose -f infra/compose/docker-compose.pgvector.yml -f infra/compose/docker-compose.mongo.yml -f infra/compose/docker-compose.ollama.yml -f infra/compose/docker-compose.rag.yml -f infra/compose/docker-compose.librechat.yml up -d --build
   - curl -s http://localhost:8001/health || true
   - curl -s -X POST http://localhost:8001/query -H 'Content-Type: application/json' -d '{"query":"What is an elective share in Minnesota?","tenant_id":"tenant_firm_example","top_k":5}' | head -c 400

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
- Changing retrieval without a fixed evaluation set → you’ll fool yourself with anecdotal wins.
- Breaking citations by altering chunk IDs or schema fields → LibreChat will show empty/incorrect references.
- Uncontrolled regressions from “smart” heuristics → gate behind toggles and measure.

## Progressive disclosure (one level deep)
If this Skill needs detail, link it directly from HERE (avoid chains of references):
- Reference/specs: ./reference.md

## Verification pattern (recommended for medium/high risk)
Use this when changes touch infra, retrieval logic, licensing, or security:
1) Analyze
2) Write a machine-checkable plan artifact (e.g. report.md / changes.json)
3) Validate assumptions (paths, versions, config)
4) Execute changes
5) Verify DONE checks

## Optional: scripts section (ONLY if repo already uses scripts)
Run:
- bash scripts/test_chat_formats.sh

Expected output:
- No regression in chat message format tests

Common failures:
- LibreChat container not running → run full compose stack

## Example References (concise summaries only)

**How to reference examples:**
- Keep summaries SHORT (1-2 sentences max)
- Include line number reference to EXAMPLES.md
- Agents will load full examples only when symptoms match

**Example summaries:**

1. **pg_trgm hybrid search for statutes** - Add pg_trgm query with toggle, report precision@5 improvement. See EXAMPLES.md:7-40
2. **Chunk size increase and backfill** - Change defaults, backfill sample, spot-check 5 citations. See EXAMPLES.md:42-75

**Note:** Full examples with tags and trigger phrases are in `./EXAMPLES.md`.
Agents search that file only when they encounter matching symptoms (context-efficient).
