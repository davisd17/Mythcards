# MythCards Visual Polish Handoff

## Agent Mission

Turn the working Godot prototype into a visually engaging tactical board game without
changing its rules. The target experience is an **occult tactical diorama**: a physical,
valuable-looking board where the figures are the focus, faction identity is immediate,
and important game states are communicated with light, shape, depth, and motion.

This document contains the overall direction and the implementation instructions for
Phase 1. Complete Phase 1 end to end before beginning later animation or HUD work.

## Product Context

- Engine: Godot 4.7.x, GDScript.
- Platform priority: mobile first, with desktop support.
- Board: 7x7 tactical grid.
- Current roster: seven Closed City figures and seven Flood Survivors figures.
- Current state: gameplay, board input, character figures, card inspection, and web
  export work. The presentation is readable but still resembles a functional prototype.
- Primary visual assets: transparent normalized figures in
  `game/assets/figures/<character-id>/default.png`.
- Existing presentation contract: `LLD-presentation.md`.

## Core Visual Direction

### Experience Goal

The player should feel that they are moving rare figures across an ancient instrument
that has been rebuilt by two incompatible civilizations. The interface should support
the board instead of competing with it.

### Visual Hierarchy

Use this priority order:

1. Selected character and immediate legal actions.
2. Other characters and dangerous targets.
3. Board center, placed objects, terrain, and faction territory.
4. Turn/AP information and primary command.
5. Detailed card text and secondary status information.

### Faction Language

**Closed City**

- Charcoal industrial metal, frozen concrete, cold white light.
- Restrained warning red and instrument green.
- Fine frost, pressure seals, conduit lines, and analog registration marks.
- Avoid broad solid-red surfaces or prominent state insignia.

**Flood Survivors**

- Black submerged stone, ivory shell, aged bronze, deep teal.
- Restrained cyan ley-line light and subtle wet reflections.
- Engraved geometry, tide channels, shell inlays, and disciplined ritual structure.
- Avoid making the faction uniformly blue or covering the board in bright cyan glow.

### Shared Rules

- Preserve tactile, realistic materials. Do not switch to flat neon UI styling.
- Preserve strong contrast at a physical mobile-game scale.
- Use color plus shape or pattern for all important states.
- Keep light effects contained. Effects must not obscure faces, silhouettes, tile
  occupancy, HP, or target markers.
- Do not add decorative cards inside cards, oversized marketing headings, or explanatory
  text inside the game.
- Do not add paid assets or a new rendering framework for this phase.

## Long-Term Visual Roadmap

### Phase 1: Board And Figure Staging

Make the figures dominant, give the board physical material, establish faction zones,
and replace prototype highlights with clear engraved markers. This is the scope of the
current assignment.

### Phase 2: Action Feedback

Add short movement, attack, impact, shield, damage, defeat, and level-up animations.
Animations should normally complete in 150-450 ms and must never delay rules resolution.

### Phase 3: HUD And Card Moments

Reduce inspector weight, improve turn hierarchy, and give relic/event draws a brief
center-stage reveal before they dock into the HUD.

### Phase 4: Atmosphere And Audio

Add restrained frost drift, water-caustic motion, convergence ambience, lightweight
sound effects, and optional haptic feedback. These must remain subtle and performant.

## Phase 1 Objective

Rework the board presentation so that a first-time viewer immediately notices the
characters, understands the two factions, sees which piece is selected, and can identify
legal movement and attack targets without reading instructions.

Phase 1 is complete only when the board looks intentional at mobile and desktop sizes,
all existing gameplay still works, and screenshots demonstrate the improvement.

## Phase 1 Technical Scope

### Primary Files

- `game/scripts/ui/game_board_view.gd`
- `game/scripts/ui/game_screen.gd` only if layout sizing requires a small adjustment.
- Existing tests under `game/tests/unit/`.
- `e2e/tests/screen.spec.ts` for screenshot coverage.

Do not change gameplay systems, character stats, ability handlers, card data, roster IDs,
win conditions, or action legality.

### 1. Board Stage And Frame

Update `GameBoardView._draw()` so the board feels like a physical artifact.

- Keep the board square and centered.
- Replace the flat outer rectangles with a restrained layered frame:
  - dark exterior shadow;
  - cold silver/bronze structural edge;
  - narrow inner bevel;
  - subtle corner or registration details.
- Keep cards, labels, and frame details outside playable tile hit areas.
- Use deterministic procedural lines, specks, seams, or cracks. Do not use per-frame
  randomness that flickers whenever `queue_redraw()` runs.
- Maintain sufficient contrast between the board, figures, and target markers.
- Do not load a large board texture when code-native drawing can provide the material.

### 2. Tile Material

Replace the checkerboard-like flat cells with related but distinguishable materials.

- Base tiles should read as dark stone fused with frozen industrial metal.
- Alternate cells may vary slightly in value and texture, but should not resemble a
  traditional chessboard.
- Grid lines should be quiet during idle play and become more visible only through
  interaction markers.
- Add sparse engraved seams or hairline cracks at low opacity.
- Frost terrain must remain immediately recognizable through texture and edge treatment,
  not only a lighter fill color.
- Leak markers, barricades, pylons, and stones must remain readable above the new surface.

### 3. Faction Territory

Redesign the starting rows so they feel embedded into the board.

- Closed City edge: restrained warning-red channels, pressure-seal marks, or instrument
  registration lines over the shared dark material.
- Flood Survivors edge: cyan ley channels, shell/bronze inlay, or tide geometry over the
  shared dark material.
- Keep faction color coverage restrained, approximately 10-20% of the row's visible
  surface. Do not use solid red and teal row fills.
- Territory treatment must not be mistaken for movement or attack highlighting.

### 4. Convergence Center

Make the center tile the board's visual anchor without overpowering the pieces.

- Draw a contained circular convergence aperture combining astrolabe rings, reactor
  geometry, and ancient engraved stone.
- Use two or three nested rings and four restrained cardinal marks.
- Add a slow 2.5-4 second breathing pulse using low-amplitude alpha or radius change.
- The pulse must stop or remain inexpensive when the board is not visible.
- The center must still show occupancy, selection, objects, and legal-action markers.

### 5. Figure Scale And Staging

Update `_draw_full_body_character()` and character draw ordering.

- Increase humanoid visual height from the current prototype treatment to roughly
  95-108% of one tile, including transparent canvas padding.
- Keep feet anchored near the lower interior of the occupied tile.
- Permit heads, crowns, and compact equipment to extend slightly above a tile, but never
  let a figure visually imply occupancy of another square.
- Fit wide mounts by both height and width. VERA-7 and Ahesu should appear substantial,
  but their active silhouette should not exceed approximately 94% of tile width.
- Draw pieces in stable board-depth order, normally back row to front row, so overlapping
  silhouettes remain coherent. Do not depend on dictionary or roster iteration order.
- Preserve the transparent source PNGs. Do not repaint, crop destructively, or generate
  replacement character art during this phase.

### 6. Bases, Shadows, And State

Give every figure a compact physical relationship to its tile.

- Add a soft elliptical contact shadow under each figure.
- Add a thin faction-colored base rim or floor inlay beneath the shadow.
- Add a smaller role-color accent so role identity remains available without dominating
  the figure.
- Selected figure:
  - enlarge by approximately 5-8%;
  - move upward only enough to feel lifted;
  - brighten the base and add an engraved selection ring;
  - keep HP/status text stable so the layout does not jump.
- Spent figure: reduce saturation and brightness modestly. Keep the face and silhouette
  visible; do not cover the whole figure with an opaque dark rectangle.
- Mounted state, level, Ember, HP, and status indicators must remain visible.

### 7. Interaction Markers

Replace full-cell prototype emphasis with marks that look integrated into the board.

- Legal move: a small green floor rune or inset disc centered on the destination.
- Attack target: a red perimeter/crosshair treatment around the occupied tile.
- Pick/ability target: gold corner brackets or a distinct diamond/rune treatment.
- Selected tile: warm pale-gold engraved ring beneath the figure.
- Each state must remain identifiable in grayscale through shape differences.
- Markers must render above tile material and below figures whenever practical.
- Avoid filling an entire cell with saturated color.

### 8. Labels And Readability

- Keep the existing role, HP, level, Ember, and status information functional.
- Reduce label footprint when possible so more of each figure remains visible.
- Maintain a dark backing behind small text, but keep it compact and consistent.
- Do not rename prototype characters or change card-inspector content in this phase.
- Text must remain readable at the current mobile test viewport without overlapping
  neighboring tiles or figures.

### 9. Responsive Layout

Verify at minimum:

- Mobile portrait: 405x720.
- Small mobile portrait: 360x640.
- Desktop landscape: 1280x720.

Requirements:

- The entire 7x7 board remains visible and square.
- No board, header, button, inspector, or text overlap.
- Touch targets remain at least 44 logical pixels where controls permit.
- The board should use the largest practical width without clipping its frame.
- Figure overflow must be clipped only at the exterior board boundary, not at every tile.

## Implementation Guidance

- Extend the current immediate-mode drawing in `game_board_view.gd`; do not rebuild the
  board as 49 decorative scene nodes solely for this polish pass.
- Extract small drawing helpers when they clarify intent, for example:
  `_draw_board_frame`, `_draw_tile_material`, `_draw_faction_inlay`,
  `_draw_center_aperture`, `_draw_piece_base`, and `_draw_move_rune`.
- Keep constants grouped by purpose: material colors, state colors, geometry ratios, and
  animation timings.
- Use `_process(delta)` only for the center pulse or similarly bounded visual time. Avoid
  redrawing unrelated UI at high cost.
- Never derive legal moves, attacks, or statuses in the presentation layer. Continue to
  consume `GameController.highlights()` and current model state.
- Preserve hotseat input, setup placement, mobile taps, and the existing web export.

## Non-Goals For Phase 1

- No new character art or outfits.
- No gameplay or balance changes.
- No roster migration from prototype IDs.
- No animated movement or combat sequences.
- No new card-reveal flow.
- No HUD redesign beyond small sizing adjustments needed to accommodate the improved
  board.
- No new audio, particles, shaders, 3D board, monetization, or entitlement work.
- No broad refactor of the presentation architecture.

## Acceptance Criteria

1. All 14 default figures render on the board without missing textures.
2. Figures are the strongest first visual signal in a gameplay screenshot.
3. Closed City and Flood Survivors starting areas are distinguishable without solid color
   bands.
4. The center reads as a contained convergence aperture and does not obscure occupants.
5. Move, attack, pick, and selection states are distinguishable by shape and color.
6. Selected, spent, mounted, leveled, Ember-carrying, damaged, and status-bearing figures
   remain legible.
7. Wide mounts fit their tiles and do not overlap adjacent occupancy indicators.
8. No UI overlap occurs at 360x640, 405x720, or 1280x720.
9. Board interaction behavior and action legality are unchanged.
10. All Godot unit tests and the click-only Playwright flow pass.
11. Before/after screenshots are saved for mobile and desktop review.

## Verification Procedure

Run from the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File tools\run_game_tests.ps1
powershell -ExecutionPolicy Bypass -File tools\export_web.ps1
powershell -ExecutionPolicy Bypass -File tools\run_e2e.ps1 -SkipExport -g 'deploy, move'
```

Then inspect actual rendered screenshots, not only test output.

- Confirm all 14 figures are nonblank and correctly mapped.
- Confirm selection, move, attack, object, frost, status, and center states.
- Capture mobile portrait and desktop landscape views.
- Check that figures remain readable against every tile type.
- Check that no transparent figure canvas creates unexpected visual alignment.
- Check the browser console and Godot output for missing resources or script errors.

## Required Agent Report

When Phase 1 is complete, report:

- Files changed.
- Visual decisions made and any intentional deviations from this document.
- Before/after screenshots.
- Test, export, and Playwright results.
- Remaining visual risks or viewport-specific compromises.
- Confirmation that gameplay data and rules were not changed.

Do not claim completion based only on passing tests. Visual inspection of the exported
game at the required viewports is mandatory.
