# Exports the Web build and runs the Playwright suite (e2e/) against it through
# TestBridge. Installs e2e dependencies on first run.
#
# Usage: tools/run_e2e.ps1 [-SkipExport] [extra playwright args, e.g. -g "full match"]
param([switch]$SkipExport, [Parameter(ValueFromRemainingArguments = $true)] $PlaywrightArgs)
$ErrorActionPreference = 'Stop'

$repo = Split-Path $PSScriptRoot -Parent
$e2e = Join-Path $repo 'e2e'
$nodeDir = 'C:\Program Files\nodejs'
if ((Test-Path $nodeDir) -and -not ($env:Path -split ';' -contains $nodeDir)) { $env:Path = "$nodeDir;$env:Path" }

if (-not $SkipExport) {
    & (Join-Path $PSScriptRoot 'export_web.ps1')
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

Push-Location $e2e
try {
    if (-not (Test-Path 'node_modules')) {
        npm install --no-audit --no-fund
        npx playwright install chromium
    }
    npx playwright test @PlaywrightArgs
    exit $LASTEXITCODE
} finally {
    Pop-Location
}
