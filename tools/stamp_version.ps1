# Writes the git short hash (plus "-dirty" if the tree has changes) into game/project.godot as
# application/config/version, for an export (LLD-network-match.md 4.5: an online match only
# replays on the build that started it). Returns the file's original text, so the export
# script can put it back afterwards and the stamp never shows up as a change.
#
# Usage (from an export script):
#   $original = & (Join-Path $PSScriptRoot 'stamp_version.ps1')
#   try { ...export... } finally { [IO.File]::WriteAllText($projectFile, $original) }
$ErrorActionPreference = 'Stop'

$repo = Split-Path $PSScriptRoot -Parent
$projectFile = Join-Path $repo 'game\project.godot'

$hash = (git -C $repo rev-parse --short HEAD).Trim()
$dirty = git -C $repo status --porcelain --untracked-files=no
if ($dirty) { $hash += '-dirty' }

$original = [IO.File]::ReadAllText($projectFile)
$lines = [Collections.Generic.List[string]]($original -split "`n")
$at = $lines.FindIndex([Predicate[string]] { param($l) $l.TrimEnd("`r") -like 'config/version=*' })
$line = "config/version=`"$hash`""
if ($at -ge 0) {
    $lines[$at] = $line
} else {
    $section = $lines.FindIndex([Predicate[string]] { param($l) $l.TrimEnd("`r") -eq '[application]' })
    if ($section -lt 0) { throw "No [application] section in $projectFile" }
    $lines.Insert($section + 2, $line)
}
[IO.File]::WriteAllText($projectFile, ($lines -join "`n"))
Write-Host "Version stamp: $hash"
return $original
