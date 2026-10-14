# LLD: Figure Animation (Visual Polish Phase 5)

| Field | Value |
| --- | --- |
| Source | Designer request 2026-10-14: "the next phase where we add simple animations", which the designer clarified as animating the figures themselves |
| Status | Approved and implemented 2026-10-14 (decisions in Section 7) |
| Builds on | `LLD-board-fx.md` (Phase 2 slides, lunges, hit flashes), `LLD-atmosphere-phase4.md` (Settings) |
| Files | `game/scripts/ui/figure_pose.gd` (new), `board_fx.gd`, `game_board_view.gd`, `game/tests/unit/test_figure_pose.gd` (new) |

## 1. Goal

The figures feel alive: they breathe while standing, hop when they move, wind up before they strike, recoil when hit, and topple when defeated. No new art is needed. Every animation is a transform of the existing single figure image (lift, squash, lean, tilt). As in Phase 2, animations play after the rules have resolved and never delay or decide anything.

## 2. Scope

**In:** the eight animations in Section 3, on the game screen's board.

**Out:** frame-by-frame sprite animation (that needs new art), animated card art, the debug board, and sound changes.

## 3. Animations

Lift is measured in tiles, lean in degrees, and squash as a vertical scale with width preserved. All pivots are at the figure's feet, so the base and shadow stay planted.

| # | Animation | When | Motion | Duration |
| --- | --- | --- | --- | --- |
| 1 | **Idle breathing** | always, while standing | Vertical scale breathes 1.000 → 1.012 with a ±0.6° sway. Each figure has its own phase, so the board doesn't pulse in unison. Mounts breathe slower and deeper. | 2.8–3.6 s loop |
| 2 | **Spent rest** | a figure with no AP left this turn | Idle breathing stops, and the figure settles 1% lower (alongside the existing grey tint). | — |
| 3 | **Selected bob** | the selected figure | A gentle 0.012-tile bob on top of the existing lift. | 1.2 s loop |
| 4 | **Move hop** | during the existing slide | An arc lifts the figure up to 0.10 tile at mid-slide, then a 6% squash on landing that recovers over the last 80 ms. A mounted pair hops as one. | 240 ms (same as the slide) |
| 5 | **Attack wind-up** | replaces the Phase 2 lunge | Lean back 4° away from the target (first 30%), snap forward with the existing 0.16-tile lunge (30–55%), then return. | 260 ms (was 220) |
| 6 | **Hit recoil** | target takes damage > 0 | Leans 6° away from the attacker, springs back, plus the existing red flash and shake. A "Blocked" hit gets a smaller 2° flinch. | 300 ms |
| 7 | **Cast** | a successful ability | Rises 0.05 tile with a 3% stretch, then settles, plus the existing gold ring. | 300 ms |
| 8 | **Level-up** | `character_leveled_up` | Stretches up to 110% and settles with a small overshoot, plus the existing gold rings. | 500 ms |
| 9 | **Defeat topple** | `character_defeated` | The existing red ghost also tips over 25° away from the attacker as it sinks and fades. | 500 ms (same as now) |

Every animation returns the figure exactly to its rest pose within 1 s. Rows 4–9 are each a transform layered over the idle pose.

## 4. Design

- **`FigurePose` (new, pure functions):** `pose(c, now, fx) -> {lift, scale_x, scale_y, lean_deg}`. It combines the idle breathing (from time plus a phase seeded by `instance_id`) with whichever `BoardFx` entries are active for that character. It has no state and draws nothing, so it's fully unit-testable.
- **`BoardFx`:** gains `casts`, `recoils` (with the attacker's direction) and `levels` timers alongside the existing `slides`, `lunges` and `hits`. The lunge becomes the wind-up curve. Ghosts store the attacker's direction for the topple. The same signals as today feed it.
- **`GameBoardView._draw_character`:** applies the pose with `draw_set_transform_matrix(Transform2D(rotation, scale, 0, feet))` around the figure only. The base, the HP pill and the badges stay level and readable. Text never tilts or squashes.
- **Redraw:** the idle loop already redraws at 24 fps (Phase 4) and at full rate while an action plays. No extra cost.
- **Setting:** idle breathing, spent rest and the selected bob follow Menu > Atmosphere, renamed to **"Motion"**. Action animations (rows 4–9) always play, because they show what happened.
- **Portrait-token fallback** (the hidden original 14): gets the same transforms.

## 5. Tests

`test_figure_pose.gd`:
1. Idle is bounded: scale within 1 ± 0.015, lean within ± 0.7°.
2. Two figures are out of phase at the same instant.
3. A spent figure doesn't breathe.
4. The hop peaks mid-slide and is zero at both ends.
5. The wind-up leans away from the target before moving toward it.
6. Recoil leans away from the attacker; a Blocked hit flinches less.
7. Every animation returns exactly to the rest pose within 1 s.
8. With Motion off, idle is flat but action animations still play.
9. Labels and badges never move with the pose; the label rect is unchanged.

The existing board smoke test draws every pose mid-flight. `visual.spec.ts` adds a capture mid-hop and mid-wind-up.

## 6. Open Questions for the Designer

1. Is the idle breathing amplitude right (1.2% height, ±0.6° sway)? It's deliberately subtle. Phase 1 feedback was "too subtle", so I can double it.
2. Should idle be on by default for everyone, or only when Motion is on (the plan: on by default, can be switched off)?
3. Rename the Atmosphere toggle to "Motion" (covering both ambience and idle), or keep two separate toggles?
4. Any animation in Section 3 you'd cut, or one missing (e.g. a staggered "ready" bob from the whole side when its turn starts)?

## 7. Designer Decisions and Implementation Notes (2026-10-14)

1. **Amplitude:** raised from 1.2% to **2% height and ±0.9° sway**. The designer asked "What would Sam say?" Sam's profile isn't saved, so this was judged for the PRD's primary player (a mobile tactics player glancing between moves): noticeable at a glance, never distracting. `[NEED: Sam persona details]` would make this call exact next time.
2. **Default:** idle is on by default.
3. **Toggles:** one toggle. Menu > Atmosphere became **Motion**, covering both the Phase 4 ambience and the idle animation. A saved "Atmosphere: Off" carries over as "Motion: Off".
4. **Ready bob:** added after the rest was running. When a turn starts, that side's figures bob (0.05 tile, 3% stretch, 0.30 s each), rippling left to right 0.05 s per column. It plays whatever the Motion setting, like the other action animations.

Deviations from Sections 3–4:
- Squash and stretch keep volume roughly: width changes by half the height change in the opposite direction (Section 3 had said width is preserved). It reads more naturally.
- A wind-up straight up or down the board crouches instead of leaning, and a recoil straight up or down squashes, since a lean only reads sideways.
- Ghosts topple away from the attacker, or to the right when there's no attacker, such as a Leak.

Tests: `test_figure_pose.gd` (13). GUT 520/520, Playwright 13/13. One full Playwright run had a one-off 60 s timeout in "play Closed City against the AI with clicks" under parallel load. It then passed 10/10 alone and in two further full runs.
