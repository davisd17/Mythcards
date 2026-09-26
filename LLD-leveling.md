# MythCards Low-Level Design — Leveling & Spirit Ember (`LevelingSystem`)

**Document Control**

| Field | Value |
| --- | --- |
| Source document(s) | HLD.md (v3, 2026-09-07), BRD.md (v3, 2026-08-14), LLD-content-board.md (v3), LLD-match-setup.md (v3), LLD-rules-engine.md (v5), LLD-combat-mount.md (v5), LLD-ability-system.md (v1) |
| Module/flow scope | Leveling & Spirit Ember (`LevelingSystem` — HLD Section 4.8). HLD build-order step 11. |
| Target stack | Godot 4.7.x, GDScript |
| Version | 2 (designer review 2026-09-25: defeating a mounted pair now grants two Spirit Embers, so `CharacterInstance.has_spirit_ember: bool` becomes `spirit_ember_count: int` and Level 3 delivery spends one Ember rather than clearing the flag) |
| Date | 2026-09-25 |
| Status | Draft |
| Prepared by | Drew Davis (solo developer/designer, acting as own PM) |

## 1. Purpose & Scope

This LLD specs level tracking (1–3), Level 2 detection (opponent-edge crossing), Spirit Ember pickup (automatic on defeat, BR-023A), and Level 3 detection (Level 2 + holding an Ember + reaching the center tile), per HLD Flow D. It consumes `CombatResolver`'s `character_defeated` signal (LLD-combat-mount.md v5, which added the `defeated_by_id`/`cause` fields specifically for this module's benefit) and delegates the actual rules-text application of a level-up to `AbilitySystem.apply_level_up_effects()` (LLD-ability-system.md Section 3.3, Section 3.5) — this LLD decides *when* a level-up happens, `AbilitySystem` decides *what* it does to the character's stats/capabilities.

**Explicitly out of scope**: the content of L2/L3 upgrades themselves (per-character stat/ability changes — `AbilitySystem`, LLD-05); how Spirit Ember possession is displayed (presentation layer, a later LLD).

## 2. File Layout

```
D:\mythcards\
├── scripts/
│   └── systems/
│       └── leveling_system.gd     (new — class_name LevelingSystem)
└── tests/
    └── unit/
        └── test_leveling_system.gd (new — extends GutTest)
```

Plain `class_name`, not an autoload (HLD Section 5.1), instantiated and held by `RulesEngine` alongside `CombatResolver`/`MountSystem`/`AbilitySystem`.

## 3. Class & Function Specs

### 3.1 `LevelingSystem` (`res://scripts/systems/leveling_system.gd`)

```gdscript
class_name LevelingSystem
extends RefCounted

var board: BoardModel
var ability_system: AbilitySystem   # injected at construction, for apply_level_up_effects()

func _init(p_board: BoardModel, p_ability_system: AbilitySystem) -> void:
    board = p_board
    ability_system = p_ability_system
    EventBus.character_moved.connect(_on_character_moved)
    EventBus.character_defeated.connect(_on_character_defeated)
    EventBus.character_leveled_up.connect(_on_character_leveled_up)
    # Same "long-lived RefCounted as EventBus listener" pattern AbilitySystem already
    # establishes (LLD-ability-system.md Section 3.3, Section 9) -- not a new architectural
    # precedent, just the second module to use it.

func _check_level_2(character: CharacterInstance) -> void
    # See Section 4.1.
func _check_level_3(character: CharacterInstance) -> void
    # See Section 4.2.
func _level_up(character: CharacterInstance, new_level: int) -> void
    # character.level = new_level; ability_system.apply_level_up_effects(character, new_level);
    # EventBus.character_leveled_up.emit(character.instance_id, new_level). The single shared
    # path every level-up goes through, so FR-050 (never exceed 3) and the AbilitySystem
    # delegation happen exactly once, not duplicated between the L2 and L3 call sites.

func _on_character_moved(character_id: String, from: Vector2i, to: Vector2i) -> void
    # See Section 4.3 -- also checks the OTHER half of a mounted pair, since both halves share
    # a position while mounted but only the mover's own id is in this signal's payload.
func _on_character_defeated(character_id: String, defeated_by_id: String, cause: String) -> void
    # See Section 4.4.
func _on_character_leveled_up(character_id: String, new_level: int) -> void
    # See Section 4.5 -- handles HLD Flow D step 3 (reaching Level 2 while already on the
    # center tile holding an Ember).
```
Satisfies HLD Section 4.8 / BRD FR-046–FR-052, BR-022–BR-026, BR-023A.

## 4. Algorithms

### 4.1 `_check_level_2`

1. If `character.level != 1`, return (FR-050 — only a Level 1 character can reach Level 2; also naturally prevents re-triggering on a character already past it).
2. `var opponent_side := 2 if character.player_id == "p1" else 1`.
3. If `character.position.y == board.get_edge_row(opponent_side)` (LLD-content-board.md Section 3.6 — this is the *opponent's* back row from the mover's perspective, per BR-022 "crossing to the opponent's board edge"): call `_level_up(character, 2)`.

### 4.2 `_check_level_3`

1. If `character.level != 2` or `character.spirit_ember_count < 1`, return.
2. If `not board.is_center(character.position)`, return.
3. `character.spirit_ember_count -= 1` (BR-023 — reaching the center square while carrying an Ember *spends one* to complete the level-up). Since 2026-09-25 a character can hold more than one Ember (a mounted-pair kill grants two, Section 4.4), so delivery decrements rather than clearing: any surplus Embers stay with the carrier. They have no further use for that character — it is already Level 3, the roster's cap — but they are not destroyed, so a future card or mode that consumes Embers for anything else inherits a coherent count. Nothing in the current prototype reads a count above `0` except the status badge (LLD-presentation.md).
4. `_level_up(character, 3)`.
5. `EventBus.spirit_ember_delivered.emit(character.instance_id)` — emitted *after* `_level_up`'s own `character_leveled_up` (step 4), matching HLD's signal map ordering intent (`spirit_ember_delivered`'s own listed listener is `LevelingSystem` itself, "triggers L3" — already accomplished by this function directly rather than needing a self-listen loop).

### 4.3 `_on_character_moved`

1. `var character := GameState.match_state.find_character(character_id)`.
2. `_check_level_2(character)`; `_check_level_3(character)` (HLD Flow D step 1 and the movement branch of step 3).
3. If `character.mounted_with_id != ""`: `var partner := GameState.match_state.find_character(character.mounted_with_id)`; `_check_level_2(partner)`; `_check_level_3(partner)`. This covers a Mount's own leveling while it is currently being ridden — `RulesEngine._handle_move` (LLD-rules-engine.md v5) only emits `character_moved` for the rider's `instance_id`, but keeps the Mount's `position` in sync (LLD-combat-mount.md `mount()`/movement handling), so the Mount's edge-crossing/center-delivery would otherwise never be checked. Both `White Siberian Tiger` and `Manta Glider` have real L2/L3 upgrade text (BRD Section 12), so this is not a hypothetical case.

### 4.4 `_on_character_defeated`

1. **Every** `character_defeated` grants an Ember, for both the `"direct"` and the `"mount_propagation"` cause — designer ruling, 2026-09-25 (BR-023A): defeating a rider and its Mount in one attack yields **two** Spirit Embers, because two characters were defeated. There is no `cause` filter here; the tag is retained in the payload for other listeners and for debug output.
2. `var attacker := GameState.match_state.find_character(defeated_by_id)`; if `null`, return (defensive — should not happen per LLD-combat-mount.md v5's invariant that `defeated_by_id` is never empty).
3. `attacker.spirit_ember_count += 1`.
4. `EventBus.spirit_ember_picked_up.emit(attacker.instance_id)` — emitted once per Ember granted, so a mounted-pair kill fires it twice in the same call stack (`_handle_defeat` emits `character_defeated` twice, LLD-combat-mount.md Section 4.3). The signal's shape is unchanged; a listener that counts emissions gets the right total, and the presentation layer reads `spirit_ember_count` for the badge rather than counting signals.
5. `_check_level_3(attacker)` — HLD Flow D step 2/3: a character already at Level 2 who happens to already be standing on the center tile at the moment it picks up an Ember completes Level 3 immediately, without needing a further move.

### 4.5 `_on_character_leveled_up`

1. If `new_level != 2`, return (only relevant for the L2-while-already-qualified-for-L3 case).
2. `var character := GameState.match_state.find_character(character_id)`.
3. `_check_level_3(character)` — HLD Flow D step 3's third trigger: reaching Level 2 while already on the center tile already holding an Ember. Relies on Godot's `Signal.emit()` calling connected listeners synchronously (the default, unless connected with `CONNECT_DEFERRED`) so this runs within the same call stack as `_level_up(character, 2)` (Section 4.1 step 3) rather than on some later frame — `LevelingSystem` does not use deferred connections anywhere (Section 9).

## 5. Data Structures

No new persistent data structures — this module reads/writes existing `CharacterInstance` fields (`level`, `spirit_ember_count`, `position`, `mounted_with_id`) already specced in LLD-match-setup.md. One field changed shape on 2026-09-25: `has_spirit_ember: bool` became `spirit_ember_count: int` (default `0`), because a single attack can now yield two Embers. Every reader was updated in the same pass — LLD-match-setup.md (field + construction), HLD Section 6 (`CharacterInstance` row), LLD-presentation.md (badge), LLD-test-bridge.md (serialized state).

## 6. Signal/Payload Specs

| Signal | Emitted by | Payload | Invariant |
| --- | --- | --- | --- |
| `character_leveled_up(character_id: String, new_level: int)` | `LevelingSystem._level_up` | id, `2` or `3` | Emitted exactly once per level-up, after `AbilitySystem.apply_level_up_effects()` has already run (so any listener sees fully-updated stats). |
| `spirit_ember_picked_up(character_id: String)` | `LevelingSystem._on_character_defeated` | id | Emitted once per Ember granted — for every defeat of either cause, so twice for a mounted-pair kill — regardless of whether it also triggers a Level 3 completion. |
| `spirit_ember_delivered(character_id: String)` | `LevelingSystem._check_level_3` | id | Emitted only when Level 3 is actually reached; `character.spirit_ember_count` has already been decremented by one when this fires (Section 4.2 step 3), and may still be `> 0`. |

This module also *listens to* `character_moved`, `character_defeated`, and `character_leveled_up` (Section 3.1) — all pre-existing HLD Section 5.3 signals, no new subscriptions beyond what this LLD itself emits.

## 7. Error Handling & Edge Cases

| Scenario | Expected behavior | Source |
| --- | --- | --- |
| A character is already at Level 3 and moves onto the opponent's edge or the center tile again | No-op — `_check_level_2`/`_check_level_3` both gate on the character's *current* level (`== 1`/`== 2` respectively), so a maxed-out character never re-triggers anything | FR-050 |
| `character_defeated` fires with `cause == "mount_propagation"` | An Ember is granted, exactly as for a `"direct"` defeat (Section 4.4 step 1) — a mounted-pair kill therefore yields two Embers in total (BR-023A, 2026-09-25) | Section 4.4 |
| A character reaches the opponent's edge and the center tile in the same conceptual "turn" but via two separate moves (only possible if MOVE is large enough to cross the whole board, not the case for any current character) | Handled correctly regardless — `_check_level_2` and `_check_level_3` both run on every `character_moved`, independent of how many moves occur | Section 4.3 |
| `GameState.match_state.find_character` returns `null` for `defeated_by_id` | `_on_character_defeated` returns early (Section 4.4 step 2) rather than crashing — should not occur given LLD-combat-mount.md v5's invariant, but defended against anyway since `LevelingSystem` cannot itself verify that invariant holds | NFR-020 |
| Match ends (Hero capture or army defeat) mid-processing of a leveling check | Not specially handled — `VictoryChecker` (LLD-08) is expected to run its own check independently at end-of-turn (LLD-match-setup.md Section 4.2); a level-up completing on the same turn a match ends is not a conflict, since both are just state changes applied before `match_ended` fires | Section 1 |
| BR-025 ("levels reset at end of match") | Not implemented as an explicit reset step — naturally satisfied structurally, since `SetupFlow._build_squad()` (LLD-match-setup.md Section 3.6) always constructs fresh `CharacterInstance`s at `level = 1` for a new match; there is no cross-match character persistence to reset in the first place (HLD Section 8 — no save system at this tier) | BR-025 |

## 8. Test Plan

Unit tests use **GUT**. `AbilitySystem.apply_level_up_effects` is doubled/spied (its own correctness is LLD-05's concern).

| Case | Given | When | Then | BRD ID |
| --- | --- | --- | --- | --- |
| C1 | P1 character at Level 1, moves to `board.get_edge_row(2)` (P2's back row = P1's opponent edge) | `character_moved` fires | `character.level == 2`; doubled `apply_level_up_effects(character, 2)` called; `character_leveled_up` fires | BR-022 |
| C2 | Same character now at Level 2, not holding an Ember, moves to the center tile | `character_moved` fires | Level remains `2` (no Ember, no L3) | BR-023 |
| C3 | An attacker defeats an enemy (`cause == "direct"`) | `character_defeated` fires | Attacker's `spirit_ember_count == 1`; `spirit_ember_picked_up` fires once for the attacker | BR-023A |
| C4 | An attacker defeats a mounted pair (one `"direct"` + one `"mount_propagation"` emission, same attacker) | Both `character_defeated` emissions fire | Attacker's `spirit_ember_count == 2`; `spirit_ember_picked_up` fires twice | BR-023A |
| C4A | The same attacker, already at Level 2, is standing on the center tile when it defeats a mounted pair | Both emissions fire | Attacker reaches Level 3 on the first Ember and keeps the second (`spirit_ember_count == 1` afterward); `spirit_ember_delivered` fires exactly once | Section 4.2 |
| C5 | Attacker already Level 2, already standing on the center tile, then defeats an enemy | `character_defeated` fires | Attacker reaches Level 3 immediately (`spirit_ember_delivered` fires) without needing to move afterward | HLD Flow D step 2 |
| C6 | Character Level 2, holding one Ember, moves onto the center tile | `character_moved` fires | Level becomes `3`; `spirit_ember_count == 0` afterward; `spirit_ember_delivered` fires | BR-023 |
| C7 | Character reaches Level 2 (edge-crossing) while already standing on the center tile and already holding an Ember | `character_moved` fires (triggering `_check_level_2` then, via `character_leveled_up`, `_check_level_3`) | Character ends at Level 3 in the same event-processing pass | HLD Flow D step 3 |
| C8 | A mounted Mount (e.g. `a-glider`, Level 1) is carried across the opponent's edge by its rider's move | `character_moved` fires for the rider | The Mount's own `level` becomes `2` (Section 4.3 step 3), independent of the rider's own level | BR-022 |
| C9 | Character already at Level 3 | Moves to the opponent's edge again | No change, no duplicate signal | FR-050 |

## 9. Open Implementation Questions

- **Mount-propagation Embers — resolved 2026-09-25: a mounted-pair kill grants two Spirit Embers.** Both characters were defeated, so both release an Ember (BR-023A). This is the literal reading of BR-023A and it makes attacking a mounted pair meaningfully more rewarding than attacking a single character — worth watching in paper tests as a possible over-reward, since two Embers on one carrier currently only ever cash in as one Level 3 (Section 4.2 step 3). If the surplus Ember should instead be transferable, droppable, or worth something on its own, that is a new design decision, not a change to this ruling.
- **Reliance on synchronous signal emission (Section 4.5 step 3).** If any future code connects one of `LevelingSystem`'s listened-to signals with `CONNECT_DEFERRED`, HLD Flow D step 3's same-frame chain (`_check_level_2` → `character_leveled_up` → `_check_level_3`) would break silently (the Level 3 check would run one frame late instead of not at all — low risk, but worth a code-comment warning at the actual `connect()` call site during implementation).
- **No handling for a hypothetical "defeats own Ember-carrying ally" scenario** (friendly fire) — not possible with any current card, so not modeled; would need revisiting if a future card ever damages allies.

## 10. Traceability

| LLD Section | HLD Section | BRD/PRD IDs |
| --- | --- | --- |
| 4.1 `_check_level_2` | HLD 4.8, Flow D step 1 | BR-022, FR-047, FR-048 |
| 4.2 `_check_level_3` | HLD 4.8, Flow D step 3 | BR-023, BR-023A, FR-048 |
| 4.4 Spirit Ember pickup | HLD 4.8, Flow B step 3, Flow D step 2 | BR-023A, FR-047A |
| 3.1 `_level_up` | HLD 4.8 | FR-049, FR-050, FR-051 |

## 11. Next Steps

1. Add `scripts/systems/leveling_system.gd` (Section 3.1); instantiate it in `RulesEngine`'s match-start setup alongside `CombatResolver`/`MountSystem`/`AbilitySystem`, after `AbilitySystem` (constructor dependency).
2. Write `tests/unit/test_leveling_system.gd`; confirm C1–C9 with a doubled `AbilitySystem.apply_level_up_effects`.
3. Resolve the mount-propagation Ember question (Section 9) with the designer before relying on it in playtesting.
4. Once `AbilitySystem`'s real `apply_level_up_effects` exists for all 14 characters (LLD-05), add an integration test confirming a full level-up actually changes observable stats (e.g. Gymnast's MOVE after reaching Level 2).
