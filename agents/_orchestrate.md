# Runner Entry Instructions

You are the **Orchestrator/Runner**.

## Hard constraints

**These are shell templates. Always run them from the repo root.**

### 1) You do *not* do Builder or QA work yourself
You orchestrate by spawning headless runs of Builder/QA agents and by moving task cards between the task files.

### 2) The ONLY prompts you may send to sub-agents
When you invoke a sub-agent, the prompt payload must be **exactly** one of the following strings (no prefixes, suffixes, extra notes, or formatting):

```
Open agents/_integrate.md and follow instructions.
Open agents/_start.md and follow instructions.
Open agents/_check.md and follow instructions.
Open agents/_hotfix.md and follow instructions.
Open agents/_doublecheck.md and follow instructions.
```

These are the only sub-agent prompts you are allowed to emit.

---

## Repo assumptions

You must run from the repo root that contains:

- `agents/_start.md`
- `agents/_check.md`
- `agents/_hotfix.md`
- `agents/_doublecheck.md`
- `agents/_integrate.md`

And the task files (default paths):

- `agents/tasks.md`
- `agents/tasksbacklog.md`
- `agents/tasksarchive.md`
- `agents/historylog.md`
- `agents/quickfix.md` (work artifact created only when a quickfix is needed; delete it when resolved)

Optional (recommended) coordination file:

- `agents/status.md` (a single-line or small file used as a reliable “state flag”)

If any of these are missing, create only what is necessary to proceed (prefer not to invent new files).

---

## State & signaling contract (what you wait for)

Use `agents/status.md` as the sole signaling file. Do not scan `agents/historylog.md` for flags.

The downstream prompt files (_integrate/_start/_check/_hotfix/_doublecheck) are expected to write one of these flags to `agents/status.md`:

- `### INTEGRATION_COMPLETE`
- `### BUILDER_COMPLETE`
- `### QA_COMPLETE`
- `### QUICKFIX_NEEDED`
- `### BLOCKED`

Rules:
- You should treat the **latest** matching flag as authoritative.
- After you observe and act on a flag, clear it by overwriting `agents/status.md` with `### IDLE`.

---

## Configuration knobs (defaults)

- **Cycle timeout:** 90 minutes per headless run
- **Poll interval:** 15 seconds when waiting for a flag
- **Quickfix attempts:** 2 total attempts per task (hotfix + doublecheck per attempt)

---

## Model config (single source of truth)

All per-cycle **runner** + **model** choices live in `agents/model_config.md`.

- To switch models or “all Codex / all Claude”, edit **only** `agents/model_config.md`.
- Do **not** edit this `_orchestrate.md` file to change models.

Required keys in `agents/model_config.md`:

- `INTEGRATION_RUNNER` / `INTEGRATION_MODEL`
- `BUILDER_RUNNER` / `BUILDER_MODEL`
- `QA_RUNNER` / `QA_MODEL`
- `HOTFIX_RUNNER` / `HOTFIX_MODEL`
- `DOUBLECHECK_RUNNER` / `DOUBLECHECK_MODEL`

**Important:** regardless of runner/model, the prompt text must stay **exactly** the allowed string.

---

## Workflow config (integration counters)

Use `agents/workflow_config.md` to store integration counters when periodic/alternating integration is enabled.
Read only the top flag block and update counters in **Finalize**.

Top flags (read/modify only here):
- `## INTEGRATION_COUNT=<int>`
- `## INTEGRATION_TARGET=<int>`

---

## How to run headless sub-agents

1) Edit `agents/model_config.md` (if you want something other than the defaults).
2) Use the templates below. They automatically respect your config.

## Command templates (copy/paste friendly)

These are templates. Adapt paths if your repo differs.

### Windows 10 PowerShell templates

**Create a run folder**

```powershell
$run = Get-Date -Format 'yyyy-MM-dd_HHmmss'
$runDir = "agents\\runs\\$run"
New-Item -ItemType Directory -Force -Path $runDir | Out-Null
```

**Load `agents/model_config.md` + helper (run once per session)**

```powershell
# Parse KEY=value lines from agents/model_config.md (ignores everything else)
$cfg = @{}
Get-Content "agents\\model_config.md" | ForEach-Object {
  if ($_ -match '^\s*([A-Z0-9_]+)\s*=\s*(.+?)\s*$') {
    $cfg[$matches[1]] = $matches[2].Trim()
  }
}

function Invoke-OladCycle {
  param(
    [Parameter(Mandatory=$true)][string]$Runner,   # codex|claude
    [Parameter(Mandatory=$true)][string]$Model,
    [Parameter(Mandatory=$true)][string]$Prompt,
    [Parameter(Mandatory=$true)][string]$StdoutPath,
    [Parameter(Mandatory=$true)][string]$StderrPath,
    [string]$LastMessagePath = "",
    [int]$TimeoutSeconds = 5400
  )

  if ($Runner -eq "codex") {
    $args = @("exec", "--model", $Model, "--full-auto")
    if ($LastMessagePath) { $args += @("-o", $LastMessagePath) }
    $args += @($Prompt)

    $proc = Start-Process -FilePath "codex" -ArgumentList $args -NoNewWindow -PassThru `
      -RedirectStandardOutput $StdoutPath -RedirectStandardError $StderrPath

    if (-not $proc.WaitForExit($TimeoutSeconds * 1000)) { $proc.Kill(); exit 124 }
    if ($proc.ExitCode -ne 0) { exit $proc.ExitCode }
    return
  }

  if ($Runner -eq "claude") {
    $args = @("-p", $Prompt, "--model", $Model, "--output-format", "text", "--dangerously-skip-permissions")

    $proc = Start-Process -FilePath "claude" -ArgumentList $args -NoNewWindow -PassThru `
      -RedirectStandardOutput $StdoutPath -RedirectStandardError $StderrPath

    if (-not $proc.WaitForExit($TimeoutSeconds * 1000)) { $proc.Kill(); exit 124 }
    if ($proc.ExitCode -ne 0) { exit $proc.ExitCode }

    # Claude doesn't have "-o"; best-effort mirror stdout into "last message" if requested.
    if ($LastMessagePath) { Copy-Item -Force $StdoutPath $LastMessagePath }
    return
  }

  throw "Unknown Runner='$Runner' (expected codex|claude). Check agents/model_config.md"
}
```

**Builder cycle (new task)**

```powershell
Invoke-OladCycle `
  -Runner $cfg["BUILDER_RUNNER"] `
  -Model  $cfg["BUILDER_MODEL"] `
  -Prompt "Open agents/_start.md and follow instructions." `
  -StdoutPath "$runDir\\builder.stdout.log" `
  -StderrPath "$runDir\\builder.stderr.log" `
  -LastMessagePath "$runDir\\builder.last.md"
```

**Integration cycle (run only if required by `agents/workflow_config.md`)**

```powershell
Invoke-OladCycle `
  -Runner $cfg["INTEGRATION_RUNNER"] `
  -Model  $cfg["INTEGRATION_MODEL"] `
  -Prompt "Open agents/_integrate.md and follow instructions." `
  -StdoutPath "$runDir\\integration.stdout.log" `
  -StderrPath "$runDir\\integration.stderr.log" `
  -LastMessagePath "$runDir\\integration.last.md"
```

**QA cycle (new task)**

```powershell
Invoke-OladCycle `
  -Runner $cfg["QA_RUNNER"] `
  -Model  $cfg["QA_MODEL"] `
  -Prompt "Open agents/_check.md and follow instructions." `
  -StdoutPath "$runDir\\qa.stdout.log" `
  -StderrPath "$runDir\\qa.stderr.log" `
  -LastMessagePath "$runDir\\qa.last.md"
```

**Hotfix cycle (only if QA says QUICKFIX_NEEDED)**

```powershell
Invoke-OladCycle `
  -Runner $cfg["HOTFIX_RUNNER"] `
  -Model  $cfg["HOTFIX_MODEL"] `
  -Prompt "Open agents/_hotfix.md and follow instructions." `
  -StdoutPath "$runDir\\hotfix.stdout.log" `
  -StderrPath "$runDir\\hotfix.stderr.log" `
  -LastMessagePath "$runDir\\hotfix.last.md"
```

**Doublecheck cycle (QA on quickfix)**

```powershell
Invoke-OladCycle `
  -Runner $cfg["DOUBLECHECK_RUNNER"] `
  -Model  $cfg["DOUBLECHECK_MODEL"] `
  -Prompt "Open agents/_doublecheck.md and follow instructions." `
  -StdoutPath "$runDir\\doublecheck.stdout.log" `
  -StderrPath "$runDir\\doublecheck.stderr.log" `
  -LastMessagePath "$runDir\\doublecheck.last.md"
```

### Bash / Git Bash / WSL templates

```bash
RUN_ID="$(date +%F_%H%M%S)"
RUN_DIR="agents/runs/$RUN_ID"
mkdir -p "$RUN_DIR"

# Parse KEY=value from agents/model_config.md (ignores everything else)
while IFS='=' read -r key value; do
  case "$key" in
    ''|\#*) continue ;;
    *)
      key="$(printf "%s" "$key" | tr -d '[:space:]')"
      value="$(printf "%s" "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
      [ -n "$key" ] && eval "${key}=\"${value}\""
      ;;
  esac
done < "agents/model_config.md"

run_cycle() {
  runner="$1"
  model="$2"
  prompt="$3"
  stdout_path="$4"
  stderr_path="$5"
  last_path="$6"

  if [ "$runner" = "codex" ]; then
    if [ -n "$last_path" ]; then
      codex exec --model "$model" --full-auto -o "$last_path" "$prompt" >"$stdout_path" 2>"$stderr_path"
    else
      codex exec --model "$model" --full-auto "$prompt" >"$stdout_path" 2>"$stderr_path"
    fi
    return
  fi

  if [ "$runner" = "claude" ]; then
    claude -p "$prompt" --model "$model" --output-format text --dangerously-skip-permissions >"$stdout_path" 2>"$stderr_path"
    if [ -n "$last_path" ]; then
      cp -f "$stdout_path" "$last_path"
    fi
    return
  fi

  echo "Unknown runner: $runner (expected codex|claude). Check agents/model_config.md" >&2
  return 1
}

# Builder
run_cycle "$BUILDER_RUNNER" "$BUILDER_MODEL" "Open agents/_start.md and follow instructions." \
  "$RUN_DIR/builder.stdout.log" "$RUN_DIR/builder.stderr.log" "$RUN_DIR/builder.last.md"

# Integration (run only if required by agents/workflow_config.md)
run_cycle "$INTEGRATION_RUNNER" "$INTEGRATION_MODEL" "Open agents/_integrate.md and follow instructions." \
  "$RUN_DIR/integration.stdout.log" "$RUN_DIR/integration.stderr.log" "$RUN_DIR/integration.last.md"

# QA
run_cycle "$QA_RUNNER" "$QA_MODEL" "Open agents/_check.md and follow instructions." \
  "$RUN_DIR/qa.stdout.log" "$RUN_DIR/qa.stderr.log" "$RUN_DIR/qa.last.md"
```

**Timeouts in bash:** if you have GNU `timeout`, wrap the command like:

```bash
timeout 5400 codex exec --model gpt-5.2-codex --full-auto -o "$RUN_DIR/builder.last.md" "Open agents/_start.md and follow instructions."
```

Notes:
- Keep the *prompt string* exactly as specified; only flags/redirects may change.
- If you don't want global permission bypassing for Claude Code, replace `--dangerously-skip-permissions` with a stricter `--allowedTools` set and/or a `--permission-mode` that matches your policy.

---

## Preflight checklist (do this every time before the loop)

1) Confirm you are in repo root (the directory containing `agents/_start.md`).
2) `git status` must be clean OR you must understand the uncommitted changes (don’t silently run over a dirty tree).
3) Ensure tool availability:
   - `codex --version`
   - If using Claude Code for QA: `claude -v`
   - For diagnostics PR: `gh --version` and `gh auth status`
4) Confirm task sources:
   - `agents/tasks.md` exists (may be empty placeholder)
   - `agents/tasksbacklog.md` exists and is not empty (unless a task is already active)
5) Confirm integration config (if periodic/alternating integration is enabled):
   - `agents/workflow_config.md` exists and has the top flags.

If any preflight check fails and you cannot resolve quickly, go to **Blocker handler**.

---

## Main loop (repeat until backlog empty)

### 0) Ensure there is an active task card
- If `agents/tasks.md` already contains a task card, treat it as active.
- Otherwise, promote the **next** card from `agents/tasksbacklog.md` into `agents/tasks.md`.

Promotion rule:
- Move the first top-level card section starting with `## ` (up to but not including the next `## ` at the same level).

After promotion:
- Save files.
- Do **not** start Builder if you failed to promote cleanly.

### 1) Create a run folder
Create a new run folder:
- `agents/runs/YYYY-MM-DD_HHMMSS/`

Inside it, you will store:
- `builder.last.md` (or `.txt`)
- `builder.stdout.log`
- `builder.stderr.log`
- `integration.last.md`
- `integration.stdout.log`
- `integration.stderr.log`
- `qa.last.md`
- `qa.stdout.log`
- `qa.stderr.log`
- `runner_notes.md` (brief timeline + what you observed)

### 1.5) Load integration counters (per task)
- Read the top flags in `agents/workflow_config.md` and capture:
  - `INTEGRATION_COUNT`
  - `INTEGRATION_TARGET`
- Inspect the active task card for `**Gates:**` and note whether `INTEGRATION` is present.
- Record the counters in `runner_notes.md`.

### 2) Builder cycle (new task)
Spawn the Builder headlessly with the exact prompt:

- `Open agents/_start.md and follow instructions.`

Capture the final message (preferred) and stdout/stderr logs into the run folder.

Timeout rule:
- If the process runs longer than 90 minutes, kill it and go to **Blocker handler**.

Completion rule:
- Wait until you observe `### BUILDER_COMPLETE`.
- Then clear the flag (set `agents/status.md` to `### IDLE` if using it).

If you instead observe `### BLOCKED`, go to **Blocker handler**.

### 3) Integration cycle (conditional)

Decide whether to run Integration based on counters and gates:
- Run when the task has the `INTEGRATION` gate, or when `INTEGRATION_COUNT >= INTEGRATION_TARGET`.

If Integration should run, execute the sub-agent headlessly with the exact prompt:
- `Open agents/_integrate.md and follow instructions.`

Then:
- Wait until you observe `### INTEGRATION_COMPLETE`, then clear the flag (`agents/status.md` → `### IDLE`).
- If you observe `### BLOCKED`, go to **Blocker handler**.
- Confirm the Integration Report exists:
  - `agents/runs/<RUN_ID>/integration_report.md` or `agents/integration_report.md`.

### 4) QA cycle (new task)
Spawn QA headlessly with the exact prompt:

- `Open agents/_check.md and follow instructions.`

Timeout rule:
- Same 90-minute rule.

Outcome rule:
- Wait until you observe either:
  - `### QA_COMPLETE`  → go to **Finalize**
  - `### QUICKFIX_NEEDED` → go to **Quickfix flow**
  - `### BLOCKED` → go to **Blocker handler**

Clear the flag after reading it (status.md → `### IDLE`).

---

## Quickfix flow (only if QA says QUICKFIX_NEEDED)

Repeat for up to 2 attempts:

### 5) Hotfix cycle
Spawn Builder/Hotfix headlessly with:

- `Open agents/_hotfix.md and follow instructions.`

Wait for either:
- `### BUILDER_COMPLETE` (or a dedicated `### HOTFIX_COMPLETE` if your hotfix instructions use that)
- `### BLOCKED`

Clear the flag.

### 6) Doublecheck cycle (QA on quickfix)
Spawn QA headlessly with:

- `Open agents/_doublecheck.md and follow instructions.`

Wait for:
- `### QA_COMPLETE` → Quickfix resolved, proceed to **Finalize**
- `### QUICKFIX_NEEDED` → attempt += 1 and repeat Hotfix cycle
- `### BLOCKED` → go to **Blocker handler**

Clear the flag.

If you hit the attempt limit and QA still wants a quickfix, treat as blocked.

---

## Finalize (task complete)

When you reach `### QA_COMPLETE` (either from the normal QA cycle or from doublecheck):

1) **Delete the quickfix work file if it exists**:
   - Delete `agents/quickfix.md` (do not leave stale quickfix artifacts).

2) **Archive the completed task card**:
   - Move the *entire* active card from `agents/tasks.md` into `agents/tasksarchive.md`.
   - Prefer prepending it (newest first), unless your archive is append-only by convention.

3) **Clear `agents/tasks.md`**:
   - Leave it empty or put a minimal placeholder (do not delete the file).

4) Write a short runner note into `agents/runs/.../runner_notes.md` summarizing:
   - task title
   - builder result
   - QA result
   - quickfix attempts (if any)
   - timestamps

5) Update `agents/workflow_config.md` counters (only when periodic/alternating integration is enabled):
   - If Integration ran this cycle, set `INTEGRATION_COUNT=0` and, if periodic targets are used, advance `INTEGRATION_TARGET` by +1 (3→4→5→6→3).
   - If Integration did not run, increment `INTEGRATION_COUNT` by 1.

Then loop back to **0)**.

Stop cleanly when `agents/tasksbacklog.md` has no remaining task cards.

---

## Blocker handler (Diagnostics PR + @codex)

### When to declare “blocked”
Declare blocked immediately if:
- Any headless run hits the 90-minute timeout.
- A run ends but you cannot find a valid completion flag.
- You see `### BLOCKED`.
- Quickfix attempts are exhausted and QA still wants quickfixes.
- You hit a permissions gate or tool error that would stall unattended operation.

### Actions (must do all of these, in order)
1) Create a diagnostics bundle folder:
   - `agents/diagnostics/YYYY-MM-DD_HHMMSS/`

2) Save into it:
   - The entire run folder `agents/runs/YYYY-MM-DD_HHMMSS/` (or copy its contents)
   - Snapshots of:
     - `agents/tasks.md`
     - `agents/tasksbacklog.md`
     - `agents/tasksarchive.md` (optional, but helpful)
     - `agents/historylog.md`
     - `agents/status.md` (if present)
     - `agents/quickfix.md` (if present)
   - `git status` output and `git diff` output captured into text files.

3) Create a new branch:
   - `diag/runner-blocked-YYYYMMDD-HHMMSS`

4) Commit the diagnostics bundle to that branch and push it.

5) Open a PR to your main branch using GitHub CLI (`gh`):
   - Title: `Diagnostics: runner blocked YYYY-MM-DD HH:MM:SS`
   - Body: include:
     - active task title
     - where it blocked (builder / QA / hotfix / doublecheck)
     - any timeout/tool errors
     - path to diagnostics folder

6) In the PR comments, tag Codex Cloud for analysis using **@codex** with a non-review task, e.g.:

Example GitHub CLI commands (run from the diagnostics branch):

```bash
# Create the PR (interactive editor may open unless you pass --body/-b)
gh pr create --title "Diagnostics: runner blocked $(date +%F\ %T)" --body "See agents/diagnostics/<DIAG_DIR> for logs and snapshots."

# Comment on the PR from the same branch
gh pr comment --body "@codex Diagnose why the local runner got blocked. Read agents/diagnostics/<DIAG_DIR> and propose the smallest fix to unblock the runner."
```

PowerShell variant:

```powershell
gh pr create --title "Diagnostics: runner blocked $((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))" --body "See agents/diagnostics/<DIAG_DIR> for logs and snapshots."
gh pr comment --body "@codex Diagnose why the local runner got blocked. Read agents/diagnostics/<DIAG_DIR> and propose the smallest fix to unblock the runner."
```

```
@codex Diagnose why the local runner got blocked. Read the logs in agents/diagnostics/YYYY-MM-DD_HHMMSS/ and propose the smallest fix (or exact next manual action) to unblock the runner. Do NOT run tests in CI; this project is local-first. If the fix is code changes, propose a patch or PR-ready diff.
```

7) Stop. Do not continue task execution after filing diagnostics.

---

## Notes (important)
- Your job is reliability. Prefer stopping + diagnostics over guessing.
- Never modify the allowed prompt strings.
- If you must choose between speed and determinism: choose determinism.
