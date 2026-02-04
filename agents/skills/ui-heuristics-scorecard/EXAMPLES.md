# Examples (UI Heuristics Scorecard)

Append new examples to the END of this file and never change existing Example IDs.

---

## EX-2026-02-03-01: Worked heuristic evaluation (NY DMV website)

**Tags**: `heuristics`, `severity-calibration`, `navigation`, `errors`

**Trigger phrases**:
- "heuristic evaluation"
- "usability scorecard"
- "Nielsen review"
- "go back button"
- "error message not indicating field"

**Date**: 2026-02-03

**Problem**:
A team needed a heuristic evaluation for a high-stakes, info-dense government website flow (based on the worked evaluation in `frontend-packet/Heuristic-Evaluation-main/README.md`).

**Impact**:
Users struggled with navigation, feedback, and error recovery, increasing abandonment and support burden.

**Cause**:
Multiple usability breakdowns across feedback, control, and error recovery created friction, especially for less experienced users.

**Fix**:
- Scored issues against the 10 heuristics with severity 1-3.
- Used these calibrated mappings (paraphrased from the source evaluation) to keep severity deterministic:
  - Heuristic #1 (Visibility): lack of hover/interaction feedback on tabs/links and search UX issues (query not preserved / weak feedback) → **Severity 2**.
  - Heuristic #2 (Match): microcopy friendliness improvements → **Severity 1**.
  - Heuristic #3 (Control/Freedom): no in-product “go back” path and loss of search state → **Severity 1**.
  - Heuristic #6 (Recognition): multi-step guidance without a way to track progress (checkboxes / visited indicators) → **Severity 2**.
  - Heuristic #8 (Aesthetic/Minimal): long single-column layout increasing overwhelm → **Severity 2**.
  - Heuristic #9 (Error recovery): form error handling that does not identify the field with an error → **Severity 3**.
  - Heuristic #10 (Help/Docs): help/support paths ineffective for user needs → **Severity 3**.
- Wrote a structured report mapping each issue to its heuristic and severity, with evidence references.

**Prevention**:
- Maintain a small, stable “severity calibration” section in the skill reference and reuse it across audits.
- Treat severity-3 findings as requiring explicit owner sign-off (they usually imply redesign or workflow changes).

**References**:
- `ui_heuristics.md`
- `ui_heuristics.json`

---

## EX-2026-02-03-02: Blocked due to severity-3 redesign decision

**Tags**: `heuristics`, `blocked`, `severity-3`, `decision-needed`

**Trigger phrases**:
- "severity 3"
- "needs redesign decision"
- "error handling redesign"

**Date**: 2026-02-03

**Problem**:
The heuristic evaluation surfaced a severity-3 issue in error recovery (users cannot reliably identify and fix input errors), but the remediation required a UX/design decision that the agent could not make unilaterally.

**Impact**:
Without a decision, any “fix” would risk UX regression (or conflict with existing UI patterns and accessibility constraints).

**Cause**:
The problem was not ambiguity in findings; it was ambiguity in the acceptable remediation approach and scope.

**Fix**:
- Marked the task BLOCKED.
- Presented 2-3 remediation options with tradeoffs (e.g., inline field errors + summary banner vs. summary-only).
- Requested owner/design sign-off on which remediation pattern to implement and what “DONE” looks like.

**Prevention**:
- Predefine approved error-handling patterns and severity-3 escalation rules before running audits.

**References**:
- `ui_heuristics.md` (blocked status)

<!--
Add new examples below this line.
-->
