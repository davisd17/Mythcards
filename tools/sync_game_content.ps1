# Copies card data from data/cards (the single source of truth) into game/data/cards
# so the Godot project can load it via res://. game/data/ is gitignored — rerun this
# after any card data edit, before opening the editor, running tests, or exporting.
$ErrorActionPreference = 'Stop'

$repo = Split-Path $PSScriptRoot -Parent
$src = Join-Path $repo 'data\cards'
$dst = Join-Path $repo 'game\data\cards'

if (Test-Path $dst) { Remove-Item $dst -Recurse -Force }
New-Item -ItemType Directory -Force (Join-Path $dst 'review_drafts') | Out-Null

Copy-Item (Join-Path $src '*.json') $dst
Copy-Item (Join-Path $src 'review_drafts\*.json') (Join-Path $dst 'review_drafts')

$count = (Get-ChildItem $dst -Recurse -Filter *.json).Count
Write-Host "Synced $count card data files into game/data/cards"
