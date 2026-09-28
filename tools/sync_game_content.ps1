# Copies card data from data/cards (the single source of truth) into game/data/cards
# so the Godot project can load it via res://. game/data/ is gitignored — rerun this
# after any card data edit, before opening the editor, running tests, or exporting.
$ErrorActionPreference = 'Stop'

$repo = Split-Path $PSScriptRoot -Parent
$src = Join-Path $repo 'data\cards'
$dst = Join-Path $repo 'game\data\cards'

if (Test-Path $dst) { Remove-Item $dst -Recurse -Force }   # card JSON only; card_art is cached
New-Item -ItemType Directory -Force (Join-Path $dst 'review_drafts') | Out-Null

Copy-Item (Join-Path $src '*.json') $dst
Copy-Item (Join-Path $src 'review_drafts\*.json') (Join-Path $dst 'review_drafts')

$count = (Get-ChildItem $dst -Recurse -Filter *.json).Count
Write-Host "Synced $count card data files into game/data/cards"

# Card art: data/cards/card_art.json maps card ids to source images under assets/. The
# game gets small JPEG copies (game/data/card_art/<id>.art, read as raw bytes so Godot
# doesn't import them), regenerated only when the source is newer.
Add-Type -AssemblyName System.Drawing
$artDst = Join-Path $repo 'game\data\card_art'
New-Item -ItemType Directory -Force $artDst | Out-Null
$artMap = Get-Content (Join-Path $src 'card_art.json') -Raw | ConvertFrom-Json
$jpeg = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
$quality = New-Object System.Drawing.Imaging.EncoderParameters 1
$quality.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter ([System.Drawing.Imaging.Encoder]::Quality), 85L
$made = 0
foreach ($entry in $artMap.PSObject.Properties) {
    if ($entry.Name.StartsWith('_')) { continue }
    $from = Join-Path $repo $entry.Value
    $to = Join-Path $artDst ($entry.Name + '.art')
    if (-not (Test-Path $from)) { Write-Warning "card_art.json: $($entry.Name) -> missing $($entry.Value)"; continue }
    if ((Test-Path $to) -and (Get-Item $to).LastWriteTime -ge (Get-Item $from).LastWriteTime) { continue }
    $image = [System.Drawing.Image]::FromFile($from)
    $width = 400
    $height = [int]($image.Height * $width / $image.Width)
    $small = New-Object System.Drawing.Bitmap $width, $height
    $g = [System.Drawing.Graphics]::FromImage($small)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.DrawImage($image, 0, 0, $width, $height)
    $small.Save($to, $jpeg, $quality)
    $g.Dispose(); $small.Dispose(); $image.Dispose()
    $made++
}
$artCount = (Get-ChildItem $artDst -Filter *.art).Count
Write-Host "Card art: $artCount images in game/data/card_art ($made regenerated)"
