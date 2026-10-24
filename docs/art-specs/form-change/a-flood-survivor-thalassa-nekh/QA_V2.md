# Seraph Manifestation V2 Verification

2026-10-24. Implemented in local Godot source; not pushed or web-exported.

## Automated

- `tools/run_game_tests.ps1`: 611/611 tests passed.
- Subsequent GUT run after shoulder-offset correction: 611/611 tests, 3557 asserts.
- Five focused manifestation tests cover successful/failed/repeated activation,
  existing bonuses, final visibility with a fresh presentation clock, impact
  intensity, reduced motion, texture alpha and unchanged human geometry.
- `git diff --check`: passed.
- Existing suite reports 20 orphan CanvasItems and exit-time RID/ObjectDB leaks;
  the suite still passes. Local rendering also warns that user shader cache is
  unavailable. No script/parse errors occurred.

## Native Render Review

Run Godot with project `game` and scene
`res://tests/helpers/seraph_visual_review.tscn` (normal renderer, not headless).
This isolated fixture scene writes screenshots to this directory's `qa/` folder
and exits. It does not change production match state or add debug player actions.

Inspected: 1280 x 960 idle before/after, left/right impact, back-row clearance,
and 390 x 844 board. The fixture asserts identical human figure rectangles before
and after the form flag. Seraph reads behind Nekh without a rectangular backdrop;
at the back edge the compact entity offsets to an inner shoulder so its face is
not hidden by her. Human figure size and original clothing remain unchanged.

## Boundaries

The entity is a reusable translucent layer, not a new six-pose body sequence.
Attack emphasis currently uses intensity, not a separately swinging spirit arm.
Shared claim-art playback remains a separate outstanding integration task.
No claim of complete save/load or network reconnect testing: a fresh view's
presentation correctly derives final form from the existing model flag.
Final board-scale artistic approval remains with the user.
