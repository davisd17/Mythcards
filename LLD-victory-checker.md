# MythCards Low-Level Design — Victory Checker (`VictoryChecker`)

**Document Control**

| Field | Value |
| --- | --- |
| Source document(s) | HLD.md (v3, 2026-09-07), BRD.md (v3, 2026-08-14), LLD-content-board.md (v3), LLD-match-setup.md (v4), LLD-rules-engine.md (v5), LLD-combat-mount.md (v5), LLD-ability-system.md (v1) |
| Module/flow scope | Victory Checker (`VictoryChecker` — HLD Section 4.10). HLD build-order step 13. |
| Target stack | Godot 4.7.x, GDScript |
| Version | 1 |
| Date | 2026-09-08 |
| Status | Draft |
| Prepared by | Drew Davis (solo developer/designer, acting as own PM) |

## 1. Purpose & Scope

This LLD specs the two victory conditions: the end-of-turn Hero-capture check (BR-034 — a positional, chess-checkmate-style condition, deliberately reusing `BoardModel.get_legal_moves()` rather than a second implementation, per HLD-R-002) and continuous army-defeat detection (BR-035). It replaces the no-op stub `TurnManager.end_turn()` has called since LLD-match-setup.md's Section 11 Next Steps item 2 (that LLD scaffolded an empty placeholder specifically so `TurnManager` wouldn't crash before this module existed).

**Explicitly out of scope**: how victory/defeat is displayed (presentation layer, a later LLD); the `DebugPanel`'s own consumption of `hero_capture_checked` (LLD-09).

## 2. File Layout

```
D:\mythcards\
├── scripts/
│   └── autoloads/
│       └── victory_checker.gd     (new — autoload name: VictoryChecker)
└── tests/
    └── unit/
        └── test_victory_checker.gd (new — extends GutTest)
```

## 3. Class & Function Specs

### 3.1 `VictoryChecker` (autoload, `res://scripts/autoloads/victory_checker.gd`)

```gdscript
extends Node
# Autoload name: VictoryChecker

func _ready() -> void:
    EventBus.character_defeated.connect(_on_character_defeated)
    # Army defeat (BR-035) is checked reactively on every defeat, not only at end of turn --
    # unlike Hero capture, nothing in BR-035's wording ties it to turn boundaries, and waiting
    # until end-of-turn would let a match continue for a full extra turn after one side's last
    # character falls. Hero capture (check_hero_capture, below) remains end-of-turn-only
    # because BR-034 explicitly scopes it that way ("at the end of a turn taken by that Hero's
    # own controller").

func check_hero_capture(player_id: String) -> void
    # Replaces the no-op placeholder TurnManager.end_turn() has called since LLD-match-setup.md
    # Section 11 item 2. See Section 4.1 for the exact algorithm.

func _on_character_defeated(character_id: String, defeated_by_id: String, cause: String) -> void
    # See Section 4.2.

func _end_match(winner_id: String, condition: String) -> void
    # GameState.match_state.winner_id = winner_id; win_condition = condition; phase = "ended".
    # EventBus.match_ended.emit(winner_id, condition). The single shared path both victory
    # conditions funnel through, so "match over" state is set consistently regardless of cause.
```
Satisfies HLD Section 4.10 / BRD FR-060–FR-065, BR-034, BR-034A, BR-035.

## 4. Algorithms

### 4.1 `check_hero_capture`

1. If `GameState.match_state.phase == "ended"`, return immediately — guards against the (currently impossible but cheap-to-guard) case where an army-defeat check (Section 4.2) already ended the match earlier in the same `end_turn` call chain, before `TurnManager` reaches its own post-call `phase == "ended"` short-circuit (LLD-match-setup.md Section 3.8).
2. `var player := GameState.match_state.get_player(player_id)`.
3. `var hero := player.characters.filter(c -> c.data.type == "Hero")[0]` (BR-001/BR-005 guarantee exactly one).
4. If `hero.current_hp <= 0`: return — a Hero already defeated via combat (BR-034A) does not get a "no legal move" check; it has already been removed from the board (LLD-combat-mount.md `_handle_defeat`) and is handled entirely by the army-defeat path (Section 4.2) if its side is now fully eliminated. This is the concrete enforcement of AS-009/BR-034A's decoupling of HP-defeat from Hero-capture.
5. Determine the Hero's *effective* mover, exactly as `RulesEngine._handle_move` does (LLD-rules-engine.md v5, Section 4.2 step 1) — reusing the identical mounted-vs-unmounted branch, since HLD-R-002 specifically warns against a second, potentially-drifted implementation of movement legality: if `hero.is_mounted_rider`: `move_budget = MountSystem.get_effective_move_stat(hero)`, `pattern = MountSystem.get_effective_movement_pattern(hero)`; else: `move_budget = hero.get_effective_move()`, `pattern = AbilitySystem.get_movement_pattern(hero)`.
6. `predicate := AbilitySystem.get_movement_passable_predicate(<mover>)`, `object_predicate := AbilitySystem.get_movement_object_passable_predicate(<mover>)` — same `mover` resolution as step 5 (the Mount's handler if mounted, else the Hero's own).
7. `var legal := board.get_legal_moves(hero.position, move_budget, pattern, predicate, object_predicate)`.
8. `EventBus.hero_capture_checked.emit(player_id, not legal.is_empty())` (HLD Section 5.3 — diagnostic only, per that signal's own listed purpose).
9. If `legal.is_empty()`: `_end_match(GameState.match_state.get_other_player_id(player_id), "hero_capture")` (BR-034 — captured Hero's *opponent* wins).

### 4.2 `_on_character_defeated` (army defeat)

1. `var defeated := GameState.match_state.find_character(character_id)`; if `null`, return.
2. `var side := GameState.match_state.get_player(defeated.player_id)`.
3. `var all_defeated := true`; for each `c in side.characters`: if `c.current_hp > 0`: `all_defeated = false`; break.
4. If `all_defeated` and `GameState.match_state.phase != "ended"`: `_end_match(GameState.match_state.get_other_player_id(defeated.player_id), "army_defeat")` (BR-035).

This runs for *every* `character_defeated` emission, including the `"mount_propagation"`-cause second emission (LLD-combat-mount.md v5, Section 4.3) — correctly, since a mount's propagated defeat still counts toward "all characters on one side removed" the same as any other defeat; `VictoryChecker`, unlike `LevelingSystem` (LLD-leveling.md Section 4.4), has no reason to treat the two causes differently, since army defeat cares about the *count* of remaining characters, not who gets credit for a kill.

## 5. Data Structures

No new persistent data structures — reads `MatchState`/`PlayerState`/`CharacterInstance` fields already specced (LLD-match-setup.md), and writes `MatchState.winner_id`/`win_condition`/`phase`.

## 6. Signal/Payload Specs

| Signal | Emitted by | Payload | Invariant |
| --- | --- | --- | --- |
| `hero_capture_checked(player_id: String, has_legal_move: bool)` | `check_hero_capture` | id, bool | Emitted every time the check runs (once per `end_turn`, unless short-circuited by step 1/4) — including when the Hero *does* have a legal move, per HLD's own "diagnostic only" framing. |
| `match_ended(winner_id: String, condition: String)` | `_end_match` | id, `"hero_capture"` \| `"army_defeat"` | Emitted exactly once per match — both call sites (Section 4.1 step 9, Section 4.2 step 4) guard against firing after `phase` is already `"ended"`. |

## 7. Error Handling & Edge Cases

| Scenario | Expected behavior | Source |
| --- | --- | --- |
| Both Hero-capture and army-defeat conditions become true in the same instant (e.g. a Hero's own defeat, via `character_defeated`, also happens to be the last character on that side) | Army defeat (Section 4.2) fires first, reactively, at the moment of the defeat itself — `check_hero_capture` (Section 4.1) later short-circuits at step 1 since `phase` is already `"ended"` by the time `TurnManager.end_turn` calls it. Army defeat effectively takes priority whenever both would apply, which matches BR-034A's intent that HP-defeat is handled through the normal defeat/army-defeat path, not hero-capture | BR-034A |
| `check_hero_capture` called for a player whose Hero was defeated earlier in the match but the match somehow didn't already end (a contradiction under this LLD's own invariants — army defeat should have fired already) | Step 4's early return still makes this safe (no crash, no incorrect win), even though it should be unreachable in practice | Section 4.1 |
| A mounted Hero's `is_mounted_rider` state changes between when `end_turn` is invoked and when `check_hero_capture` reads it | Cannot happen — both run synchronously within the same `RulesEngine.request_action("end_turn", ...)` call, with no intervening action possible (single-threaded hotseat flow, same assumption LLD-combat-mount.md Section 7 already documents for dismount) | NFR-020 |
| `get_other_player_id` is asked for a `player_id` that isn't `"p1"`/`"p2"` | Asserts (LLD-match-setup.md Section 3.5) — a caller bug, not a reachable state given `MatchState.players` is fixed at exactly two entries | Section 3.5 |

## 8. Test Plan

Unit tests use **GUT**. `BoardModel`/`AbilitySystem`/`MountSystem` are doubled to control the "legal moves" result directly rather than constructing full board scenarios for every case.

| Case | Given | When | Then | BRD ID |
| --- | --- | --- | --- | --- |
| C1 | Doubled `board.get_legal_moves` returns a non-empty array for P1's Hero | `check_hero_capture("p1")` | `hero_capture_checked("p1", true)` fires; `match_ended` does NOT fire | BR-034 |
| C2 | Doubled `board.get_legal_moves` returns `[]` | `check_hero_capture("p1")` | `hero_capture_checked("p1", false)` fires; `match_ended("p2", "hero_capture")` fires; `phase == "ended"` | BR-034 |
| C3 | P1's Hero `current_hp == 0` (already defeated via combat) | `check_hero_capture("p1")` | No signals fire; no legal-moves query even attempted (doubled `get_legal_moves` never called) | BR-034A, AS-009 |
| C4 | P1 has one character remaining with `current_hp > 0` | `character_defeated` fires for a different P1 character | No `match_ended` | BR-035 |
| C5 | P1's last remaining character is defeated | `character_defeated` fires | `match_ended("p2", "army_defeat")` fires | BR-035 |
| C6 | Match already `phase == "ended"` | `check_hero_capture(...)` called again | No-op, no duplicate `match_ended` | Section 4.1 |
| C7 | Hero is a mounted rider, doubled `MountSystem.get_effective_move_stat`/`get_effective_movement_pattern` return specific values | `check_hero_capture(...)` | `board.get_legal_moves` called with those mount-derived values, not the Hero's own | BR-014, HLD-R-002 |

## 9. Open Implementation Questions

- **No open questions specific to this module** — its logic is fully determined by BR-034/BR-034A/BR-035 and the already-established `get_legal_moves`/mount-aware-movement contracts from earlier LLDs. The only genuine risk (HLD-R-002: a drifted second movement-legality implementation) is explicitly avoided by Section 4.1 steps 5–7 mirroring `RulesEngine._handle_move` exactly.

## 10. Traceability

| LLD Section | HLD Section | BRD/PRD IDs |
| --- | --- | --- |
| 4.1 `check_hero_capture` | HLD 4.10, Flow C, HLD-R-002 | FR-060, FR-060A, FR-061, BR-034 |
| 4.2 Army defeat | HLD 4.10 | FR-062, FR-063, BR-035 |
| 3.1 `_end_match` | HLD 4.10 | FR-061A, FR-064, FR-065, BR-034A |

## 11. Next Steps

1. Add `scripts/autoloads/victory_checker.gd` (Section 3.1); replace the no-op stub referenced by `TurnManager.end_turn()` (LLD-match-setup.md Section 11 item 2) with this real implementation.
2. Write `tests/unit/test_victory_checker.gd`; confirm C1–C7.
3. Once the presentation layer (a later LLD) exists, verify it correctly distinguishes a `"hero_capture"` win from an `"army_defeat"` win in its victory/defeat UI, per the BRD's own acceptance criteria (Section 16).
