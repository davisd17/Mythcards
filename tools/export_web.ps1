# Exports the "Web (test)" preset to build/web/index.html.
# Requires the Godot 4.7.2 Web export templates in %APPDATA%\Godot\export_templates\4.7.2.stable\.
# The test preset carries the "test_bridge" feature tag, so TestBridge's JS hooks are live.
#
# Usage: tools/export_web.ps1 [-Release] [-Godot <path>]    then: tools/serve_web.ps1
param([switch]$Release, [string]$Godot = $env:GODOT)
$ErrorActionPreference = 'Stop'

$Godot = & (Join-Path $PSScriptRoot 'find_godot.ps1') $Godot
$repo = Split-Path $PSScriptRoot -Parent
$game = Join-Path $repo 'game'
$out = Join-Path $repo 'build\web'

& (Join-Path $PSScriptRoot 'sync_game_content.ps1')
if (Test-Path $out) { Remove-Item $out -Recurse -Force }
New-Item -ItemType Directory -Force $out | Out-Null

$ErrorActionPreference = 'Continue'  # Godot writes progress to stderr
& $Godot --headless --path $game --import 2>&1 | Out-Null
$mode = if ($Release) { '--export-release' } else { '--export-debug' }
$log = & $Godot --headless --path $game $mode 'Web (test)' (Join-Path $out 'index.html') 2>&1 | ForEach-Object { "$_" }
$exitCode = $LASTEXITCODE

$problems = $log | Select-String -Pattern 'ERROR|SCRIPT ERROR|No export template'
if ($exitCode -ne 0 -or $problems -or -not (Test-Path (Join-Path $out 'index.pck'))) {
    $log | Write-Host
    Write-Host "`nWeb export FAILED" -ForegroundColor Red
    exit 1
}
Get-ChildItem $out | ForEach-Object { '{0,-28} {1,10:N0} KB' -f $_.Name, ($_.Length / 1KB) }
Write-Host "`nWeb export OK -> $out   Serve with: tools/serve_web.ps1"
