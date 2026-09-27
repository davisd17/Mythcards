# Syncs card data, imports the Godot project, and runs the GUT unit tests headless.
# Exit code is nonzero if any test fails.
#
# Usage: tools/run_game_tests.ps1 [-Godot <path to Godot console exe>]
# Godot lookup order is in tools/find_godot.ps1.
param([string]$Godot = $env:GODOT)
$ErrorActionPreference = 'Stop'

$Godot = & (Join-Path $PSScriptRoot 'find_godot.ps1') $Godot

$repo = Split-Path $PSScriptRoot -Parent
$game = Join-Path $repo 'game'

& (Join-Path $PSScriptRoot 'sync_game_content.ps1')

# Godot logs expected test errors to stderr; with 'Stop', Windows PowerShell would
# turn the first one into a terminating error.
$ErrorActionPreference = 'Continue'

# Import first so class_name scripts are registered before GUT loads the tests.
$importLog = & $Godot --headless --path $game --import 2>&1 | ForEach-Object { "$_" }

$testLog = & $Godot --headless --path $game -s addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json 2>&1 |
    ForEach-Object { "$_" }
$exitCode = $LASTEXITCODE
$testLog | Write-Host

# GUT skips a test script that fails to parse and still reports "All tests passed",
# so a script error anywhere must fail the run explicitly.
$scriptErrors = @($importLog + $testLog) | Select-String -Pattern 'SCRIPT ERROR|Ignoring script'
if ($scriptErrors) {
    Write-Host "`nFAILED: script errors (tests may have been skipped):" -ForegroundColor Red
    $scriptErrors | Select-Object -Unique | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    exit 1
}
exit $exitCode
