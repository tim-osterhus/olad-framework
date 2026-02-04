param(
  [ValidateSet("auto","flash","pro_low","pro_high")][string]$Model = "auto",
  [switch]$Force,
  [int]$RetryMinutes = 360
)

$ErrorActionPreference = "Stop"

function Read-WorkflowConfig {
  $cfg = @{}
  $path = "agents/options/workflow_config.md"
  if (-not (Test-Path $path)) { return $cfg }
  foreach ($line in Get-Content $path) {
    if ($line -match '^##\s*([A-Z0-9_]+)\s*=\s*(.*)$') {
      $key = $matches[1]
      $val = $matches[2].Trim()
      $cfg[$key] = $val
    }
  }
  return $cfg
}

function Write-WorkflowConfigValue {
  param([string]$Key, [string]$Value)

  $path = "agents/options/workflow_config.md"
  $lines = @()
  if (Test-Path $path) { $lines = Get-Content $path }

  $out = New-Object System.Collections.Generic.List[string]
  $found = $false
  foreach ($line in $lines) {
    if ($line -match ("^##\s*" + [Regex]::Escape($Key) + "\s*=")) {
      $out.Add("## $Key=$Value")
      $found = $true
    } else {
      $out.Add($line)
    }
  }
  if (-not $found) {
    $out.Add("## $Key=$Value")
  }
  [System.IO.File]::WriteAllText($path, ($out -join "`n") + "`n")
}

function Now-MinuteUtc {
  return (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm")
}

function MinutesSinceUtc {
  param([string]$Stamp)
  if ([string]::IsNullOrWhiteSpace($Stamp)) { return $null }
  try {
    $dt = [DateTime]::ParseExact($Stamp, "yyyy-MM-ddTHH:mm", [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::AssumeUniversal)
    $now = (Get-Date).ToUniversalTime()
    return [int](($now - $dt.ToUniversalTime()).TotalMinutes)
  } catch {
    return $null
  }
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

  # Fallback: some installs print the token directly.
  $raw2 = & $cli config get gateway.auth.token
  return ([string]$raw2).Trim()
}

function Is-QuotaErrorMessage {
  param([string]$Message)
  if ([string]::IsNullOrWhiteSpace($Message)) { return $false }
  $m = $Message.ToLowerInvariant()
  return ($m.Contains("quota") -or $m.Contains("rate limit") -or $m.Contains("resource_exhausted") -or $m.Contains("too many requests") -or $m.Contains("429"))
}

function Probe-CallOpenClawGateway {
  param(
    [string]$GatewayUrl,
    [string]$AgentId,
    [string]$Token,
    [string]$ModelId
  )

  $uri = ($GatewayUrl.TrimEnd("/") + "/v1/responses")
  $headers = @{
    Authorization = "Bearer $Token"
    "Content-Type" = "application/json"
    "x-openclaw-agent-id" = $AgentId
  }
  $body = @{ model = $ModelId; input = "Reply with the single token OK." } | ConvertTo-Json -Depth 5

  try {
    $resp = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body
  } catch {
    $msg = $_.Exception.Message
    if (Is-QuotaErrorMessage $msg) { return @{ ok = $false; quota = $true; message = $msg } }
    return @{ ok = $false; quota = $false; message = $msg }
  }

  if ($resp -and $resp.error) {
    $msg2 = ""
    try { $msg2 = [string]$resp.error.message } catch { $msg2 = [string]$resp.error }
    if (Is-QuotaErrorMessage $msg2) { return @{ ok = $false; quota = $true; message = $msg2 } }
    return @{ ok = $false; quota = $false; message = $msg2 }
  }

  return @{ ok = $true; quota = $false; message = "" }
}

function ModelOrderForPref([string]$Pref) {
  switch ($Pref) {
    "flash" { return @("flash","pro_low","pro_high") }
    "pro_low" { return @("pro_low","pro_high","flash") }
    "pro_high" { return @("pro_high","pro_low","flash") }
    default { return @("flash","pro_low","pro_high") }
  }
}

function ExhaustedKeyFor([string]$m) {
  switch ($m) {
    "flash" { return "ANTIGRAVITY_G3_FLASH_EXHAUSTED_AT" }
    "pro_low" { return "ANTIGRAVITY_G3_PRO_LOW_EXHAUSTED_AT" }
    "pro_high" { return "ANTIGRAVITY_G3_PRO_HIGH_EXHAUSTED_AT" }
    default { return "" }
  }
}

function ModelIdKeyFor([string]$m) {
  switch ($m) {
    "flash" { return "ANTIGRAVITY_G3_FLASH_MODEL" }
    "pro_low" { return "ANTIGRAVITY_G3_PRO_LOW_MODEL" }
    "pro_high" { return "ANTIGRAVITY_G3_PRO_HIGH_MODEL" }
    default { return "" }
  }
}

$cfg = Read-WorkflowConfig
$gatewayUrl = $cfg["OPENCLAW_GATEWAY_URL"]
if ([string]::IsNullOrWhiteSpace($gatewayUrl)) { $gatewayUrl = "http://127.0.0.1:18789" }
$agentId = $cfg["OPENCLAW_AGENT_ID"]
if ([string]::IsNullOrWhiteSpace($agentId)) { $agentId = "main" }

$pref = $cfg["ANTIGRAVITY_MODEL_PREF"]
if ([string]::IsNullOrWhiteSpace($pref)) { $pref = "auto" }

$order = @()
if ($Model -ne "auto") {
  $order = @($Model)
} else {
  $order = ModelOrderForPref $pref
}

$token = Get-OpenClawToken

$hadAnyModelId = $false

foreach ($m in $order) {
  $midKey = ModelIdKeyFor $m
  $modelId = if ($midKey -and $cfg.ContainsKey($midKey)) { $cfg[$midKey] } else { "" }
  if ([string]::IsNullOrWhiteSpace($modelId)) {
    [Console]::Error.WriteLine("Skipping $m (missing model id; set $midKey in agents/options/workflow_config.md)")
    continue
  }
  $hadAnyModelId = $true

  $exKey = ExhaustedKeyFor $m
  $exVal = if ($exKey -and $cfg.ContainsKey($exKey)) { $cfg[$exKey] } else { "" }
  if (-not $Force -and -not [string]::IsNullOrWhiteSpace($exVal)) {
    $mins = MinutesSinceUtc $exVal
    if ($mins -ne $null -and $mins -lt $RetryMinutes) {
      [Console]::Error.WriteLine("Skipping $m due to recent exhausted flag ($exKey)")
      continue
    }
  }

  $r = Probe-CallOpenClawGateway -GatewayUrl $gatewayUrl -AgentId $agentId -Token $token -ModelId $modelId
  if ($r.ok) {
    if ($exKey) { Write-WorkflowConfigValue -Key $exKey -Value "" }
    Write-Output $modelId
    exit 0
  }

  if ($r.quota) {
    if ($exKey) { Write-WorkflowConfigValue -Key $exKey -Value (Now-MinuteUtc) }
    continue
  }

  [Console]::Error.WriteLine("Probe failed for $m ($modelId) with non-quota error: $($r.message)")
  exit 1
}

if (-not $hadAnyModelId) {
  [Console]::Error.WriteLine("No Anti-Gravity model ids are configured. Set ANTIGRAVITY_G3_*_MODEL in agents/options/workflow_config.md.")
  exit 3
}

exit 2
