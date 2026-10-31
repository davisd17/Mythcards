# Far North Battlefield: Vera Kargina

Status: artwork and theme registration implemented locally, awaiting user visual
review. Not pushed, not exported to a new game build.

## Direction

Vera Kargina's protected northern village, not VERA-7's Closed City. Frosted
timber, meteor-dark iron, silver ice, red boundary ribbons and amber lamps sit
beneath emerald aurora. An aged circus pavilion and caravan mark the village
edge; a great branching tree and frozen river carry the older northern story.
No people or figures are baked into the environment.

The board is quiet frostbound stone/river ice, with meteor iron, root-carved
timber and muted red-cord trim. The raster has no grid, center objective, labels,
legal-move markers or gameplay objects; the engine continues drawing those.
No prominent state emblems or invented readable northern script.

## Assets

- `game/assets/boards/far-north/boundary-village-v1.png`: full-screen background.
- `game/assets/boards/far-north/frostbound-stone-v1.png`: square surface and border.
- `PROMPTS.md`: exact built-in ImageGen prompts and reference provenance.
- `qa/far-north-desktop.png`: native 1440x960 screenshot.
- `qa/far-north-mobile.png`: native 390x844 screenshot.
- `qa/far-north-landscape.png`: native 844x390 screenshot.

Generated via built-in ImageGen, with no paid API fallback. Approved Vera card v3
and Deep North Circus Arrives event v2 supplied the background's visual language.
Existing card, character, attack and music assets are untouched.

## Selection And Scope

`BattlefieldTheme.THEMES` registers the Far North sub-area. The theme follows
the starting side's Leader for the entire match, using the existing same
starting-leader rule as environment/music selection. Ordinary turn changes do
not replace the background. Closed City and Flood Survivors remain unchanged;
unregistered sub-areas retain the neutral fallback.

Vera Kargina exists in story/card drafts, but the current playable team catalog
does not yet contain her or a complete Far North squad. This delivery does not
invent stats, add a team, promote drafts or turn VERA-7 into a Leader. Once the
playable roster supplies a Leader with `sub_area: "Far North"`, this registration
selects the theme automatically when that side starts. Until then, it can be
reviewed through the isolated art fixture below, not normal roster selection.

The fixture uses the existing roster and reparses a private copy of its Leader's
card data with Far North as the sub-area. Shared ContentDB records are untouched.
Its header explicitly says Art Preview: the displayed pieces are not proposed
Far North character art. No test fixture data is saved into the playable roster.

## Verification

683 tests / 4,887 assertions passed. Includes loading all three themes' assets,
cover crops, starting-side selection, persistent theme across turns, and all
49 tile rectangles and hit targets remaining unchanged. Existing shutdown
RID/ObjectDB and orphan-UI warnings remain; no test or script failures.

Native desktop/phone/landscape captures were inspected for textured board,
visible environment, intact frame, readable labels and HUD separation. The
existing nine-slice border, center-symbol layer, cover crop, dark background
wash and HUD scrims are reused. No game rules, grid geometry, figure scale,
camera controls or click handling changed. Web export was not run.

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_game_tests.ps1
& (./tools/find_godot.ps1) --path game --audio-driver Dummy `
  --log-file "$PWD/build/far-north-review.log" `
  res://tests/helpers/closed_city_visual_review.tscn -- --far-north
```

The full test suite needs temporary Godot user-data file access for existing
online-session tests. The helper retains its older filename for compatibility;
the flag chooses the new theme fixture.
