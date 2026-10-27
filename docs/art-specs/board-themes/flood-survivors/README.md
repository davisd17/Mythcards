# Flood Survivors Battlefield Theme V1

2026-10-26. Implemented and included in the user-requested GitHub delivery.

## Art Direction

A living submerged sanctuary, not a ruined city: scalloped basalt columns,
bronze celestial instruments, sealed memory archives, pearl lamps and dry
causeways over black water. The board uses celadon stone with fossil-shell veins,
subtle caustics, pearl inlay and bronze/emerald tide-work around the edge. Muted
coral and warm lamps balance the cyan water. Meret-Anu's canonical card supplied
the architectural/material reference, not a new location lore claim.

Built-in ImageGen assets (opaque PNGs; exact prompts in `PROMPTS.md`):

- `game/assets/boards/flood-survivors/sanctuary-v1.png`: environment backdrop.
- `game/assets/boards/flood-survivors/tide-stone-v1.png`: square board material.

## Runtime Contract

`BattlefieldTheme.THEMES` maps the starting side's Leader sub-area to the two
textures and central floor tint. Flood Survivors now receives its own environment;
Closed City retains its existing art and tint. Other areas still use the original
neutral fallback. The selected/active character and ordinary turn changes never
choose the environment. No music assets or music selection rules were changed.

The existing nine-slice frame keeps the same 7x7 playable grid and margin. The
stone texture sits below seams, territory, legal markers, objectives, objects,
characters and labels. Closed City's bolt details are not drawn on Atlantean stone.
Shared environmental and HUD scrims preserve contrast and ignore pointer input.
Character scale, anchoring, zoom and game rules are unchanged.

This prepares presentation for a Flood Survivors first player; it does NOT add
a coin flip or change the current setup flow's starter-selection rules.

## Verification

Final full game suite: 624/624 tests passed, 3761 assertions. Tests exercise both
area textures, player/team reversal, persistence across turns, neutral fallback,
cover crop bounds and all 49 tile rectangles/hit targets across the theme switch.

Native full-game-screen captures under `qa/` at 1440x960, 390x844 and 844x390.
The review fixture sets `first_player_id` to p2, restarts match presentation and
starts p2's turn solely for art QA; this is not a new production starting rule.

Reproduce with the normal Godot renderer, project `game`, scene
`res://tests/helpers/closed_city_visual_review.tscn`, user argument
`--flood-survivors` (after `--` on the command line). Without the argument it
continues to render the Closed City review. Native rendering, not a generated UI.

Existing orphan/RID warnings and local user-log/shader-cache permission warnings
remain. Browser/Web export was not run in this delivery. Existing in-progress
ability, roster, guidebook and website edits were preserved.
