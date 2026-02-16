# Spark-Routing Option (Complexity-Aware Local Loop)

This option is intended to be used by `agents/_customize.md`.

Goal: optionally enable Spark-first routing for `TRIVIAL`/`BASIC` tasks in the
local foreground runner (`agents/orchestrate_loop.sh`) while preserving fallback
to standard Codex models when Spark usage caps are reached.

## What this option changes

- Uses task metadata in `agents/tasks.md`:
  - `**Complexity:** TRIVIAL|BASIC|MODERATE|INVOLVED|HEAVY`
  - `**Assigned skills:** skill-a, skill-b` (required for TRIVIAL/BASIC)
- Routes small Builder runs to `agents/_ministart.md`.
- Uses model chains from `agents/options/model_config.md` for small tasks.
- Persists Spark exhaustion cooldown markers in `agents/options/workflow_config.md`.

## Workflow flags

Set in `agents/options/workflow_config.md`:
- `## COMPLEXITY_ROUTING=On`
- `## SPARK_COOLDOWN_MINUTES=<N>`
- `## CODEX_SPARK_EXHAUSTED_AT=` (runtime-managed; leave empty at install)

To disable:
- `## COMPLEXITY_ROUTING=Off`

## Model config keys

Configure in `agents/options/model_config.md` (Active config block):
- `SMALL_BUILDER_MODEL_CHAIN`
- `SMALL_HOTFIX_MODEL_CHAIN`
- `MODERATE_BUILDER_MODEL_CHAIN`
- `MODERATE_HOTFIX_MODEL_CHAIN`
- `LARGE_BUILDER_MODEL_CHAIN`
- `LARGE_HOTFIX_MODEL_CHAIN`
- `QA_SMALL_MODEL`, `QA_SMALL_EFFORT`
- `QA_MODERATE_MODEL`, `QA_MODERATE_EFFORT`
- `QA_LARGE_MODEL`, `QA_LARGE_EFFORT`
- `DOUBLECHECK_SMALL_MODEL`, `DOUBLECHECK_SMALL_EFFORT`
- `DOUBLECHECK_MODERATE_MODEL`, `DOUBLECHECK_MODERATE_EFFORT`
- `DOUBLECHECK_LARGE_MODEL`, `DOUBLECHECK_LARGE_EFFORT`

Recommended Spark-first overrides (optional):
- `SMALL_BUILDER_MODEL_CHAIN=gpt-5.3-codex-spark|gpt-5.3-codex`
- `SMALL_HOTFIX_MODEL_CHAIN=gpt-5.3-codex-spark|gpt-5.3-codex`

If you leave these unchanged, small-task routes stay on standard codex.

## Task-card requirements

For `TRIVIAL` and `BASIC` cards:
- Provide exactly two assigned skills.
- Keep card scope narrow enough for one short cycle.

If small-task metadata is missing/invalid, the loop auto-upscopes the card to `MODERATE`.

## Troubleshooter behavior

With Spark-routing enabled:
- `_troubleshoot.md` is used only for `MODERATE`/`INVOLVED`/`HEAVY`.
- `TRIVIAL`/`BASIC` non-usage blockers auto-upscope to `MODERATE` instead.

## Validation checklist

- `bash -n agents/orchestrate_loop.sh`
- Confirm `agents/_ministart.md` exists.
- Confirm a sample `TRIVIAL` card routes Builder to `_ministart.md`.
- Confirm Spark-cap simulation falls back to next model in chain.
