# Examples (Codebase Safe Cleanup — Strict)

Append new examples to the bottom. Keep them repo-exact and reproducible.

## Example 1 — Refactor allowed (tests exist)
User: “Simplify the parser module; it’s a mess.”
Assistant:
1) Finds `make test` + `make lint` in README/Makefile
2) Runs baseline (passes)
3) Batch 1: Extract `parse_tokens()` helper, reduce nesting, remove unused branches
4) Runs verification (passes)
5) Batch 2: Deduplicate error mapping, keep same error codes/messages
6) Runs verification (passes)
7) Updates docstring + adds short note in README

Key: every batch is gated by passing verification.

## Example 2 — Refactor refused (no verification)
User: “Clean up these scripts and shorten functions.”
Assistant:
1) Searches for test/build commands (none found; README missing)
2) STRICT MODE: does **not** edit code
3) Produces “Verification Bootstrapping Plan”:
   - minimal run command
   - minimal smoke test (how to execute main entrypoint)
   - recommended baseline checks (lint/typecheck)
4) Requests the user provide the intended run/test commands or CI job to mirror

## Example 3 — Dead code removal with proof
User: “Remove the legacy v1 API code.”
Assistant:
- Confirms routing no longer references v1 paths (search + config)
- Confirms feature flag removed
- Removes dead modules
- Runs full tests/build
- Adds changelog note that v1 endpoints were already unreachable (evidence links)

## Example 4 — Security surface hardening without semantics change
User: “I’m worried about path traversal.”
Assistant:
- Locates file download handler
- Adds normalization + allowlist checks that match existing docs/tests
- Adds regression test if tests already exist and user allows (otherwise: documents risk + stops)
- Runs verification; only ships if passing

## Trigger phrases
- “clean up this repo”
- “refactor for readability”
- “reduce complexity”
- “remove dead code”
- “dedupe this logic”
- “harden scripts / make it safer”
