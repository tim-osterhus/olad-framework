# Examples (Codebase Audit + Documentation)

Append new examples to the end.

---

## Example 1: Security + dependency audit with reproducible findings

**Tags**: `security`, `dependencies`, `reporting`

**Trigger phrases**:
- "check for security vulnerabilities"
- "audit this repo"
- "are there any obvious security issues"

**Date**: 2025-12-28

**Scenario**:
User hands over a repo and wants a practical security audit (not a theoretical essay).

**Inputs to request / discover**:
- How to run tests + linters (or confirm none exist)
- Runtime context (local-only tool, internet-facing API, internal service)
- Any secrets policy (are .env files expected?)

**Expected outputs**:
- A short "How to reproduce" section (commands + expected output)
- Findings grouped by severity with exact file/line pointers
- A dependency risk summary (direct deps + known vulnerable versions if detected)
- A doc-only patch list (where docstrings/comments are missing or misleading)

**Common pitfalls**:
- Reporting "possible" issues without evidence
- Suggesting fixes that require architecture changes without stating scope/risk

**Prevention**:
- Only mark as a finding when you can point to concrete code/config
- Separate "confirmed findings" vs "suspicious patterns to investigate"

**References**:
- SKILL.md: "Audit report format"
- SKILL.md: "Security triage rules"

---

## Example 2: Documentation coverage pass without changing behavior

**Tags**: `documentation`, `api`, `safety`

**Trigger phrases**:
- "document this codebase"
- "add docstrings and comments"
- "make it easier to onboard engineers"

**Date**: 2025-12-28

**Scenario**:
Repo works, but is hard to understand. User wants better docs without refactoring.

**Expected outputs**:
- A prioritized list of modules/files to document first (entrypoints and public APIs)
- Consistent docstring style and minimal "why" comments at tricky spots
- A short "Developer quickstart" snippet if one is missing or incorrect

**Guardrails**:
- Only doc-only changes (docstrings/comments/types that do not affect runtime)
- No moving code, no renaming exports, no changing logic

**Verification**:
- Run the repo's test command (or at least import/compile step) after doc edits
- Ensure formatting/linting still passes (or note what exists)

**References**:
- SKILL.md: "Doc coverage checklist"

---

## Example 3: Complexity hotspot map for a mixed-language monorepo

**Tags**: `analysis`, `complexity`, `prioritization`

**Trigger phrases**:
- "where is the tech debt"
- "what should we clean up first"
- "functions are too long"

**Date**: 2025-12-28

**Scenario**:
Monorepo with multiple services. User wants the fastest path to risk reduction.

**Expected outputs**:
- A "hotspot table" (top files by churn if git history exists; otherwise by size + centrality)
- A shortlist of candidate refactors (but do NOT perform them in this skill)
- A callout list of dangerous areas (auth, payments, deserialization, file IO, shell-outs)

**Notes**:
- If git history is present: use it to identify high-churn + bug-prone areas.
- If not: fall back to static heuristics (LOC, nesting depth, number of dependencies).

**References**:
- SKILL.md: "Hotspot identification"

---

## Example 4: Hardening documentation for deployment + configuration

**Tags**: `configuration`, `ops`, `security`

**Trigger phrases**:
- "how do I deploy this"
- "what env vars does this need"
- "we keep misconfiguring it"

**Date**: 2025-12-28

**Scenario**:
Incidents are caused by unclear config (CORS, auth keys, debug flags, ports).

**Expected outputs**:
- A single source of truth for required configuration (docs near the config schema)
- Explicit defaults + safe recommended values
- A "misconfig traps" section (what breaks / what becomes unsafe)

**Guardrails**:
- Do not change runtime defaults unless explicitly asked (that belongs in the cleanup/refactor skill)
- If a default is unsafe, document it as unsafe and propose a follow-up task

**References**:
- SKILL.md: "Config audit checklist"
