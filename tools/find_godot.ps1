# Returns the path to the Godot console executable. Dot-source or call from other tools.
# Order: explicit argument, $env:GODOT, godot*.exe on PATH, then the winget install location.
param([string]$Godot = $env:GODOT)

if (-not $Godot) {
    $cmd = Get-Command 'godot*console*', 'godot4', 'godot' -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($cmd) { $Godot = $cmd.Source }
}
if (-not $Godot) {
    $wingetDir = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages'
    $found = Get-ChildItem $wingetDir -Recurse -Filter 'Godot_v4*_console.exe' -ErrorAction SilentlyContinue |
        Sort-Object Name -Descending | Select-Object -First 1
    if ($found) { $Godot = $found.FullName }
}
if (-not $Godot) { throw 'Godot not found. Install Godot 4.7.x or pass -Godot <path>.' }
$Godot
