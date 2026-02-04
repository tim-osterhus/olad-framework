# Reference: Nielsen Heuristics (distilled)

Source pin: frontend-packet/Heuristic-Evaluation-main/README.md (local copy, 2021-09-30)

## 10 usability heuristics
1) Visibility of system status
- Keep users informed about what is happening with timely feedback.
2) Match between system and real world
- Use user language and familiar concepts.
3) User control and freedom
- Provide clear exits and undo/back paths.
4) Consistency and standards
- Follow platform conventions and keep wording/actions consistent.
5) Error prevention
- Prevent errors or ask for confirmation before risky actions.
6) Recognition rather than recall
- Make options visible so users do not rely on memory.
7) Flexibility and efficiency of use
- Provide shortcuts and efficient paths for experienced users.
8) Aesthetic and minimalist design
- Remove irrelevant or rarely needed content.
9) Help users recognize, diagnose, recover from errors
- Provide clear, constructive error messages near the problem.
10) Help and documentation
- Provide searchable help or support when needed.

## Severity ratings used in the source
- 1: Cosmetic/polish issue; fix if time allows.
- 2: Minor usability issue; important but not crucial; users can usually work around it.
- 3: Major usability issue; high priority; users may be blocked or fail critical workflows.

## Severity calibration examples (from the worked evaluations in the source)
Use these to keep severity assignment consistent across reviews.

Severity 3 (major / priority):
- **Error messages do not indicate where the error is** (e.g., sign-up form shows an error but not which field is wrong). This impairs recovery and can block completion. (Heuristic #9)
- **Help options are missing or ineffective for high-need users** (e.g., no useful help content and support paths are unclear for a service-heavy site). (Heuristic #10)

Severity 2 (minor / important but not crucial):
- **UI gives weak feedback on interactivity** (e.g., hover/focus states missing on links/tabs so users question responsiveness). (Heuristic #1)
- **Search/query state is not preserved** (e.g., query cleared on navigation, no suggestions), increasing rework and confusion. (Heuristics #1 and #3)
- **Information is laid out in a way that feels overwhelming** (e.g., very long single-column link lists), increasing cognitive load. (Heuristic #8)

Severity 1 (cosmetic / low priority):
- **Microcopy changes that improve friendliness/clarity but do not change outcomes** (e.g., placeholder wording). (Heuristic #2)
- **Minor consistency improvements** that do not block key tasks (e.g., clarifying which items are “learn about” vs “apply”). (Heuristic #4)

## Heuristic-specific cues (quick checks)
1) Visibility of system status
- Look for: hover/focus feedback, progress indicators, "you are here" cues, and state retention (search/filter).
2) Match between system and the real world
- Look for: user language (not internal jargon), familiar concepts, and task-first labeling/microcopy.
3) User control and freedom
- Look for: clear back/exit paths, undo/cancel, non-destructive defaults, and persistence of user inputs.
4) Consistency and standards
- Look for: consistent terminology, predictable placement of actions, and standard UI patterns (forms, navigation).
5) Error prevention
- Look for: constraints/validation before submit, confirmation for destructive actions, and prevention of double-submits.
6) Recognition rather than recall
- Look for: visible options, breadcrumbs/progress indicators, visited states, and reduced reliance on memory.
7) Flexibility and efficiency of use
- Look for: shortcuts for frequent users (search, keyboard access, sensible defaults) without harming novice flow.
8) Aesthetic and minimalist design
- Look for: reduced clutter, clear hierarchy, chunking/progressive disclosure, and removal of non-essential content.
9) Help users recognize, diagnose, recover from errors
- Look for: inline errors near fields, actionable remediation text, and preservation of user input.
10) Help and documentation
- Look for: searchable help, FAQs, clear support path, and context-specific guidance.
