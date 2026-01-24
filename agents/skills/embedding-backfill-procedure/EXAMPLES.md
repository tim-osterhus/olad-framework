# Examples - Embedding/Backfill Procedure

This file stores detailed, real-world examples for the embedding-backfill-procedure skill.

---

## Example 1: Tenant re-embedding after chunk size change

**Tags**: `embedding`, `backfill`, `tenant`, `chunk-size`

**Trigger phrases**:
- "changed MAX_CHUNK_SIZE"
- "re-embed tenant docs"
- "backfill tenant"
- "chunk size backfill"

**Date**: 2025-12-28

**Problem**:
Changed MAX_CHUNK_SIZE from 256 to 512. Existing tenant documents still embedded with old chunk size.

**Impact**:
New uploads used 512-token chunks, old documents used 256-token chunks. Inconsistent retrieval behavior.

**Root cause**:
Embedding parameters changed but existing embeddings not updated.

**Fix**:
1. Backed up tenant collection:
   ```bash
   pg_dump -t tenant_demo_chunks > backups/tenant_demo_before_backfill.sql
   ```
2. Ran backfill script with recorded settings:
   ```bash
   python scripts/backfill_embeddings.py \
     --tenant demo \
     --max-chunk 512 \
     --overlap 50 \
     --model nomic-embed-text-v1.5 \
     --batch-size 32
   ```
3. Monitored progress (script logs):
   - 1,234 documents processed
   - 3,456 chunks created (was 5,678 with size=256)
   - Duration: 18 minutes
4. Verified counts:
   ```sql
   SELECT COUNT(*) FROM tenant_demo_chunks WHERE chunk_size = 512;
   -- Expected: 3,456
   ```
5. Ran spot-check queries:
   - `/query` with "testator signature"
   - Verified citations reference 512-token chunks
   - Before: avg 3.2 chunks/answer, After: avg 1.8 chunks/answer

**Prevention**:
Updated SKILL.md to require:
- "Backup collection before backfill"
- "Record exact parameters used (chunk size, overlap, model, batch size)"
- "Monitor progress and duration"
- "Verify counts + spot-check queries after"

**References**:
- `scripts/backfill_embeddings.py`
- `backups/tenant_demo_before_backfill.sql`
- Backfill log: `logs/backfill_tenant_demo_2025-12-28.log`
- Commit: jkl7890

---

## Example 2: Global corpus missing citations after DB restore

**Tags**: `embedding`, `backfill`, `global-corpus`, `citations`, `disaster-recovery`

**Trigger phrases**:
- "missing citations"
- "DB restore"
- "global corpus backfill"
- "citations not rendering"

**Date**: 2025-12-28

**Problem**:
After database restore from backup, queries returned results but citations weren't rendering in LibreChat.

**Impact**:
Users saw answers without sources. Attorney couldn't verify claims. Non-compliant with legal requirements.

**Root cause**:
DB backup didn't include embeddings table (was excluded to reduce backup size). Chunks existed but no vectors.

**Fix**:
1. Verified missing embeddings:
   ```sql
   SELECT COUNT(*) FROM global_law_chunks WHERE embedding IS NULL;
   -- Result: 45,678 (should be 0)
   ```
2. Ran backfill on global corpus:
   ```bash
   python scripts/backfill_embeddings.py \
     --corpus global_law \
     --max-chunk 512 \
     --model nomic-embed-text-v1.5 \
     --batch-size 64 \
     --resume-from-checkpoint  # In case of interruption
   ```
3. Monitored (long-running):
   - 45,678 chunks to embed
   - Duration: 2.5 hours
   - Checkpoint saved every 5,000 chunks
4. Ran 3 statute queries to confirm citations:
   - "524.2-502" (probate code)
   - "518.54" (divorce)
   - "145C.01" (health care directive)
   - All returned citations with proper rendering
5. Verified embedding coverage:
   ```sql
   SELECT COUNT(*) FROM global_law_chunks WHERE embedding IS NOT NULL;
   -- Result: 45,678 (100% coverage)
   ```

**Prevention**:
Updated SKILL.md to require:
- "Check for NULL embeddings after DB restore"
- "Use --resume-from-checkpoint for large backfills"
- "Run statute queries to confirm citations render"
- "Include embeddings table in backups (or document exclusion + backfill procedure)"

**References**:
- `scripts/backfill_embeddings.py`
- Backfill log: `logs/backfill_global_law_2025-12-28.log`
- SQL verification: `scripts/verify_embeddings.sql`
- Commit: mno1234

---

<!--
Add new examples below this line.
DO NOT insert examples above existing ones (breaks line number references in SKILL.md).
-->
