# Examples - LibreChat Customization Workflow (Submodule-Safe)

This file stores detailed, real-world examples for the librechat-customization-workflow-submodule-safe skill.

---

## Example 1: Hide Agent Marketplace and web search

**Tags**: `librechat`, `ui`, `feature-toggle`, `composer`

**Trigger phrases**:
- "hide Agent Marketplace"
- "disable web search"
- "remove UI features"
- "composer customization"

**Date**: 2025-12-28

**Problem**:
Air-gapped legal app shouldn't show "Agent Marketplace" or "Web Search" toggles (they require internet).

**Impact**:
UI showed features that don't work offline in production. Confusing to users, suggests internet dependency.

**Root cause**:
Default LibreChat UI includes features designed for online use.

**Fix**:
1. Located feature flags in `librechat/.env.librechat`:
   ```env
   SHOW_AGENT_MARKETPLACE=false
   WEB_SEARCH_ENABLED=false
   ```
2. Alternatively, modified UI component directly (inside submodule):
   - `librechat/client/src/components/Composer/Composer.tsx:234`
   - Commented out Agent Marketplace button
   - Commented out Web Search toggle
3. Rebuilt container:
   ```bash
   docker compose -f docker-compose.librechat.yml up -d --build
   ```
4. Verified in UI: Composer shows only "Attach Files" and "File Search"
5. Cleared browser cache to ensure UI updated

**Prevention**:
Updated SKILL.md to recommend:
- "Prefer env vars / feature flags over code changes"
- "If modifying code inside submodule, document exact component/line"
- "Always rebuild container after UI changes"
- "Clear browser cache to verify"

**References**:
- `librechat/.env.librechat:45-46`
- `librechat/client/src/components/Composer/Composer.tsx:234`
- Commit: bcd0123

---

## Example 2: Update LibreChat upstream while keeping context monitor

**Tags**: `librechat`, `submodule`, `upstream`, `merge`

**Trigger phrases**:
- "update LibreChat upstream"
- "merge upstream"
- "keep custom features"
- "submodule update"

**Date**: 2025-12-28

**Problem**:
LibreChat upstream released security fix (v0.7.2). Needed to update while keeping custom "context monitor" feature we added.

**Impact**:
Running old version with security vulnerability. But direct update would lose custom feature.

**Root cause**:
Custom feature developed on top of old upstream commit. Upstream changed significantly.

**Fix**:
1. Fetched upstream in submodule:
   ```bash
   cd librechat
   git fetch upstream
   git checkout main
   ```
2. Created merge branch:
   ```bash
   git checkout -b merge-v0.7.2-with-context-monitor
   git merge upstream/v0.7.2
   ```
3. Resolved conflicts:
   - Conflict in `client/src/components/Chat/ChatView.tsx` (context monitor component)
   - Kept our context monitor code, integrated with new upstream structure
   - Conflict in `package.json` (dependency versions)
   - Took upstream versions, verified context monitor still works
4. Rebuilt and tested:
   ```bash
   cd ..
   docker compose -f docker-compose.librechat.yml up -d --build
   ```
5. Validated context monitor still appears in UI
6. Validated security fix applied (checked changelog)

**Prevention**:
Updated SKILL.md to require:
- "Fetch upstream in submodule, don't pull in parent repo"
- "Create merge branch, don't merge directly to main"
- "Resolve conflicts carefully, test custom features after"
- "Rebuild container and validate UI"

**References**:
- `librechat/` (submodule at commit: def4567)
- `client/src/components/Chat/ChatView.tsx:89-123` (context monitor)
- Commit: ghi4567

---

<!--
Add new examples below this line.
DO NOT insert examples above existing ones (breaks line number references in SKILL.md).
-->
