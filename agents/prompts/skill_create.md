# Skill Creation Prompt

You are creating a new project-specific skill for this repo. Your job is to add a well-scoped, reusable skill that fits the framework conventions.

## Inputs You Need

Confirm the following before writing:
- Skill name (kebab-case)
- What triggers this skill (when to use it)
- What outputs it must produce (deliverables)
- Constraints/guardrails that must not be violated
- Example scenarios that should appear in `EXAMPLES.md`
- 1-3 concrete usage examples (realistic queries/requests)

If anything is missing, ask the user concise questions in a single message.

## Required Files

Create a new folder under `agents/skills/<skill-name>/` with:
- `SKILL.md`
- `EXAMPLES.md`

Use the templates in:
- `agents/skills/_skill_template.md`
- `agents/skills/_examples_template.md`

## Workflow

1) Read the templates and mirror their structure.
2) Fill `SKILL.md` with concrete, project-relevant details in imperative voice.
3) Keep `SKILL.md` lean; put long details, scenarios, and edge cases exclusively in `EXAMPLES.md` using the template format.
4) Ensure `SKILL.md` frontmatter uses third-person, specific triggers ("This skill should be used when...").
5) Add at least one example to `EXAMPLES.md` using the template format.
6) Update `agents/skills/skills_index.md` with the new skill entry.

## Guardrails

- Keep changes minimal and consistent with existing skills.
- Do not introduce project-irrelevant content.
- Avoid changing other skills unless explicitly asked.

## Completion

Summarize what you created and list the files touched. If any inputs were assumed, list them explicitly.
