# Opens the game screen in a desktop window for playtesting (hotseat; the debug match is
# under Menu > Debug view).
# Syncs card data first so edits in data/cards are picked up.
#
# Usage: tools/play.ps1 [-Godot <path>]
param([string]$Godot = $env:GODOT)
$ErrorActionPreference = 'Stop'

$Godot = & (Join-Path $PSScriptRoot 'find_godot.ps1') $Godot
$game = Join-Path (Split-Path $PSScriptRoot -Parent) 'game'
& (Join-Path $PSScriptRoot 'sync_game_content.ps1')

# The console build keeps a log window next to the game; use the plain one if found.
$windowed = $Godot -replace '_console\.exe$', '.exe'
if (-not (Test-Path $windowed)) { $windowed = $Godot }
& $windowed --path $game
