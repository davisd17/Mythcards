# MythCards Low-Level Design — Rules Engine (`RulesEngine`)

**Document Control**

| Field | Value |
| --- | --- |
| Source document(s) | HLD.md (v3, 2026-09-07), BRD.md (v3, 2026-08-14), LLD-content-board.md (v2, 2026-09-07), LLD-match-setup.md (v1, 2026-09-08) |
| Module/flow scope | Rules Engine (`RulesEngine` — HLD Section 4.4). HLD build-order step 8. |
| Target stack | Godot 4.7.x, GDScript |
| Version | 7 (v2–v5: mount-aware movement, effective-stat routing, `"reactive_bonus"`, status-effect gates; v6: `get_legal_move_tiles`/`get_legal_attack_target_ids` extracted as public preview queries; v7 — designer review 2026-09-25: range resolution now passes an attack-vs-ability `context` through one `get_effective_range(context)` call instead of each call site summing its own conditional term) |
| Date | 2026-09-25 |
| Status | Draft |
| Prepared by | Drew Davis (solo developer/designer, acting as own PM) |

## 1. Purpose & Scope

This LLD specs the single authoritative gate for every player action (move, attack, ability, mount, dismount, end-turn): AP validation, delegation to `BoardModel`/`CombatResolver`/`AbilitySystem`/`MountSystem` for legality and effect resolution, and the `action_requested` → `action_resolved` signal contract that is the only path any UI, future AI, or future network layer uses to change match state (HLD Section 9's networking extension point depends on this remaining true).

**Explicitly out of scope for this LLD**: the actual combat math and mount/dismount tile mechanics (`CombatResolver`/`MountSystem`, LLD-04), ability execution and targeting rules (`AbilitySystem`, LLD-05), and what happens after a character is defeated or levels up (`LevelingSystem`, LLD-06) — this LLD specs the dispatch/validation gate and the exact contract it calls into those modules through, not their internal behavior. Because `RulesEngine` is built (HLD Section 13 step 8) before `CombatResolver`, `AbilitySystem`, and `MountSystem` (steps 9–10), this LLD necessarily defines the calling contract those later LLDs must implement against — see Section 9.

## 2. File Layout

```
D:\mythcards\
├── scripts/
│   └── autoloads/
│       └── rules_engine.gd        (new — autoload name: RulesEngine)
└── tests/
    └── unit/
        └── test_rules_engine.gd   (new — extends GutTest; uses GUT doubles for
                                     CombatResolver/AbilitySystem/MountSystem, Section 9)
```

## 3. Class & Function Specs

### 3.1 `RulesEngine` (autoload, `res://scripts/autoloads/rules_engine.gd`)

```gdscript
extends Node
# Autoload name: RulesEngine

const ACTION_TYPES: Array[String] = ["move", "attack", "ability", "mount", "dismount", "end_turn",
    "reactive_bonus"]
# "reactive_bonus" covers the "once per turn/match, after X, may do Y for free" family of L3
# upgrades (e.g. Gymnast's Aurora Acrobat post-Vault attack, White Siberian Tiger's Aurora
# Predator post-Pounce-defeat bonus move+AP refresh) -- see LLD-ability-system.md Section 3 for
# the general pattern. Unlike every other action type, it costs no AP (Section 4.8) because the
# card text explicitly grants it "without spending AP"/"for free."
# Extends GameEnums (LLD-content-board.md Section 3.1) rather than living there, because this
# set is specific to RulesEngine's own dispatch table, not a cross-cutting content vocabulary
# like CHARACTER_TYPES -- see Section 9.

func request_action(action_type: String, actor_id: String, payload: Dictionary) -> Dictionary
    # The ONLY entry point. UI, future AI, and a future network layer call this exclusively;
    # no other code path may mutate MatchState (HLD Section 4.4, Section 9's networking seam
    # depends on this). Emits EventBus.action_requested(action_type, actor_id, payload) first
    # (for DebugPanel visibility of attempts, not just successes), then dispatches per Section 4,
    # then ALWAYS emits EventBus.action_resolved(action_type, actor_id, result) as its last step
    # -- on both success and failure -- and returns the same result Dictionary.
    # result shape: {"success": bool, "reason": String}, with action-specific extra keys added
    # by each handler (Section 4) only when success == true.

func _validate_common(action_type: String, actor_id: String) -> String
    # Returns "" if valid, else a human-readable failure reason. See Section 4.1 for the exact
    # ordered checks (they differ for "end_turn", where actor_id is a player id, not a
    # character instance_id).

func _handle_move(actor: CharacterInstance, payload: Dictionary) -> Dictionary
func _handle_attack(actor: CharacterInstance, payload: Dictionary) -> Dictionary
func _handle_ability(actor: CharacterInstance, payload: Dictionary) -> Dictionary
func _handle_mount(actor: CharacterInstance, payload: Dictionary) -> Dictionary
func _handle_dismount(actor: CharacterInstance, payload: Dictionary) -> Dictionary
func _handle_end_turn(player_id: String) -> Dictionary
func _handle_reactive_bonus(actor: CharacterInstance, payload: Dictionary) -> Dictionary
    # See Section 4.2-4.8 for each handler's exact algorithm.

func get_legal_move_tiles(actor_id: String) -> Array[Vector2i]
    # Public, non-mutating query -- forward-referenced by the presentation layer (LLD-11) for
    # move-highlight rendering (FR-017). Returns [] if actor_id doesn't resolve to a live
    # character (no error thrown -- a query, not an action). Otherwise runs exactly
    # _handle_move's Section 4.2 steps 1-3 (mover resolution, budget/pattern, predicates,
    # board.get_legal_moves call) and returns the result without touching AP, position, or
    # emitting any signal. _handle_move (Section 4.2) now calls this method internally instead
    # of duplicating the logic, so the two can never drift apart.

func get_legal_attack_target_ids(actor_id: String) -> Array[String]
    # Same shape, for attacks (FR-044). Runs _handle_attack's Section 4.3 steps 2-3 (range
    # candidates) plus a line-of-sight filter and enemy-occupancy filter per candidate tile,
    # returning the *character instance ids* of legal targets (more directly useful to a UI
    # highlighting character tokens than raw tile positions). _handle_attack calls this
    # internally for its own candidate check where it can (see Section 4.3 patch note).

func _spend_ap(actor: CharacterInstance) -> void
    # PlayerState.pool_ap_remaining -= 1; actor.character_ap_remaining -= 1. Emits
    # pool_ap_changed(actor.player_id, new_remaining) and
    # character_ap_changed(actor.instance_id, new_remaining). The single shared spend path for
    # every AP-costing action (move/attack/ability/mount/dismount, BR-020) so no handler
    # duplicates this bookkeeping.
```
Satisfies HLD Section 4.4 / BRD FR-021–FR-024, FR-027A, NFR-020, NFR-021.

## 4. Algorithms

### 4.1 `_validate_common` (ordered checks)

For `action_type` in `["move", "attack", "ability", "mount", "dismount"]` (`actor_id` is a `CharacterInstance.instance_id`):
1. `GameState.is_match_active()` — else `"match not active"`.
2. `GameState.match_state.find_character(actor_id) != null` — else `"unknown actor"`.
3. `actor.player_id == GameState.match_state.active_player_id` — else `"not your turn"`.
4. `GameState.match_state.get_player(actor.player_id).pool_ap_remaining >= 1` — else `"no pool AP remaining"` (BR-020).
5. `actor.character_ap_remaining >= 1` — else `"no character AP remaining"` (BR-020).

For `action_type == "reactive_bonus"` (`actor_id` is a `CharacterInstance.instance_id`, no AP check — see `ACTION_TYPES`'s note, Section 3.1):
1. `GameState.is_match_active()` — else `"match not active"`.
2. `GameState.match_state.find_character(actor_id) != null` — else `"unknown actor"`.
3. `actor.player_id == GameState.match_state.active_player_id` — else `"not your turn"`.

For `action_type == "end_turn"` (`actor_id` is a player id):
1. `GameState.is_match_active()` — else `"match not active"`.
2. `actor_id == GameState.match_state.active_player_id` — else `"not your turn"`.
(No AP check — ending a turn never costs AP.)

All five/two checks are evaluated in order, short-circuiting on the first failure — `request_action` never proceeds to dispatch (Section 4.2–4.7) if `_validate_common` returns a non-empty string; the result is `{"success": false, "reason": <that string>}`.

### 4.2 `_handle_move`

Payload: `{"to": Vector2i}`.
1. `var legal := get_legal_move_tiles(actor.instance_id)` (Section 3.1's v6 extraction — see below for that method's own algorithm, moved out of this handler so `_handle_move` and the presentation-layer preview path can never compute two different answers).
2. If `payload["to"]` not in `legal`, return `{"success": false, "reason": "illegal move"}`.
3. `var from := actor.position`; `board.clear_occupant(from)`; `board.set_occupant(payload["to"], actor.instance_id)`; `actor.position = payload["to"]`. If `actor.is_mounted_rider`, also set the mount `CharacterInstance.position = payload["to"]` (kept in sync for internal bookkeeping even though the mount has no separate `BoardTile` entry while mounted, LLD-04 Section 3).
4. `_spend_ap(actor)` — AP is spent from the rider's own pool/character AP even when mounted; the Mount never has its own AP spent since it cannot act separately (BR-015).
5. `actor.ability_uses_this_turn["moved"] = true` — a generic per-turn marker (not tied to any one character's ability) so any handler needing a "did this character move this turn" condition (e.g. Sniper's Aim, Section 9) has a single shared source of truth instead of each ability inventing its own tracking.
6. `EventBus.character_moved.emit(actor.instance_id, from, payload["to"])`.
7. Return `{"success": true}`.

**`get_legal_move_tiles(actor_id)` algorithm** (Section 3.1): resolve `actor` via `GameState.match_state.find_character(actor_id)`, returning `[]` if `null`. `var mover := actor`; if `actor.is_mounted_rider`: `mover := <the CharacterInstance actor.mounted_with_id resolves to>` (the Mount) — BR-014 puts MOVE, movement pattern, *and* any movement-affecting ability (e.g. Manta Glider's own Glide) on the Mount's side while carrying a rider. `var move_budget: int; var pattern: String`. If `actor.is_mounted_rider`: `move_budget = MountSystem.get_effective_move_stat(actor)`, `pattern = MountSystem.get_effective_movement_pattern(actor)` (forward references, LLD-04, already resolving internally to `mover`'s own stats). Else: `move_budget = mover.get_effective_move()`, `pattern = AbilitySystem.get_movement_pattern(mover)`. `predicate := AbilitySystem.get_movement_passable_predicate(mover)`, `object_predicate := AbilitySystem.get_movement_object_passable_predicate(mover)` (forward references, LLD-05; asked of `mover` so a Glider's own Glide applies while carrying a rider). Return `board.get_legal_moves(actor.position, move_budget, pattern, predicate, object_predicate)` (LLD-content-board.md v3, Section 3.6) — the BFS always starts from `actor.position` (where the pair/solo character actually stands) even though budget/pattern/predicates came from `mover`.

### 4.3 `_handle_attack`

Payload: `{"target_id": String}`.
1. `var target := GameState.match_state.find_character(payload["target_id"])`; if `null`, return `{"success": false, "reason": "unknown target"}`.
2. If `payload["target_id"]` not in `get_legal_attack_target_ids(actor.instance_id)` (Section 3.1's v6 extraction — see below), return `{"success": false, "reason": "out of range"}` if the failure was a range/pattern miss, or `{"success": false, "reason": "blocked line of sight"}` if it was an LOS block — `get_legal_attack_target_ids` itself only returns the final legal set, so `_handle_attack` re-derives *which* of the two reasons applies by checking range membership first (same as step 3/4 below) before falling back to the LOS reason, purely so the error message stays specific; the presentation layer's own preview use of `get_legal_attack_target_ids` doesn't need this distinction; only `report_action`'s failure `reason` string does.
3. `var effective_range := actor.get_effective_range("attack")` — v7 (2026-09-25): the `context` argument was added so attack range and ability range can diverge, and `get_effective_range()` now folds the `AbilitySystem` conditional term in itself rather than leaving each call site to add it (LLD-match-setup.md v5, Section 3.3). It bakes in permanent level-based RANGE (Sniper's L2 +1), `temp_range` status effects, the global range modifier, and `AbilitySystem.get_conditional_range_bonus(actor, "attack")` for live-state bonuses (Sniper's Aim: "+1 RANGE if it did not move this turn," which checks `actor.ability_uses_this_turn["moved"]` from Section 4.2 step 5). RANGE always uses the rider's own value even when mounted (BR-014), unlike MOVE. `candidates := board.get_tiles_in_range(actor.position, effective_range, pattern)` (`pattern := AbilitySystem.get_attack_pattern(actor)`, defaulting to `"orthogonal_line"`) — used only to produce the specific `"out of range"` vs `"blocked line of sight"` distinction in step 2, not re-validated as a separate gate.
4. `var combat_result := CombatResolver.resolve_attack(actor, target)` — forward reference (LLD-04); expected shape `{"damage": int, "defeated": bool}`. `CombatResolver` itself emits `attack_resolved` and, if applicable, `character_defeated` (HLD Section 5.3) — `RulesEngine` does not re-emit them.
5. `_spend_ap(actor)`.
6. Return `{"success": true, "damage": combat_result["damage"], "defeated": combat_result["defeated"]}`.

**`get_legal_attack_target_ids(actor_id)` algorithm** (Section 3.1): resolve `actor`, returning `[]` if `null`. `pattern := AbilitySystem.get_attack_pattern(actor)`, `effective_range := actor.get_effective_range("attack")` (v7 — same single-call form as Section 4.3 step 3), `candidates := board.get_tiles_in_range(actor.position, effective_range, pattern)`. For each `pos in candidates`: if `board.is_occupied_by_character(pos)` by an *enemy* of `actor.player_id`, and `board.has_line_of_sight(actor.position, pos, AbilitySystem.get_line_of_sight_exceptions(actor, pos, board))`, append that tile's occupant `instance_id` to the result. Return the result.

### 4.4 `_handle_ability`

Payload: `{"ability_id": String, "target": Variant}` (`target` is a `Vector2i` or a character `instance_id` depending on the ability — `AbilitySystem` interprets it, `RulesEngine` passes it through opaquely).
1. If `not AbilitySystem.can_use_ability(actor, payload["ability_id"])` — forward reference (LLD-05; covers once-per-turn/once-per-match limits, FR-043) — return `{"success": false, "reason": "ability unavailable"}`.
2. `legal_targets := AbilitySystem.get_legal_ability_targets(actor, payload["ability_id"])` — forward reference (LLD-05); implicitly applies BR-011/FR-036C line-of-sight blocking for any ranged ability (AbilitySystem is responsible for this, not RulesEngine, so the rule isn't checked in two places). Any range this resolves internally uses the `"ability"` context (`actor.get_effective_range("ability")`), never `"attack"` — v7, 2026-09-25: several effects grant range to abilities only (Crystal Architect's Pylon at L1, Link Mind, the Crystal Tide event) or to attacks only (Sniper's Aim), so the two must not share one number.
3. If `payload["target"]` not in `legal_targets`, return `{"success": false, "reason": "illegal ability target"}`.
4. `var ability_result := AbilitySystem.execute_ability(actor, payload["ability_id"], payload["target"])` — forward reference (LLD-05); expected shape `{"success": bool, ...ability-specific keys}`. `AbilitySystem` is responsible for emitting whatever specific signal its effect implies (e.g., a future `object_placed`), the same pattern `BoardModel.place_object` already defers to its caller (LLD-content-board.md Section 6).
5. `_spend_ap(actor)`.
6. Return `{"success": true}` merged with `ability_result`'s extra keys.

### 4.5 `_handle_mount`

Payload: `{"mount_id": String}`.
1. `var mount := GameState.match_state.find_character(payload["mount_id"])`; if `null`, return `{"success": false, "reason": "unknown mount"}`.
2. If `actor.data.type` not in `["Hero", "Leader"]`, return `{"success": false, "reason": "only a Hero or Leader may mount"}` (BR-012).
3. If `mount.data.type != "Mount"` or `mount.player_id != actor.player_id`, return `{"success": false, "reason": "invalid mount target"}`.
4. If `actor.mounted_with_id != ""` or `mount.mounted_with_id != ""`, return `{"success": false, "reason": "already mounted"}`.
5. If `actor.position` and `mount.position` are not orthogonally adjacent (Chebyshev/Manhattan distance check consistent with the orthogonal-only movement convention), return `{"success": false, "reason": "not adjacent"}` (BR-012).
6. If `actor.status_effects` contains a `type == "no_mount_dismount"` entry, return `{"success": false, "reason": "cannot mount right now"}` (Frost Seer's Chill, LLD-05 Section 9).
7. `MountSystem.mount(actor, mount)` — forward reference (LLD-04); expected to set `actor.mounted_with_id = mount.instance_id`, `mount.mounted_with_id = actor.instance_id`, `mount.is_mounted_rider = false`, `actor.is_mounted_rider = true`, clear the Mount's separate board tile via `board.clear_occupant(mount.position)` (the pair now occupies the rider's tile, BR-013), and leave `actor.position` unchanged.
8. `_spend_ap(actor)`.
9. Return `{"success": true}`.

### 4.6 `_handle_dismount`

Payload: `{"to": Vector2i}`.
1. If `not actor.is_mounted_rider` or `actor.mounted_with_id == ""`, return `{"success": false, "reason": "not mounted"}` (BR-015 — only the rider initiates; the Mount cannot act separately).
2. If `payload["to"]` is not orthogonally adjacent to `actor.position`, return `{"success": false, "reason": "not adjacent"}`.
3. If `not board.is_in_bounds(payload["to"])` or `board.is_occupied_by_character(payload["to"])` or `board.get_placed_object(payload["to"]) != null`, return `{"success": false, "reason": "no empty adjacent tile"}` (BR-017 — no legal dismount destination means the pair cannot dismount).
4. If `actor.status_effects` contains a `type == "no_mount_dismount"` entry, return `{"success": false, "reason": "cannot dismount right now"}` (Frost Seer's Chill, LLD-05 Section 9).
5. `MountSystem.dismount(actor, payload["to"])` — forward reference (LLD-04); expected to set `mount.position = payload["to"]`, `board.set_occupant(payload["to"], mount.instance_id)`, clear both `mounted_with_id`/`is_mounted_rider` fields on both instances. `actor.position` is unchanged (BR-017 — "the rider remains on the current tile").
6. `_spend_ap(actor)`.
7. Return `{"success": true}`.

### 4.7 `_handle_end_turn`

1. `TurnManager.end_turn(player_id)` (LLD-match-setup.md Section 3.8).
2. Return `{"success": true}`. (No AP spend — ending a turn is free.)

### 4.8 `_handle_reactive_bonus`

Payload: `{"tag": String, ...effect-specific extra keys (e.g. "target_id")}`. Covers the "once per turn/match, after X, may do Y for free" family of L3 upgrades — see LLD-ability-system.md (LLD-05) Section 3 for the full pattern and which characters use it.
1. If `actor.status_effects` contains a `type == "no_reaction"` entry, return `{"success": false, "reason": "reactions disabled"}` (Frost Seer's Deep Freeze, LLD-05 Section 9).
2. If `not actor.ability_uses_this_turn.get(payload["tag"] + "_available", false)` and `not actor.ability_uses_this_match.get(payload["tag"] + "_available", false)`, return `{"success": false, "reason": "no bonus action available"}` — `AbilitySystem`'s reactive event hooks (LLD-05) are the only code that ever sets one of these flags to `true`, when the trigger condition for that specific `tag` was just met.
3. `var bonus_result := AbilitySystem.execute_reactive_bonus(actor, payload["tag"], payload)` — forward reference (LLD-05); expected shape `{"success": bool, ...tag-specific keys}`. `AbilitySystem` is responsible for clearing the `"<tag>_available"` flag and setting the corresponding consumed-use counter (`ability_uses_this_turn`/`_this_match`) as part of this call, so a given offered bonus can only be consumed once.
4. No `_spend_ap(actor)` call — this action type is free by design (`ACTION_TYPES` note, Section 3.1).
5. Return `bonus_result`.

## 5. Data Structures

`RulesEngine` introduces no new persistent data structures — it operates entirely on `MatchState`/`PlayerState`/`CharacterInstance` (LLD-match-setup.md) and `BoardModel` (LLD-content-board.md). The only new shape is the transient `result: Dictionary` returned by `request_action` (Section 3.1), which is never stored, only returned and mirrored into `action_resolved`'s payload.

## 6. Signal/Payload Specs

| Signal | Emitted by | Payload | Invariant |
| --- | --- | --- | --- |
| `action_requested(action_type: String, actor_id: String, payload: Dictionary)` | `RulesEngine.request_action` (self-emitted, at entry) | one of `ACTION_TYPES`, id, action-specific dict | Always emitted before dispatch, whether the action will ultimately succeed or fail — DebugPanel/HUD see every attempt (HLD Section 4.11). |
| `action_resolved(action_type: String, actor_id: String, result: Dictionary)` | `RulesEngine.request_action` (self-emitted, at exit) | same `action_type`/`actor_id`, plus `result` from Section 4 | `result["success"]` is always present; `result["reason"]` is present iff `success == false`. Always emitted exactly once per `request_action` call, even on early validation failure. |
| `character_moved(character_id: String, from: Vector2i, to: Vector2i)` | `RulesEngine._handle_move` | ids/positions | Only emitted on a successful move (Section 4.2 step 7). |

`attack_resolved`, `character_defeated`, and any mount/ability-specific signals are emitted by `CombatResolver`/`AbilitySystem`/`MountSystem` themselves (their own later LLDs), not by `RulesEngine` — `RulesEngine` only ever emits the three signals above plus the generic `action_requested`/`action_resolved` pair.

## 7. Error Handling & Edge Cases

| Scenario | Expected behavior | Source |
| --- | --- | --- |
| `request_action` called with an `action_type` not in `ACTION_TYPES` | `push_error`, return `{"success": false, "reason": "unknown action type"}` without emitting `action_requested`/`action_resolved` (this is a caller/UI bug, not a gameplay-legal rejection) | Section 3.1 |
| Not the active player's turn | `{"success": false, "reason": "not your turn"}` (Section 4.1) | FR-024 |
| Pool AP or character AP exhausted | `{"success": false, "reason": "no pool AP remaining"}` / `"no character AP remaining"` (Section 4.1) | BR-020, FR-024 |
| Move target not in `get_legal_moves()` result | `{"success": false, "reason": "illegal move"}`, no state mutated | NFR-021 |
| Attack target out of range or blocked by line-of-sight | `{"success": false, "reason": "out of range"}` / `"blocked line of sight"`, no state mutated, no AP spent | NFR-021, BR-011 |
| Ability requested past its once-per-turn/once-per-match limit | `{"success": false, "reason": "ability unavailable"}` (delegated to `AbilitySystem.can_use_ability`) | FR-043 |
| Mount/dismount adjacency or occupancy checks fail | `{"success": false, "reason": ...}` per Section 4.5/4.6, no state mutated, no AP spent | BR-012, BR-017 |
| A handler (`_handle_*`) is reached but its forward-referenced module (`CombatResolver`/`AbilitySystem`/`MountSystem`) doesn't exist yet at this LLD's implementation time | Undefined by this LLD — see Section 9's build-order note; GUT tests use doubles (Section 8) until those LLDs land | Section 9 |
| Two actions requested for the same actor with no AP spent between them (e.g., a UI double-tap) | Not specially handled — the second `request_action` call re-validates AP fresh each time (Section 4.1) and is naturally rejected once AP hits 0; no debounce/lock is implemented at this tier | NFR-020 |

## 8. Test Plan

Unit tests use **GUT**. Because `CombatResolver`, `AbilitySystem`, and `MountSystem` are specced in later LLDs (04/05), `tests/unit/test_rules_engine.gd` uses GUT doubles (`double()`/`stub()`) for those three autoloads/classes to test `RulesEngine`'s own dispatch/validation logic in isolation — this is explicitly the point of doubling per GUT's own design, not a workaround. A smaller set of true integration cases (marked below) is deferred until LLD-04/05 land for real.

| Case | Given | When | Then | BRD ID |
| --- | --- | --- | --- | --- |
| C1 | Match active, P1's turn, `p1_r-gymnast` has AP | `request_action("move", "p1_r-gymnast", {"to": <legal tile>})` | `{"success": true}`; character's `position` updated; `pool_ap_remaining`/`character_ap_remaining` each decremented by 1 | FR-021, BR-020 |
| C0a | Any valid actor with legal moves available | `get_legal_move_tiles(actor_id)` | Returns the same set `_handle_move` would validate against; no state mutated, no signal emitted | FR-017 |
| C0b | An unknown `actor_id` | `get_legal_move_tiles(actor_id)` | Returns `[]`, no crash | Section 3.1 |
| C0c | Doubled `CombatResolver`/`AbilitySystem` as in C5–C7 | `get_legal_attack_target_ids(actor_id)` | Returns exactly the enemy instance ids within range and clear LOS | FR-044 |
| C1a | Actor is a mounted rider (`is_mounted_rider == true`), doubled `MountSystem.get_effective_move_stat` returns the Mount's higher MOVE | `request_action("move", <rider>, {"to": <tile only reachable at the Mount's MOVE, not the rider's own>})` | `{"success": true}`; both rider's and mount's `position` updated to `to` | BR-014 |
| C2 | Same, but `to` is not in `get_legal_moves()` | `request_action("move", ...)` | `{"success": false, "reason": "illegal move"}`; no AP spent, no position change | NFR-021 |
| C3 | Match active, but it is P2's turn | `request_action("move", "p1_r-gymnast", {...})` | `{"success": false, "reason": "not your turn"}` | FR-024 |
| C4 | P1's `r-gymnast` has `character_ap_remaining == 0` | `request_action("move", "p1_r-gymnast", {...})` | `{"success": false, "reason": "no character AP remaining"}` | BR-020 |
| C5 | Doubled `CombatResolver.resolve_attack` returns `{"damage": 2, "defeated": false}` | `request_action("attack", <actor>, {"target_id": <target>})` with target in range and LOS clear | `{"success": true, "damage": 2, "defeated": false}`; AP spent once | FR-022 |
| C6 | Target outside `get_tiles_in_range()` result | `request_action("attack", ...)` | `{"success": false, "reason": "out of range"}` | FR-029 |
| C7 | Target in range but an occupied tile sits between attacker and target | `request_action("attack", ...)` | `{"success": false, "reason": "blocked line of sight"}` | BR-011 |
| C8 | Doubled `AbilitySystem.can_use_ability` returns `false` | `request_action("ability", ...)` | `{"success": false, "reason": "ability unavailable"}` | FR-043 |
| C9 | `_handle_mount` with a non-adjacent ally Mount | `request_action("mount", ...)` | `{"success": false, "reason": "not adjacent"}` | BR-012 |
| C10 | `_handle_dismount` with no empty adjacent tile (all 4 neighbors occupied/out of bounds) | `request_action("dismount", ...)` | `{"success": false, "reason": "no empty adjacent tile"}` | BR-017 |
| C11 | Any `request_action` call, success or failure | — | `action_requested` and `action_resolved` both fire exactly once each (GUT signal-watch) | Section 6 |
| C12 | `request_action("end_turn", "p1", {})` while P1 is active | — | `{"success": true}`; `TurnManager.end_turn` called (GUT double/spy) | FR-026 |
| C12a | `actor.ability_uses_this_turn["l3_bonus_attack_available"] == true` | `request_action("reactive_bonus", actor_id, {"tag": "l3_bonus_attack", "target_id": ...})` | `{"success": true}`; no AP deducted; doubled `AbilitySystem.execute_reactive_bonus` called once | FR-043 |
| C12b | Same flag `false`/unset | `request_action("reactive_bonus", ...)` | `{"success": false, "reason": "no bonus action available"}` | Section 4.8 |
| C13 *(deferred, integration)* | Real `CombatResolver`/`AbilitySystem`/`MountSystem` once LLD-04/05 land | A full move → attack → ability → mount → dismount → end_turn sequence via `request_action` only | Match state stays consistent throughout (NFR-020); no direct `MatchState` mutation occurs outside `RulesEngine`/its delegates | NFR-020, NFR-021 |

## 9. Open Implementation Questions

- **Forward-referenced contract for `CombatResolver`, `AbilitySystem`, `MountSystem`.** This LLD is built (HLD step 8) before those three (steps 9–10) and therefore defines, rather than consumes, their calling contract: `CombatResolver.resolve_attack(actor, target) -> Dictionary`, `MountSystem.mount(actor, mount) -> void`, `MountSystem.dismount(actor, to) -> void`, `MountSystem.get_effective_move_stat(actor) -> int`, `MountSystem.get_effective_movement_pattern(actor) -> String`, `AbilitySystem.get_movement_pattern/get_movement_passable_predicate/get_attack_pattern/get_line_of_sight_exceptions/can_use_ability/get_legal_ability_targets/execute_ability`. LLD-04 and LLD-05 must implement exactly these signatures or this LLD needs a patch — flagged here so those LLDs don't independently invent a different shape.
- **(v2 patch note)** `_handle_move`'s original v1 draft used `actor.data.move` unconditionally, which is wrong for a mounted rider per BR-014 (the pair uses the Mount's MOVE/pattern, not the rider's). Caught and patched while writing LLD-combat-mount.md (LLD-04) — see Section 4.2's revised step 1. Flagged here as a reminder that `_handle_attack` was deliberately *not* changed the same way, since BR-014 keeps RANGE on the rider's own stat line.
- **(v4 patch note)** `"reactive_bonus"` (Section 4.8) and `AbilitySystem.execute_reactive_bonus(actor, tag, payload) -> Dictionary` are new forward-referenced additions for LLD-05's benefit. `AbilitySystem` also needs `get_line_of_sight_exceptions(actor, target_pos, board) -> Array[String]` (note the two extra parameters versus this LLD's original v1/v2 assumption of `get_line_of_sight_exceptions(actor)` alone — Sniper's Piercing Shot needs to know *which* target/line is being traced to pick a tile to ignore, which the actor-only signature couldn't express). `_handle_attack`'s Section 4.3 step 5 is patched accordingly below.
- **(v6 patch note)** `get_legal_move_tiles`/`get_legal_attack_target_ids` (Section 3.1) are the presentation layer's (LLD-11) only sanctioned way to preview legality before calling `request_action` — it must never re-derive movement/attack legality itself (that would risk exactly the kind of drifted second implementation HLD-R-002 warns against for the Hero-capture check specifically, and the same risk applies generally).
- **(v5 patch note)** Additional forward references added: `AbilitySystem.get_movement_object_passable_predicate(mover) -> Callable` (Section 4.2 step 2, paired with LLD-content-board.md v3's new `object_passable_predicate` parameter), `AbilitySystem.get_conditional_range_bonus(actor) -> int` (Section 4.3 step 3), and two new `StatusEffect.type` values consumed directly by this LLD rather than queried through `AbilitySystem`: `"no_mount_dismount"` (Section 4.5–4.6) and `"no_reaction"` (Section 4.8) — both are plain flag checks against `actor.status_effects`, cheap enough not to need a dedicated `AbilitySystem` query method.
- **`ACTION_TYPES` placement.** Kept as a `RulesEngine`-local const rather than added to the shared `GameEnums` (LLD-content-board.md Section 3.1) because it's this module's own dispatch vocabulary, not cross-cutting content data every module needs — revisit if a second module (e.g., a future AI) needs to enumerate action types independently.
- **No undo/confirmation modeled.** FR-074/FR-045 ("Should") mention undo and irreversible-action confirmation. Not modeled by this LLD's `request_action` (which mutates immediately on success) — if added, it would sit in the presentation layer (confirm-before-calling `request_action`) rather than requiring a `RulesEngine` rollback capability, since every current action is a forward-only state change with no printed card requiring a reversal.
- **No debounce/action-lock against duplicate rapid requests** (Section 7) — acceptable for a hotseat prototype with synchronous single-threaded input; would need revisiting for the future networked-PvP extension point (HLD Section 9) where request latency could create a race.

## 10. Traceability

| LLD Section | HLD Section | BRD/PRD IDs |
| --- | --- | --- |
| 3.1, 4.1 Validation gate | HLD 4.4, Flow A | FR-021–FR-024, BR-020, NFR-020, NFR-021 |
| 4.2 `_handle_move` | HLD 4.2, 4.4 | FR-012–FR-015, BR-008, BR-010 |
| 4.3 `_handle_attack` | HLD 4.4, 4.5, Flow B | FR-022, FR-029, BR-011, FR-036C |
| 4.4 `_handle_ability` | HLD 4.4, 4.6 | FR-023, FR-043 |
| 4.5–4.6 Mount/dismount | HLD 4.4, 4.7 | FR-027A, BR-012, BR-017 |
| 4.7 `_handle_end_turn` | HLD 4.3, 4.4 | FR-026 |
| Section 6 Signals | HLD 5.3 | — |

## 11. Next Steps

1. Add `scripts/autoloads/rules_engine.gd` (Section 3.1); register as an autoload after `GameState`/`TurnManager`/`RelicEventDeck`/`VictoryChecker` in Project Settings (order doesn't matter functionally since `RulesEngine` calls them by autoload name at request time, not at `_ready()`, but keeping it last among gameplay autoloads documents the dependency direction).
2. Write `tests/unit/test_rules_engine.gd` using GUT doubles for `CombatResolver`/`AbilitySystem`/`MountSystem`; confirm C1–C12.
3. Wire the presentation layer's `action_requested` calls (a later LLD) exclusively through `RulesEngine.request_action` — never a direct `MatchState` mutation.
4. Once LLD-04 and LLD-05 land, replace the GUT doubles with real implementations for the deferred integration case (C13).
