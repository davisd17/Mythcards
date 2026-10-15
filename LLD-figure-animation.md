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

## 8. Next: Phase 6, Art-Driven Attack Wind-Ups (decided 2026-10-14)

The designer wants character-unique, multi-frame attack wind-up art. An art spec for the graphic designer is in `docs/art-specs/attack-windup-spec.html` (open it from a clone; it loads Yuri's figure from `game/assets/figures/`) and published at https://claude.ai/artifact/733oX1LZktxg28BqtVRU7Y. Decisions:

- **Frames (revised after pilot review):** 6 poses per character: Ready 100 ms, Raise 100 ms, Brace 130 ms, Fire 60 ms, Recoil 90 ms, Recover 120 ms (600 ms total). The designer requested six images to reduce choppiness and approved this sequence. Code blends between poses and keeps the Phase 5 lean and lunge. Keep the flash frame brief; do not make the attack slower merely to show more images.
- **Actions:** basic attack only. Abilities keep the procedural cast animation.
- **Facing:** frames are drawn facing screen-right, and the game mirrors them for leftward attacks.
- **Pilot:** Major Yuri Volkov first. The remaining 13 are commissioned after an in-game review.
- **Format:** 512×768 RGBA PNG, with the feet on y = 756 and the body centered on x = 256, matching `default.png`. Files go in `<character-id>/attack-1-ready.png` through `attack-6-recover.png` (2 raise, 3 brace, 4 fire, 5 recoil). The current `prepare_board_figures.py` re-fits every image to its own bounds, which would make the frames jitter, so the import path for these frames must keep the shared anchor. Use the explicit ordered sequence in the art delivery's `registration.json`.
- **Asset bug found:** `a-flood-survivor-ahesu/default.png` contains a stray VERA-7 wheel fragment at its left edge. It widens Ahesu's measured silhouette, so Ahesu is drawn smaller. A clean re-export was requested with Ahesu's frames.

Engine work (wardrobe entries for the frames, frame playback in `FigurePose`, mirroring, fallback to the Phase 5 procedural wind-up when a character has no frames) starts when the pilot art arrives.

### 8A. Implemented: Yuri Volkov pilot (2026-10-15)

The art delivery (`docs/art-specs/yuri-attack-pilot/`) has **six** poses at 600 ms, replacing the spec's four: ready 100, raise 100, brace 130, fire 60, recoil 90, recover 120. Built to the delivery's notes:

- **Data:** Yuri's default outfit in `wardrobe.json` lists the six frames with their holds, and the fire frame is marked `"impact": true`. `FigureCatalog.attack_frames` and `attack_timing` read it: length 0.60 s, impact at 0.33 s. A character with no `attack` list, or a missing frame, keeps the Phase 5 procedural wind-up.
- **One transform:** every frame is drawn with the default figure's rect (scale and foot anchor). The frames are never fitted to their own bounds.
- **Playback:** `FigurePose.frame_layers` holds each pose, then crossfades into the next over the last 40 ms (at most 40% of the hold). It fades in from the idle figure and fades the recover pose back to idle. The lunge step stays and runs over the 600 ms, peaking at 55%, which is the shot. The procedural lean and crouch are off for drawn attacks, because the brace and recoil art carry them.
- **Mirroring:** frames flip when the target is to the attacker's left.
- **Impact timing (presentation only):** everything an art attack causes waits for the impact frame: the target's flash, recoil, damage number or "Blocked", a defeat ghost (the figure stands untinted until then), Embers, level-ups, and the hit, defeat and Ember sounds. The rules have already resolved. A procedural attacker still reacts at once.
- **Smoothness:** attack frames load when the board opens. In the web build, loading them on the first attack stalled a frame long enough to skip the wind-up. The board also advances animations by at most 50 ms per frame.

Tests: `test_attack_frames.gd` (8). GUT 528/528, Playwright 13/13, with `-hit`, `-shot` and `-recoil` captures at 150, 340 and 430 ms into the attack.

Open for designer review:
- `[NEED: designer review]` **Vertical attacks:** the art faces sideways, so against a target straight up or down the board Yuri fires to the right. Options: accept it, add up/down poses to the spec, or face the art toward the target's side of the board.
- `[NEED: designer review]` **The helmet:** the attack frames carry the helmet at the hip while the idle figure holds it under the arm. The 40 ms fade back to idle softens the change; judge it in play.

### 8B. Plan for the remaining 13 (decided 2026-10-15)

The Yuri pilot passed playtesting. Decisions before commissioning the rest:

- **Vertical attacks:** reuse the sideways poses. No up/down art.
- **Props:** a carried item may move when the pose needs it; the artist flags it with the delivery. Yuri's helmet moving to his hip played fine.
- **Outfits (a planned feature):** attack art belongs to the outfit, not the character. Each outfit entry in `wardrobe.json` carries its own six frames. Each character's first delivery becomes its **pose reference**: later outfits re-dress the same six poses (same silhouette, holds and impact), so they cost less and play identically. An outfit without frames uses the procedural wind-up, never another outfit's frames, so a character never changes clothes mid-attack. Outfit files are named `<outfit-id>-attack-N-<pose>.png`. A recolor shader that reuses the default frames is a possible later tier for palette-only outfits. Ruled out: paper-doll clothing layers (they don't suit painted, generated art) and a skeletal rig (a pipeline rebuild).
- **This commission:** default outfits only. Zoya's Aurora Rite and Thalassa-Nekh's Drowned Seraph (their idle images exist but aren't in `wardrobe.json` yet) come in a later outfit pass.
- **Batches:**
  1. Closed City's remaining 6 (Reactor Worker, VERA-7, Irina Karpova, Mikhail Orlov, Elena Morozova, Zoya Miranova), which completes one animated team.
  2. Flood Survivors' 7, including Ahesu's clean figure re-export, with its frames registered against the cleaned figure.

Pipeline for each delivery:
1. Drop the frames into `game/assets/figures/<id>/`.
2. Run `node tools/register_attack_frames.js <id> [outfit] [--holds …]`.
3. Run `tools/run_game_tests.ps1`. `test_attack_art_contract.gd` checks every registered outfit: six poses, exactly one impact on pose 4, the same canvas as the idle figure, the lowest pixel at y = 756 ± 4, and nothing inside the 24 px side and 18 px top margins.

The spec (repo copy and published link) is updated with all of this.
