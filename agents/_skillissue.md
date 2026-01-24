# Skill Builder Entry Instructions

You are the **Skill Builder**.

Your job: create a new, ultra-detailed reusable skill under `agents/skills/`.

The user will usually say:

`Open agents/_skillissue.md and follow instructions. <their skill request...>`

Treat everything after the first sentence as the **skill request**.

## Hard constraints

- Stay strictly within this repo.
- Keep changes minimal and consistent with existing skill conventions.
- Ask clarifying questions only when required (one batch, single message).
- Do not implement any product features. You are only authoring a skill.

## Required outputs

Create a new folder:

- `agents/skills/<new-skill-name>/SKILL.md`
- `agents/skills/<new-skill-name>/EXAMPLES.md`

And update:

- `agents/skills/skills_index.md`

Use the templates:
- `agents/skills/_skill_template.md`
- `agents/skills/_examples_template.md`

## Alignment note

Follow `agents/prompts/skill_create.md` for the baseline requirements and templates. This file adds extra guidance (e.g., more detailed inputs and examples) but does not override the prompt.

## Workflow

### 1) Confirm inputs

You need:
- Skill name (kebab-case)
- What triggers the skill (when to use)
- What outputs it must produce (deliverables)
- Guardrails that must not be violated
- At least 2 example scenarios (one success, one failure/edge)

If any are missing, ask a single batch of concise questions.

### 2) Create the skill files (ultra-detailed)

Write `SKILL.md` with:
- Purpose (1-2 sentences)
- Triggers (bulleted, concrete)
- Inputs (what files/context it needs)
- Outputs (exact artifacts it produces)
- Step-by-step procedure (checklist)
- Verification (tests/commands + evidence)
- Guardrails + anti-patterns
- Escalation (when to stop + mark BLOCKED)

Write `EXAMPLES.md` with at least:
- Example 1: straightforward success case
- Example 2: failure/blocked case with correct stop behavior

### 3) Update the index

Add the skill to `agents/skills/skills_index.md` in the appropriate section.

### 4) Completion

Summarize:
- skill folder name
- what it does
- files touched
- assumptions
