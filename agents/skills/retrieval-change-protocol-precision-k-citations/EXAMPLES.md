# Examples - Retrieval Change Protocol (Precision@k + Citations)

This file stores detailed, real-world examples for the retrieval-change-protocol-precision-k-citations skill.

---

## Example 1: pg_trgm hybrid search for statutes

**Tags**: `retrieval`, `hybrid`, `pg_trgm`, `precision`

**Trigger phrases**:
- "improve statute lookups"
- "hybrid search"
- "pg_trgm"
- "lexical + dense retrieval"

**Date**: 2025-12-28

**Problem**:
Statute lookups (e.g., "524.2-502") were failing with dense-only retrieval. Exact statute numbers weren't matching well with embeddings.

**Impact**:
Attorneys couldn't quickly find specific statutes, reducing app usefulness for legal research.

**Root cause**:
Dense embeddings don't capture exact alphanumeric patterns well. Statute numbers need lexical matching.

**Fix**:
1. Enabled pg_trgm extension: `psql -c "CREATE EXTENSION pg_trgm;"`
2. Added lexical search function in `rag_api/services/query.py`:
   - BM25-style scoring using pg_trgm similarity
   - Hybrid fusion: weighted merge of lexical + dense results
3. Added `HYBRID_ENABLED=false` env var (feature toggle)
4. Created 50-query evaluation set focused on statute lookups
5. Ran precision@5 report before/after:
   - Dense-only: 0.42 precision@5 on statute queries
   - Hybrid: 0.78 precision@5 on statute queries
6. Documented in `tests/retrieval_reports/hybrid_statute_lookup.md`

**Prevention**:
Updated SKILL.md to require:
- "Fixed evaluation set with statute/alphanumeric queries"
- "Precision@k report before/after on that set"
- "Feature toggle for rollback"

**References**:
- `rag_api/services/query.py:89-123`
- `tests/retrieval_reports/hybrid_statute_lookup.md`
- Commit: pqr4567

---

## Example 2: Chunk size increase and backfill

**Tags**: `chunking`, `embedding`, `backfill`, `citations`

**Trigger phrases**:
- "increase chunk size"
- "reduce fragmentation"
- "chunk size too small"
- "backfill embeddings"

**Date**: 2025-12-28

**Problem**:
Chunk size was 256 tokens, causing fragmentation. Long statute sections split across multiple chunks, breaking context.

**Impact**:
Citations were fragmented. Answers referenced multiple chunks from same statute instead of one coherent chunk.

**Root cause**:
MAX_CHUNK_SIZE=256 was too conservative. Statutes often 400-600 tokens.

**Fix**:
1. Changed `rag_api/config.py`: MAX_CHUNK_SIZE = 512
2. Ran backfill on sample tenant collection (tenant_demo):
   ```bash
   python scripts/backfill_embeddings.py --tenant demo --max-chunk 512
   ```
3. Ran 5 test queries with citation spot-check:
   - "testator signature requirements"
   - "revocation of will by divorce"
   - "intestate succession spouse"
   - "probate notice to creditors"
   - "guardianship emergency"
4. Verified citations referenced fewer, longer chunks
5. Before: avg 3.2 chunks per answer, After: avg 1.8 chunks per answer
6. Documented in `tests/retrieval_reports/chunk_size_512.md`

**Prevention**:
Updated SKILL.md to require:
- "Backfill sample collection first, not full corpus"
- "Citation spot-check for 5 representative queries"
- "Document before/after chunk fragmentation metrics"

**References**:
- `rag_api/config.py:34`
- `scripts/backfill_embeddings.py`
- `tests/retrieval_reports/chunk_size_512.md`
- Commit: stu8901

---

<!--
Add new examples below this line.
DO NOT insert examples above existing ones (breaks line number references in SKILL.md).
-->
