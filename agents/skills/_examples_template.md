# Examples Template (EXAMPLES.md)

This file stores detailed, real-world examples for the skill. Each example includes:
- **Tags**: Searchable categories (e.g., retrieval, formatting, tests, deps, librechat)
- **Trigger phrase(s)**: Exact symptom text to grep for (enables context-aware loading)
- **Complete fix**: Problem → Root cause → Solution → Prevention

## How to Use This File

1. **Agents load SKILL.md always** (small, procedural, low context cost)
2. **Agents search EXAMPLES.md only when symptoms match** (grep trigger phrases)
3. **SKILL.md references examples by line number** (e.g., "See EXAMPLES.md:42-67")

## Adding New Examples

**CRITICAL: Always append new examples to the END of this file!**

This ensures line number references in SKILL.md remain accurate. Never insert examples in the middle.

---

## Example 1: [Short title of the issue]

**Tags**: `retrieval`, `tests`, `regression`

**Trigger phrases** (grep these to find this example):
- "precision@k dropped"
- "citations missing after reranker"
- "HyDE fallback not logging"

**Date**: YYYY-MM-DD

**Problem**:
Describe the issue concisely (2-3 sentences). Include the symptom the user/agent observed.

**Impact**:
What broke? Who's affected? How severe?

**Root cause**:
What was the actual underlying issue? Be specific (file, line, logic flaw).

**Fix**:
Exact steps taken to resolve it. Include:
- Files changed
- Code snippets (if helpful)
- Commands run
- Validation performed

**Prevention**:
What to add to SKILL.md to prevent this recurring:
- New checklist item
- New validation command
- New constraint to document

**References**:
- `path/to/file.py:123`
- `pytest tests/test_foo.py -k regression`
- PR #123, commit abc1234

---

## Example 2: [Another issue]

**Tags**: `infra`, `compose`, `networking`

**Trigger phrases**:
- "docker compose config failed"
- "service unreachable"
- "port already allocated"

**Date**: YYYY-MM-DD

**Problem**:
...

**Impact**:
...

**Root cause**:
...

**Fix**:
...

**Prevention**:
...

**References**:
...

---

<!--
Add new examples below this line.
DO NOT insert examples above existing ones (breaks line number references in SKILL.md).
-->
