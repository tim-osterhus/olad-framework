param(
  [switch]$Force,
  [int]$RetryMinutes = 360
)

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
& (Join-Path $here "probe_gemini_auto.ps1") -Model "flash" -Force:$Force -RetryMinutes $RetryMinutes
exit $LASTEXITCODE

