# MythCards Low-Level Design — Board Visual Polish, Phase 1 (Board and Figure Staging)

**Document Control**

| Field | Value |
| --- | --- |
| Source document(s) | `VISUAL_POLISH_PHASE_1.md` (design handoff, 2026-10-11); LLD-presentation.md (v1 + 9A); HLD 4.12 (presentation layer) |
| Module/flow scope | `GameBoardView` drawing only (`game/scripts/ui/game_board_view.gd`), plus a landscape sizing tweak in `game_screen.gd`. Phase 1 of the visual roadmap. |
| Target stack | Godot 4.7.x, GDScript, immediate-mode `_draw()` |
| Version | 1 |
| Date | 2026-10-11 |
| Status | Implemented and visually verified at 405×720, 360×640, 1280×720 (screenshots in `docs/visual-polish-phase1/`) |
| Prepared by | Drew Davis (designer) / implementation per the handoff |

## 1. Purpose & Scope

This LLD makes the board read as an "occult tactical diorama". The figures dominate, faction territory is embedded in the board, the center is a convergence aperture, and legal actions use engraved markers. Rules, data, and legality are untouched: the view keeps consuming `GameController.highlights()` and model state.

**Out of scope** (later phases, per the handoff): animations (Phase 2), the HUD and card reveal (Phase 3), atmosphere and audio (Phase 4), new art, and any gameplay change.

**Deviations from the handoff, both intended:**
- **Roster ids.** The handoff predates the roster migration (2026-10-07). It says not to migrate ids; the board already uses the new ids, which is what this LLD assumes.
- **Ember progress on the aperture.** Delivering 4 Spirit Embers to the center now wins (designer ruling 2026-10-11, made alongside this work). The aperture shows each team's banked Embers as 4 small notches on its own side of the outer ring, so the board itself shows the objective. These are notches, not text, which respects the "no explanatory text" rule.

## 2. File Layout

```
game/scripts/ui/game_board_view.gd     drawing (this LLD)
game/scripts/ui/game_screen.gd         landscape board sizing only (Section 3.4)
game/tests/unit/test_board_visuals.gd  pure-helper and smoke tests (Section 8)
e2e/tests/visual.spec.ts               screenshots at 405x720, 360x640, 1280x720
docs/visual-polish-phase1/             before/after screenshots for review
```

## 3. Class & Function Specs (`GameBoardView`)

### 3.1 Constants, grouped by purpose

- **Material:** `STONE_A`, `STONE_B` (cell values within ±4% of each other, not a checkerboard), `SEAM`, `SPECK`, `FRAME_EDGE`, `FRAME_BEVEL_LIGHT`, `FRAME_BEVEL_DARK`, `FRAME_SHADOW`, frost colors.
- **Faction:** `CITY_RED` (warning red), `CITY_GREEN` (instrument green), `FLOOD_CYAN` (ley cyan), `FLOOD_BRONZE`.
- **State:** `MOVE`, `ATTACK`, `PICK`, `SELECTED`, `EMBER`.
- **Geometry** (revised after visual review, Section 4.2):
  - `FIGURE_HEIGHT := 0.95`: a standing figure's visible height, in tiles.
  - `FIGURE_MAX_WIDTH := 0.90`.
  - `FEET_LINE := 0.86`: where the lowest visible pixel rests.
  - `MOUNT_MAX_SILHOUETTE := 0.94`: the widest a Mount's visible figure may be, in tiles.
  - `MOUNT_MAX_HEIGHT := 0.92`.
  - `SELECT_SCALE := 1.065`.
  - `SELECT_LIFT := 0.035`.
- **Timing:** `PULSE_PERIOD := 3.2` seconds; `PULSE_FPS := 15` (redraw rate while pulsing).

### 3.2 Methods

| Method | Behavior |
| --- | --- |
| `_draw()` | Order: background → frame (`_draw_board_frame`) → per tile: material, faction inlay, frost, center aperture, objects, markers (move runes, attack perimeters, pick brackets, selection ring) → figures in `draw_order()` → labels. Markers sit above the material and below the figures. |
| `_process(delta)` | While visible, advances `_time` and calls `queue_redraw()` at most `PULSE_FPS` times a second, for the center pulse only. Nothing runs while hidden. |
| `static func draw_order(characters: Array) -> Array` | The live, placed, non-ridden characters sorted back to front by screen row (the top of the screen first, i.e. board `y` descending), then by `x`. Deterministic whatever the roster order. |
| `func figure_rect(c, tile: Rect2, texture: Texture2D, selected: bool) -> Rect2` | The figure's target rect (Section 4.2). |
| `static func pulse(t: float) -> float` | 0..1 breathing value: `0.5 - 0.5 * cos(TAU * t / PULSE_PERIOD)`. |
| `func label_rect(tile: Rect2) -> Rect2` | The fixed tag/HP pill: `Rect2(tile.x + 0.2px, tile.y + 0.79px, 0.6px, 0.17px)`. Identical for selected and unselected figures, so the label never jumps. |
| `_draw_board_frame(board_rect)` | Layered frame (Section 4.1). |
| `_draw_tile_material(pos, rect)` | Stone/metal cell with deterministic specks and seams (Section 4.3). |
| `_draw_faction_inlay(pos, rect)` | Back-row treatment (Section 4.4). |
| `_draw_center_aperture(rect)` | Rings, cardinals, pulse, Ember notches (Section 4.5). |
| `_draw_piece_base(c, rect, selected, spent)` | Shadow, faction rim, role accent, selection ring (Section 4.6). |
| `_draw_move_rune(rect)` / `_draw_attack_perimeter(rect)` / `_draw_brackets(rect)` | Interaction markers (Section 4.7). |

### 3.3 Figure texture bounds

`_silhouette(texture) -> Rect2` returns the opaque region of a figure texture (`Image.get_used_rect()`), cached per texture. Mounts are fitted by it.

### 3.4 `GameScreen` landscape sizing

When the window is wider than it is tall, the board's vertical stretch ratio rises from 2.2 to 4.5, so the board uses the height a desktop window has. Portrait is unchanged.

## 4. Algorithms

### 4.1 Frame

On `board_rect`:
1. A shadow: `grow(16)` filled with `FRAME_SHADOW`, alpha 0.85.
2. The structural edge: `grow(10)` outlined, 3 px, in `FRAME_EDGE` (cold silver-bronze).
3. A bevel at `grow(5)`: top and left lines in `FRAME_BEVEL_LIGHT`, bottom and right in `FRAME_BEVEL_DARK`, 2 px.
4. Registration marks at each corner of `grow(10)`: an L tick 14 px long, plus a 2.5 px rivet at `grow(13)`.

Everything lies outside the tile area, so hit testing is unchanged.

### 4.2 `figure_rect` (revised after visual review)

The first version sized the whole 512×768 canvas to 1.02 tiles. The screenshots showed the visible figures at only about 60% of a tile, because the canvases carry wide faint pixels (glows, cloaks): the opaque area is 80–96% of the canvas height and about 90% of its width. Figures are now sized by their measured silhouette (`sil`, Section 3.3):
1. **Standing figures:** `s = min(FIGURE_HEIGHT * px / sil.h, FIGURE_MAX_WIDTH * px / sil.w)`.
2. **Mounts:** `s = min(MOUNT_MAX_SILHOUETTE * px / sil.w, MOUNT_MAX_HEIGHT * px / sil.h)`.
3. If `selected`: `s *= SELECT_SCALE`, and the feet rise by `SELECT_LIFT * px`.
4. `feet = tile.y + FEET_LINE * px`. The figure is placed so the silhouette's bottom sits on `feet` and its center is on the tile's center: `left = center.x - (sil.x + sil.w/2) * s`, `top = feet - (sil.y + sil.h) * s`, with size = texture size × `s`.

A standing figure's visible body is 0.95 tile; a head can rise about 0.09 tile into the row behind. Draw order keeps that coherent. The name/HP pill (0.865–0.99 of the tile) sits below the feet. The status strip moved to the left edge, beside the figure.

### 4.3 Tile material

1. `seed = (pos.x * 92821 + pos.y * 68917 + 7) & 0x7fffffff`, then a tiny LCG `next = (seed * 1103515245 + 12345) & 0x7fffffff`.
2. Fill with `STONE_A` or `STONE_B` (by `(x + 2y) % 3 == 0`, so it doesn't read as a chessboard).
3. Draw 5 specks: 1 px circles at LCG positions with alpha 0.05–0.10.
4. One seam: a hairline from one LCG edge point to another, alpha 0.07.
5. A quiet grid: a 1 px outline at alpha 0.07.

Nothing is random per frame, so redraws never flicker.

**Frost:** a pale ice fill, plus 3 short diagonal hatch lines and a bright 2 px inner edge, so it stays recognizable by texture, not color alone.

### 4.4 Faction inlay (back rows)

- **Closed City (board row 0, the screen bottom):**
  - two thin warning-red channel lines along the row's outer quarter;
  - a pressure-seal tick at each tile seam;
  - one instrument-green registration dot per tile.
- **Flood Survivors (row 6, the screen top):**
  - two cyan ley lines along the outer quarter;
  - a bronze shell arc (a half-circle) at each tile center;
  - one ivory inlay dot.

Coverage stays around 15% of the row. There are no solid fills, and no green disc or red ring shapes, so the inlay is never mistaken for a marker.

### 4.5 Center aperture

`p = pulse(_time)`.
- **Outer ring:** `r = 0.40px * (1 + 0.02p)`, bronze, alpha 0.55 + 0.25p.
- **Middle ring:** `0.27px`, pale gold.
- **Inner ring:** `0.14px`, ley cyan, alpha 0.35.
- **Cardinal marks:** 4 short marks from 0.30px to 0.40px at N/E/S/W.
- **Ember notches:** 4 per team.
  - Flood Survivors' notches sit on the upper arc (angles 200°–340°), Closed City's on the lower arc (20°–160°).
  - Each notch is a 0.035px dot: `EMBER` when banked (`PlayerState.embers_delivered`), dim bronze otherwise.

Occupants, objects, and markers draw on top.

### 4.6 Piece base

On a flattened ellipse at the feet (`scale(1, 0.34)`):
- a contact shadow (radius 0.30px, alpha 0.6);
- a faction rim (0.25px, 2 px);
- a role accent: a 70° arc at the front of the rim in the role color.

When selected:
- the rim brightens;
- a `SELECTED` engraved ring (0.33px, 3 px) is added, with 4 small ticks.

When spent (no AP left on the active side), the figure is modulated `Color(0.62, 0.62, 0.66, 0.9)`. That modestly lowers brightness and saturation, and the face and silhouette stay visible. There is no rectangle overlay.

### 4.7 Markers

- **Move rune:** a disc at 0.10px, `MOVE` alpha 0.45; a ring at 0.17px, 2 px; and 4 dots at 0.22px.
- **Attack perimeter:** an inset rect outline at 0.06px, 3 px, `ATTACK`; plus 4 crosshair ticks at the edge midpoints.
- **Pick:** gold corner brackets, as before.
- **Selection:** the base ring (Section 4.6).

In grayscale, the shapes are a dot cluster, a square perimeter with ticks, corner brackets, and an ellipse: all distinguishable.

## 5. Data Structures

`var _time := 0.0`, `var _since_redraw := 0.0`, `var _silhouettes := {}` (texture RID → `Rect2`). There's no game data.

## 6. Signal/Payload Specs

None new. The view still listens to nothing directly; GameScreen redraws it.

## 7. Error Handling & Edge Cases

| Case | Behavior |
| --- | --- |
| A figure texture is missing | Falls back to the existing portrait-card token. |
| A texture has no opaque pixels | `_silhouette` returns the full rect. |
| A head overlapping the row above | Draw order (back to front) keeps it coherent; the overlap stays inside the board frame margin. |
| A mounted pair | Drawn once, as the rider, with the rider ring. |
| The center occupied | The aperture still draws under the occupant. |
| The board hidden | `_process` does nothing. |

## 8. Test Plan

`test_board_visuals.gd`:
1. **`draw_order`:** given characters in shuffled roster order, the result is sorted by `y` descending, then `x`, and is the same for any input order.
2. **Humanoid fit:** for a humanoid figure, `figure_rect` height is 0.95–1.08 tiles, and its bottom is within the tile.
3. **Mount fit:** for VERA-7 and Ahesu, the silhouette width ≤ 0.94 tile.
4. **Selected figure:** 5–8% larger and lifted; `label_rect` is identical to the unselected one.
5. **`pulse`:** 0 at t=0, 1 at half a period, within [0, 1] throughout.
6. **Hit testing unchanged:** `tile_rect` → `tile_at` round-trips all 49 tiles.
7. **Smoke:** a screen with selection, moves, an attack target, a Leak, a Stone, frost, a mounted pair, a level badge, an Ember carrier, and statuses draws over several frames with no errors.

Browser (`visual.spec.ts`): the same scripted position at 3 viewports, by real clicks, saved as before/after screenshots. The existing click-only flows must still pass.

## 9. Open Implementation Questions

- `[NEED: designer review]` Ember notches on the aperture (deviation, Section 1).
- True desaturation of spent figures would need a shader. The handoff excludes shaders in Phase 1, so this uses a grayish modulate.

## 10. Traceability

| Section | Handoff section | Acceptance criterion |
| --- | --- | --- |
| 4.1 | 1 Board stage and frame | 2 |
| 4.3 | 2 Tile material | 2, 6 |
| 4.4 | 3 Faction territory | 3 |
| 4.5 | 4 Convergence center | 4 |
| 4.2, 3.2 draw_order | 5 Figure scale and staging | 1, 2, 7 |
| 4.6 | 6 Bases, shadows, and state | 6 |
| 4.7 | 7 Interaction markers | 5 |
| label_rect | 8 Labels and readability | 6, 8 |
| 3.4 | 9 Responsive layout | 8 |

## 11. Next Steps

1. Implement Sections 3–4 in `game_board_view.gd`; the landscape ratio in `game_screen.gd`.
2. Add `test_board_visuals.gd`.
3. Run GUT, the web export, and Playwright; capture the after screenshots; inspect them at all 3 viewports; iterate.
4. Report per the handoff's "Required Agent Report".
