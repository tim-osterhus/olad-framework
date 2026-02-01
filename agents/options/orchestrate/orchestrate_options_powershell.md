# Orchestrator Options (PowerShell Templates)

This document is a copy/paste scratchpad for running OLAD cycles headlessly from **PowerShell**
(Windows PowerShell 5.1 or PowerShell 7).

It is intentionally kept out of `agents/_orchestrate.md` to keep the Runner entrypoint small.

## Assumptions

- You are running from the repo root (the directory containing `agents/`).
- You have the CLIs you plan to use installed:
  - `codex` (Codex CLI)
  - `claude` (Claude Code CLI), if used
  - Optional (OpenClaw runner): either
    - `openclaw` / `openclaw.exe` on PATH (to read the Gateway token), OR
    - `OPENCLAW_GATEWAY_TOKEN` set in your environment
- OpenClaw runner requires the Gateway `/v1/responses` endpoint enabled (see `agents/options/openclaw/runner_integration_powershell.md`)

## Create a run folder + run a cycle (PowerShell)

```powershell
$runId = Get-Date -Format 'yyyy-MM-dd_HHmmss'
$runDir = "agents\\runs\\$runId"
New-Item -ItemType Directory -Force -Path $runDir | Out-Null

function Get-OladModelConfig {
  $cfg = @{}
  $inActive = $false

  foreach ($line in Get-Content "agents\\options\\model_config.md") {
    if (-not $inActive) {
      if ($line -match '^##\\s*Active config') { $inActive = $true }
      continue
    }

    if ($line -match '^---\\s*$') { break }

    if ($line -match '^\\s*([A-Z0-9_]+)\\s*=\\s*(.*?)\\s*$') {
      $cfg[$matches[1]] = $matches[2].Trim()
    }
  }

  foreach ($k in @(
    "BUILDER_RUNNER","BUILDER_MODEL",
    "QA_RUNNER","QA_MODEL",
    "HOTFIX_RUNNER","HOTFIX_MODEL",
    "DOUBLECHECK_RUNNER","DOUBLECHECK_MODEL"
  )) {
    if (-not $cfg.ContainsKey($k) -or [string]::IsNullOrWhiteSpace($cfg[$k])) {
      throw "Missing $k in agents/options/model_config.md Active config block"
    }
  }

  return $cfg
}

function Get-OladWorkflowConfig {
  $cfg = @{}

  foreach ($line in Get-Content "agents\\options\\workflow_config.md") {
    if ($line -match '^\\s*##\\s*([A-Z0-9_]+)\\s*=\\s*(.*?)\\s*$') {
      $cfg[$matches[1]] = $matches[2].Trim()
    }
  }

  if (-not $cfg.ContainsKey("HEADLESS_PERMISSIONS") -or [string]::IsNullOrWhiteSpace($cfg["HEADLESS_PERMISSIONS"])) {
    throw "Missing HEADLESS_PERMISSIONS in agents/options/workflow_config.md"
  }

  return $cfg
}

function Get-OladPermissionFlags {
  param([Parameter(Mandatory=$true)][string]$HeadlessPermissions)

  switch ($HeadlessPermissions) {
    "Normal" {
      return @{
        Codex  = @("--full-auto")
        Claude = @()
      }
    }
    "Elevated" {
      return @{
        Codex  = @("--full-auto","--sandbox","danger-full-access")
        Claude = @("--permission-mode","acceptEdits")
      }
    }
    "Maximum" {
      return @{
        Codex  = @("--full-auto","--dangerously-bypass-approvals-and-sandbox")
        Claude = @("--dangerously-skip-permissions")
      }
    }
    default { throw "Unknown HEADLESS_PERMISSIONS: $HeadlessPermissions" }
  }
}

function Get-OpenClawToken {
  if (-not [string]::IsNullOrWhiteSpace($env:OPENCLAW_GATEWAY_TOKEN)) {
    return $env:OPENCLAW_GATEWAY_TOKEN.Trim()
  }

  $cmd = Get-Command openclaw -ErrorAction SilentlyContinue
  if ($cmd) { return (& openclaw config get gateway.auth.token --raw).Trim() }

  $cmdExe = Get-Command openclaw.exe -ErrorAction SilentlyContinue
  if ($cmdExe) { return (& openclaw.exe config get gateway.auth.token --raw).Trim() }

  throw "OpenClaw token not available. Set OPENCLAW_GATEWAY_TOKEN or install openclaw/openclaw.exe."
}

function Invoke-OpenClawResponse {
  param(
    [Parameter(Mandatory=$true)][string]$Model,
    [Parameter(Mandatory=$true)][string]$Prompt,
    [Parameter(Mandatory=$true)][string]$StdoutPath,
    [Parameter(Mandatory=$true)][string]$StderrPath,
    [string]$LastMessagePath = "",
    [string]$RunId = "",
    [string]$OpenClawGatewayUrl = "http://127.0.0.1:18789",
    [string]$OpenClawAgentId = "main"
  )

  if ([string]::IsNullOrWhiteSpace($OpenClawGatewayUrl)) { $OpenClawGatewayUrl = "http://127.0.0.1:18789" }
  if ([string]::IsNullOrWhiteSpace($OpenClawAgentId)) { $OpenClawAgentId = "main" }

  $token = Get-OpenClawToken

  $cycle = [System.IO.Path]::GetFileName($StdoutPath) -replace '\\.stdout\\.log$',''
  $userKey = "olad:$RunId:$cycle"

  $body = @{ model = $Model; user = $userKey; input = $Prompt } | ConvertTo-Json -Compress
  $url = $OpenClawGatewayUrl.TrimEnd("/") + "/v1/responses"

  try {
    $resp = Invoke-RestMethod -Method Post -Uri $url -Headers @{
      Authorization = "Bearer $token"
      "x-openclaw-agent-id" = $OpenClawAgentId
    } -ContentType "application/json" -Body $body

    $responsePath = Join-Path (Split-Path $StdoutPath) "$cycle.openclaw.response.json"
    ($resp | ConvertTo-Json -Depth 30) | Out-File -FilePath $responsePath -Encoding utf8

    $text = ""
    if ($resp.PSObject.Properties.Name -contains "output_text") {
      $text = [string]$resp.output_text
    }

    if ([string]::IsNullOrWhiteSpace($text) -and ($resp.PSObject.Properties.Name -contains "output")) {
      $parts = New-Object System.Collections.Generic.List[string]
      foreach ($item in $resp.output) {
        if ($null -eq $item) { continue }
        if ($item.type -ne "message") { continue }
        if ($item.role -ne "assistant") { continue }
        foreach ($c in ($item.content | ForEach-Object { $_ })) {
          if ($null -eq $c) { continue }
          if ($c.PSObject.Properties.Name -contains "text") {
            $t = $c.text
            if ($t -is [string]) { [void]$parts.Add($t) }
          }
        }
      }
      $text = ($parts -join "")
    }

    $text | Out-File -FilePath $StdoutPath -Encoding utf8
    if ($LastMessagePath) { Copy-Item -Force $StdoutPath $LastMessagePath }
    return 0
  } catch {
    ($_ | Out-String) | Out-File -FilePath $StderrPath -Encoding utf8 -Append
    return 1
  }
}

function Invoke-OladCycle {
  param(
    [Parameter(Mandatory=$true)][string]$Runner,   # codex|claude|openclaw
    [Parameter(Mandatory=$true)][string]$Model,
    [Parameter(Mandatory=$true)][string]$Prompt,
    [Parameter(Mandatory=$true)][string]$StdoutPath,
    [Parameter(Mandatory=$true)][string]$StderrPath,
    [string]$LastMessagePath = "",
    [int]$TimeoutSeconds = 5400,
    [switch]$CodexSearch
  )

  if ($Runner -eq "codex") {
    $args = @("exec","--model",$Model) + $perm["Codex"]
    if ($CodexSearch) { $args += @("--search") }
    if ($LastMessagePath) { $args += @("-o",$LastMessagePath) }
    $args += @($Prompt)

    $proc = Start-Process -FilePath "codex" -ArgumentList $args -NoNewWindow -PassThru `
      -RedirectStandardOutput $StdoutPath -RedirectStandardError $StderrPath

    if (-not $proc.WaitForExit($TimeoutSeconds * 1000)) { $proc.Kill(); exit 124 }
    if ($proc.ExitCode -ne 0) { exit $proc.ExitCode }
    return
  }

  if ($Runner -eq "claude") {
    $args = @("-p",$Prompt,"--model",$Model,"--output-format","text") + $perm["Claude"]

    $proc = Start-Process -FilePath "claude" -ArgumentList $args -NoNewWindow -PassThru `
      -RedirectStandardOutput $StdoutPath -RedirectStandardError $StderrPath

    if (-not $proc.WaitForExit($TimeoutSeconds * 1000)) { $proc.Kill(); exit 124 }
    if ($proc.ExitCode -ne 0) { exit $proc.ExitCode }

    if ($LastMessagePath) { Copy-Item -Force $StdoutPath $LastMessagePath }
    return
  }

  if ($Runner -eq "openclaw") {
    $exitCode = Invoke-OpenClawResponse -Model $Model -Prompt $Prompt -StdoutPath $StdoutPath -StderrPath $StderrPath `
      -LastMessagePath $LastMessagePath -RunId $runId -OpenClawGatewayUrl $workflow["OPENCLAW_GATEWAY_URL"] -OpenClawAgentId $workflow["OPENCLAW_AGENT_ID"]
    if ($exitCode -ne 0) { exit $exitCode }
    return
  }

  throw "Unknown Runner='$Runner' (expected codex|claude|openclaw). Check agents/options/model_config.md"
}

$models = Get-OladModelConfig
$workflow = Get-OladWorkflowConfig
$perm = Get-OladPermissionFlags -HeadlessPermissions $workflow["HEADLESS_PERMISSIONS"]

# Builder
Invoke-OladCycle `
  -Runner $models["BUILDER_RUNNER"] `
  -Model  $models["BUILDER_MODEL"] `
  -Prompt "Open agents/_start.md and follow instructions." `
  -StdoutPath "$runDir\\builder.stdout.log" `
  -StderrPath "$runDir\\builder.stderr.log" `
  -LastMessagePath "$runDir\\builder.last.md"

# QA (Codex should run with --search)
Invoke-OladCycle `
  -Runner $models["QA_RUNNER"] `
  -Model  $models["QA_MODEL"] `
  -Prompt "Open agents/_check.md and follow instructions." `
  -StdoutPath "$runDir\\qa.stdout.log" `
  -StderrPath "$runDir\\qa.stderr.log" `
  -LastMessagePath "$runDir\\qa.last.md" `
  -CodexSearch
```

## Optional cycles (only if your repo enables them)

Integration cycle (only if `agents/_orchestrate.md` has Integration enabled):

```powershell
Invoke-OladCycle `
  -Runner $models["INTEGRATION_RUNNER"] `
  -Model  $models["INTEGRATION_MODEL"] `
  -Prompt "Open agents/_integrate.md and follow instructions." `
  -StdoutPath "$runDir\\integration.stdout.log" `
  -StderrPath "$runDir\\integration.stderr.log" `
  -LastMessagePath "$runDir\\integration.last.md"
```

Hotfix + Doublecheck (only if QA writes `### QUICKFIX_NEEDED`):

```powershell
Invoke-OladCycle `
  -Runner $models["HOTFIX_RUNNER"] `
  -Model  $models["HOTFIX_MODEL"] `
  -Prompt "Open agents/_hotfix.md and follow instructions." `
  -StdoutPath "$runDir\\hotfix.stdout.log" `
  -StderrPath "$runDir\\hotfix.stderr.log" `
  -LastMessagePath "$runDir\\hotfix.last.md"

Invoke-OladCycle `
  -Runner $models["DOUBLECHECK_RUNNER"] `
  -Model  $models["DOUBLECHECK_MODEL"] `
  -Prompt "Open agents/_doublecheck.md and follow instructions." `
  -StdoutPath "$runDir\\doublecheck.stdout.log" `
  -StderrPath "$runDir\\doublecheck.stderr.log" `
  -LastMessagePath "$runDir\\doublecheck.last.md" `
  -CodexSearch
```

Troubleshooter (only if installed and enabled by `agents/_orchestrate.md`):

```powershell
$context = "<blocker summary>"
Invoke-OladCycle `
  -Runner "codex" `
  -Model  "gpt-5.2-codex" `
  -Prompt "Open agents/_troubleshoot.md and follow instructions. For context: `"$context`"" `
  -StdoutPath "$runDir\\troubleshoot.stdout.log" `
  -StderrPath "$runDir\\troubleshoot.stderr.log" `
  -LastMessagePath "$runDir\\troubleshoot.last.md"
```

## Diagnostics PR helpers (gh)

Example commands (run from the diagnostics branch):

```powershell
$ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
gh pr create --title "Diagnostics: runner blocked $ts" --body "See agents/diagnostics/<DIAG_DIR> for logs and snapshots."
gh pr comment --body "@codex Diagnose why the local runner got blocked. Read agents/diagnostics/<DIAG_DIR> and propose the smallest fix to unblock the runner."
```

## Notes

- Keep the *prompt string* exactly as specified in the Runner entrypoints; only flags/redirects may change.
- Permission flags are controlled by `HEADLESS_PERMISSIONS` in `agents/options/workflow_config.md`.
