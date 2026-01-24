# Skills Layer (Agents)

This folder contains small, reusable playbooks ("skills") that any role can apply.
Skills are optional and auto-discovered by the Builder/QA prompts via
`agents/skills/skills_index.md`.

## How to Add a New Skill

1) Create a new folder: `agents/skills/<kebab-case-skill-name>/`
2) Copy `_skill_template.md` → `<skill-name>/SKILL.md`
3) Copy `_examples_template.md` → `<skill-name>/EXAMPLES.md`
4) Fill out `SKILL.md` (keep it short and procedural)
5) Add entry to `agents/skills/skills_index.md`

## Skill Structure (Context-Efficient Design)

### SKILL.md (Always Loaded)
- **Purpose**: Procedural checklist, triggers, DONE criteria
- **Size**: ~1 page max (~500 lines)
- **Content**: What to do, when to use it, how to validate
- **Examples**: Brief 1-2 sentence summaries with line references to EXAMPLES.md

### EXAMPLES.md (Loaded Only When Symptoms Match)
- **Purpose**: Detailed real-world fixes with searchable metadata
- **Content**: Full problem → root cause → fix → prevention
- **Metadata**: Tags and trigger phrases for grep-based discovery
- **Loading**: Agents search this file only when they encounter matching symptoms

**Why this split?**
- Reduces context bloat: SKILL.md is always cheap to load
- Smart loading: EXAMPLES.md loaded only when relevant symptoms appear
- Prevents repeated failures without polluting core skill procedures

## How to Add Examples (CRITICAL: Append Only!)

**Adding an example to an existing skill:**

1. **Open the skill's EXAMPLES.md file**
2. **Scroll to the END of the file** (after all existing examples)
3. **Append your new example** using this structure:

```markdown
## Example N: [Short title]

**Tags**: `retrieval`, `tests`, `regression`

**Trigger phrases**:
- "precision@k dropped"
- "citations missing after reranker"

**Date**: 2025-12-28

**Problem**: What went wrong...

**Impact**: Who was affected...

**Root cause**: The actual bug...

**Fix**: Exact steps taken...

**Prevention**: What to add to SKILL.md...

**References**: Files, commands, commits...
```

4. **Note the line numbers** where your example starts and ends (e.g., lines 142-178)
5. **Open the skill's SKILL.md file**
6. **Scroll to "Example References" section**
7. **Add a concise summary** with the line reference:

```markdown
3. **Citations missing after reranker** - Reranker was dropping citation metadata. See EXAMPLES.md:142-178
```

**⚠️ WARNING: NEVER insert examples in the middle of EXAMPLES.md!**

Inserting examples breaks all existing line number references in SKILL.md.
Always append to the END to keep references accurate.

## Guidelines

- Keep skills narrowly scoped and under ~1 page
- Use concrete triggers and verifiable DONE checks
- Avoid duplicate skills that overlap with role definitions
- Keep `SKILL.md` lean; add detailed, recurring examples to `EXAMPLES.md`
- Tag examples thoroughly (enables smart grep-based loading)
- Write specific trigger phrases (exact error messages, symptoms)

## Example Workflow (Agent Perspective)

```
1. Agent reads task
2. Agent loads relevant SKILL.md (from skills_index.md)
3. Agent follows procedural checklist
4. If agent encounters error matching trigger phrase:
   → Grep EXAMPLES.md for trigger phrase
   → Load only the matching example(s)
   → Apply the fix
   → Update prevention steps in SKILL.md if needed
```

This keeps context usage minimal while maintaining institutional knowledge.
