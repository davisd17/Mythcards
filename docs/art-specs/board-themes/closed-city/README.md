# Closed City Battlefield Theme V1

2026-10-24. Implemented and prepared for the user-requested GitHub delivery.
No website changes, gameplay changes or new paid tools.

## Visual Direction

A classified containment deck inside an underground analogue reactor chamber.
Pewter composite floor, enamel oxblood rails, worn safety-yellow markings, jade
instrument lights and nickel fittings replace the plain board and black surround.
The active scene remains a tactical game, not an illustrated loading screen.

Generated with built-in ImageGen. Exact prompts are in `PROMPTS.md`.
Final project-bound assets:

- `game/assets/boards/closed-city/chamber-v1.png`: opaque environment backdrop.
- `game/assets/boards/closed-city/containment-deck-v1.png`: opaque square surface
  and perimeter, nine-sliced at runtime without altering board geometry.

## Theme Selection

`BattlefieldTheme.area_for` follows `MatchState.first_player_id` and that side's
Leader sub-area, matching MusicManager's existing selection convention. The user
described the opening Hero; the current engine actually chooses music by Leader.
Neither gameplay roster roles nor the music selector were changed here.

The environment stays the same across turn changes. It does not follow the
currently selected piece, current player, cosmetic outfit or defeated Leader's
board presence. Closed City is the first themed area. An unthemed starting area
retains the existing neutral board instead of borrowing the opponent's setting.
Deployment is neutral until the starting-side match state is established.

## Readability And Interaction

The chamber covers each viewport with a centered crop, without stretching.
Darkened HUD bands keep labels legible; the background ignores mouse/touch input.
The square floor is drawn first, then tile seams, territory, frost, objects,
selection/legal actions, figures and labels in their existing order. Territory
tint is reduced only for this material. The seven-by-seven grid, tile hit testing,
zoom, figure scale, AP, movement, combat and win conditions are unchanged.

## Verification

- Final GUT suite: 617/617 tests, 3592 assertions; no script/parse errors.
- New tests cover starter selection, music agreement, turn stability, reversed
  squads, neutral fallback, texture loading, cover crop bounds and input pass-through.
- Native captures inspected at 1440x960, 390x844 and 844x390 under `qa/`.
- `git diff --check` passes.
- Existing GUT orphan/RID leak warnings and the local shader-cache permission
  warning remain; these are not claims of a warning-free engine run.
- Web export and browser end-to-end tests were not run in this delivery.

Reproduce native screenshots by running the normal Godot renderer with project
`game` and `res://tests/helpers/closed_city_visual_review.tscn`. This uses the real
game screen with a fixed-seed test match, waits for responsive layout to settle,
saves the screenshots and exits. It is not a generated screenshot or production
debug feature. The scene temporarily selects Orlov to show legal movement markers.

Next artistic decisions: review material brightness, environmental intensity and
frame weight before producing another starting-area theme.
