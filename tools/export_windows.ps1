# Exports the "Windows Desktop" preset to build/windows/MythCards.exe, stamped with the git
# version (tools/stamp_version.ps1) so online matches know which build they belong to.
# Requires the Godot 4.7.2 Windows export templates.
#
# Usage: tools/export_windows.ps1 [-Release] [-Godot <path>]
param([switch]$Release, [string]$Godot = $env:GODOT)
$ErrorActionPreference = 'Stop'

$Godot = & (Join-Path $PSScriptRoot 'find_godot.ps1') $Godot
$repo = Split-Path $PSScriptRoot -Parent
$game = Join-Path $repo 'game'
$out = Join-Path $repo 'build\windows'
$exe = Join-Path $out 'MythCards.exe'

& (Join-Path $PSScriptRoot 'sync_game_content.ps1')
New-Item -ItemType Directory -Force $out | Out-Null

$projectFile = Join-Path $game 'project.godot'
$original = & (Join-Path $PSScriptRoot 'stamp_version.ps1')
$ErrorActionPreference = 'Continue'  # Godot writes progress to stderr
try {
    & $Godot --headless --path $game --import 2>&1 | Out-Null
    $mode = if ($Release) { '--export-release' } else { '--export-debug' }
    $log = & $Godot --headless --path $game $mode 'Windows Desktop' $exe 2>&1 | ForEach-Object { "$_" }
    $exitCode = $LASTEXITCODE
} finally {
    [IO.File]::WriteAllText($projectFile, $original)   # the stamp lives only in the build
}

$problems = $log | Select-String -Pattern 'ERROR|SCRIPT ERROR|No export template'
if ($exitCode -ne 0 -or $problems -or -not (Test-Path $exe)) {
    $log | Write-Host
    Write-Host "`nWindows export FAILED" -ForegroundColor Red
    exit 1
}
Get-Item $exe | ForEach-Object { '{0,-28} {1,10:N0} KB  {2}' -f $_.Name, ($_.Length / 1KB), $_.LastWriteTime }
Write-Host "`nWindows export OK -> $exe"
