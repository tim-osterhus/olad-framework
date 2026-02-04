param(
  [Parameter(Mandatory=$true)][string]$ModelId,
  [Parameter(Mandatory=$true)][string]$BundleDir,
  [Parameter(Mandatory=$true)][string]$OutPath
)

$ErrorActionPreference = "Stop"

function Read-WorkflowConfig {
  $cfg = @{}
  $path = "agents/options/workflow_config.md"
  if (-not (Test-Path $path)) { return $cfg }
  foreach ($line in Get-Content $path) {
    if ($line -match '^##\s*([A-Z0-9_]+)\s*=\s*(.*)$') {
      $cfg[$matches[1]] = $matches[2].Trim()
    }
  }
  return $cfg
}

function Get-OpenClawToken {
  if (-not [string]::IsNullOrWhiteSpace($env:OPENCLAW_GATEWAY_TOKEN)) {
    return $env:OPENCLAW_GATEWAY_TOKEN
  }

  $cli = $null
  if (Get-Command "openclaw" -ErrorAction SilentlyContinue) { $cli = "openclaw" }
  elseif (Get-Command "openclaw.exe" -ErrorAction SilentlyContinue) { $cli = "openclaw.exe" }

  if ($null -eq $cli) { throw "OpenClaw token not available. Set OPENCLAW_GATEWAY_TOKEN or install openclaw/openclaw.exe." }

  try {
    $raw = & $cli config get gateway.auth.token --json 2>$null
    if (-not [string]::IsNullOrWhiteSpace($raw)) {
      try {
        $obj = $raw | ConvertFrom-Json
        if ($obj -and $obj.value -and (-not [string]::IsNullOrWhiteSpace([string]$obj.value))) {
          return ([string]$obj.value).Trim()
        }
      } catch {}
    }
  } catch {}

  $raw2 = & $cli config get gateway.auth.token
  return ([string]$raw2).Trim()
}

function Analyze-CallOpenClawGateway {
  param(
    [string]$GatewayUrl,
    [string]$AgentId,
    [string]$Token,
    [string]$ModelId,
    [string]$Prompt
  )

  $uri = ($GatewayUrl.TrimEnd("/") + "/v1/responses")
  $headers = @{
    Authorization = "Bearer $Token"
    "Content-Type" = "application/json"
    "x-openclaw-agent-id" = $AgentId
  }
  $body = @{ model = $ModelId; input = $Prompt } | ConvertTo-Json -Depth 5
  $resp = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body

  if ($resp -and $resp.error) {
    $msg = ""
    try { $msg = [string]$resp.error.message } catch { $msg = [string]$resp.error }
    throw "Analyzer error: $msg"
  }

  if ($resp -and $resp.output_text) {
    return [string]$resp.output_text
  }

  return ""
}

if (-not (Test-Path (Join-Path $BundleDir "result.json"))) {
  throw "Missing $BundleDir/result.json"
}

$cfg = Read-WorkflowConfig
$gatewayUrl = $cfg["OPENCLAW_GATEWAY_URL"]
if ([string]::IsNullOrWhiteSpace($gatewayUrl)) { $gatewayUrl = "http://127.0.0.1:18789" }
$agentId = $cfg["OPENCLAW_AGENT_ID"]
if ([string]::IsNullOrWhiteSpace($agentId)) { $agentId = "main" }
$token = Get-OpenClawToken

$resultJson = Get-Content (Join-Path $BundleDir "result.json") -Raw
if ($resultJson.Length -gt 40000) { $resultJson = $resultJson.Substring(0, 40000) }

$evidenceDir = Join-Path $BundleDir "evidence"
$evidenceFiles = @()
if (Test-Path $evidenceDir) {
  $evidenceFiles = Get-ChildItem -Path $evidenceDir -Recurse -File | Select-Object -First 200 | ForEach-Object {
    $_.FullName.Replace($BundleDir + [System.IO.Path]::DirectorySeparatorChar, "")
  }
}

$prompt = @"
You are an automated UI verification report writer.

Inputs:
- result.json (authoritative): below
- evidence file list: below

Write a concise Markdown report with:
1) UI_VERIFY: PASS|FAIL|BLOCKED (repeat the status from result.json; do not change it)
2) What failed (if anything), grouped by check/suite if available
3) Likely causes (hypotheses; clearly labeled)
4) Suggested next fixes / debugging steps

Do NOT include secrets. Do NOT claim you verified UI beyond what the evidence supports.

--- result.json (truncated) ---
$resultJson

--- evidence files (truncated) ---
$($evidenceFiles -join "`n")
"@

New-Item -ItemType Directory -Force -Path (Join-Path $BundleDir "meta") | Out-Null

$report = ""
try {
  $report = Analyze-CallOpenClawGateway -GatewayUrl $gatewayUrl -AgentId $agentId -Token $token -ModelId $ModelId -Prompt $prompt
} catch {
  [System.IO.File]::WriteAllText((Join-Path $BundleDir "meta/analyzer.stderr.log"), $_.Exception.Message + "`n")
  throw
}

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $OutPath) | Out-Null
[System.IO.File]::WriteAllText($OutPath, $report + "`n")

