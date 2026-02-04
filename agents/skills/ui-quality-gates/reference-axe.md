# Reference: axe-core (distilled)

Source pin: frontend-packet/axe-core-develop/README.md, doc/API.md, doc/issue_impact.md, doc/rule-descriptions.md (local copy, 2025-01-29)

## What axe-core reports
- Results object includes: passes, violations, incomplete (needs review), inapplicable.
- Violations include rule id, help text, help URL, impact, and nodes.
- Incomplete items require manual review and should not be treated as pass.

## Tags you should use (standards + categories)
Every violation has a `tags` array. You can (and should) use tags to make runs and reports deterministic:
- **Standard tags** (pick the standard you care about): `wcag2a`, `wcag2aa`, `wcag21a`, `wcag21aa`, `wcag22a`, `wcag22aa`, `wcag2aaa`.
- **Rule categories** (group results): `cat.aria`, `cat.color`, `cat.forms`, `cat.keyboard`, `cat.language`, `cat.name-role-value`, `cat.parsing`, `cat.semantics`, `cat.structure`, `cat.tables`, `cat.text-alternatives`, `cat.time-and-media`, `cat.sensory-and-visual-cues`, `cat.navigation`.
- **Other common tags** you may see: `best-practice`, `experimental`, and regulatory mappings like `section508`.

Practical grouping rule:
- Treat any tag starting with `cat.` as the primary grouping key for reports.
- Treat any tag starting with `wcag` as the compliance standard key.

## runOnly: how to run against a specific standard
Use `runOnly` so the scan is about a specific standard instead of "whatever axe runs by default".

Common patterns:
```js
// WCAG 2.0 Level A
axe.run({ runOnly: { type: 'tag', values: ['wcag2a'] } })

// WCAG 2.0 Level A + AA
axe.run({ runOnly: { type: 'tag', values: ['wcag2a', 'wcag2aa'] } })

// Equivalent shorthand (tags array or single string)
axe.run({ runOnly: ['wcag2a', 'wcag2aa'] })
axe.run({ runOnly: 'wcag2a' })
```

Rule-level targeting (rare, but sometimes useful for debugging):
```js
axe.run({ runOnly: { type: 'rule', values: ['color-contrast', 'label'] } })
```

## Impact levels (from issue_impact.md)
- Minor: nuisance/annoyance; fix if small effort but still affects compliance.
- Moderate: causes some difficulty; prioritize after higher issues.
- Serious: serious barriers; blocks essential workflows for some users.
- Critical: blocks access to fundamental content; top priority.

## Practical notes
- Axe finds a substantial portion of WCAG issues but does not replace manual review.
- Rule list (including tags and categories) is in doc/rule-descriptions.md.
- There is limited support for JSDOM; some rules (notably `color-contrast`) are known not to work in JSDOM. Prefer running in a real browser harness for gating.
