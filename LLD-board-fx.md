# LLD: Board Action Feedback (Visual Polish Phase 2)

| Field | Value |
| --- | --- |
| Source | `VISUAL_POLISH_PHASE_1.md` (Long-Term Visual Roadmap, Phase 2) |
| Status | Implemented 2026-10-11 |
| Files | `game/scripts/ui/board_fx.gd` (new), `game/scripts/ui/game_board_view.gd`, `game/tests/unit/test_board_fx.gd`, `e2e/tests/visual.spec.ts` |

## 1. Design

`BoardFx` (RefCounted, owned by `GameBoardView`) listens to EventBus. Every signal fires after the model has already changed, so animations can't delay, block, or decide rules. They only offset, tint, or decorate what the view already draws. `BoardFx` keeps its own clock, advanced by the view's `_process` (and by tests through `advance()`). The view redraws every frame while an effect is active, and at the Phase 1 pulse rate (15 fps) otherwise.

## 2. Effects

| Signal | Effect | Duration |
| --- | --- | --- |
| `character_moved`, `character_repositioned` (push, pull, mount, dismount) | The figure slides from its old tile with an ease-out. A mounted pair slides whichever id moved. | 240 ms |
| `character_repositioned` cause `return` | A gold ring appears (it didn't travel). | 400 ms |
| `attack_resolved` | The attacker lunges 0.16 tile toward the target and back. | 220 ms |
| `damage_resolved` | Damage > 0: the target flashes red and shakes, and `-N` floats up. Damage 0: `Blocked` floats up in cyan. | 320 / 750 ms |
| `object_attacked` | A burst plus `-N`, or `Destroyed`. | 400 / 750 ms |
| `status_added` (shield only) | A cyan ring expands. | 400 ms |
| `action_resolved` ability, success | A gold cast ring on the caster. | 400 ms |
| `leak_triggered` | A green ring. | 400 ms |
| `character_defeated` | A red ghost of the figure sinks and fades, plus a burst. No ghost for a Mount falling under its rider. | 500 ms |
| `character_leveled_up` | Two gold rings plus `LEVEL N` rising. | 850 ms |
| `spirit_ember_picked_up` / `delivered` | An orange burst plus `+Ember` / `Banked`. | 600 / 840 ms |

Everything finishes within 1 s, under the AI's 0.6 s step plus reading time. Most effects stay within the roadmap's 150–450 ms band. Text effects run longer so they can be read.

## 3. Tests

- `test_board_fx.gd`: slide start, midpoint and settle; a real move action starts a slide; mounted pairs; hit and number; Blocked; the lunge; ghosts, with no ghost for a Mount under its rider; level, shield and Ember flourishes; nothing lingers past 1 s; the model is never touched.
- `test_board_visuals.gd`: the smoke test draws with effects mid-flight.
- `visual.spec.ts`: a `-hit` screenshot 90 ms into an attack. Copies are in `docs/visual-polish-phase2/`.

## 4. Open

- `[NEED: designer review]` Feel and timing in hands-on play: is the slide too fast or slow, and are the numbers readable on a phone?
- Not in scope: sound, screen shake, particles, and a reduce-motion setting (Phase 4 or later).
