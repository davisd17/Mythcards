# MythCards Low-Level Design — Combat Resolution & Mounted Pair (`CombatResolver`, `MountSystem`)

**Document Control**

| Field | Value |
| --- | --- |
| Source document(s) | HLD.md (v3, 2026-09-07), BRD.md (v3, 2026-08-14), LLD-content-board.md (v2), LLD-match-setup.md (v1), LLD-rules-engine.md (v2) |
| Module/flow scope | Combat Resolution (`CombatResolver` — HLD Section 4.5) and Mounted Pair (`MountSystem` — HLD Section 4.7). HLD build-order step 9 groups these two. |
| Target stack | Godot 4.7.x, GDScript |
| Version | 6 (v2: base damage from `get_effective_atk()`; v3: lethal-damage interception hook; v4: "marked"/penetration damage terms and `"no_push"`; v5: `character_defeated` now carries the defeating character's id and a `cause` tag; v6 — designer review 2026-09-25: "ranged" confirmed as actual tile distance > 1; shield consumption fixed as newest-first (LIFO); Piercing Shot fixed at 1 point of damage reduction; mount-propagation defeat now grants a second Spirit Ember) |
| Date | 2026-09-25 |
| Status | Draft |
| Prepared by | Drew Davis (solo developer/designer, acting as own PM) |

## 1. Purpose & Scope

This LLD specs damage application (including shields, flat damage reduction, and defeat detection) and mount/dismount tile mechanics with stat inheritance and defeat propagation. It implements the exact `CombatResolver`/`MountSystem` contract that `RulesEngine` (LLD-rules-engine.md Sections 4.3, 4.5–4.6, 9) already calls into.

**Explicitly out of scope for this LLD**: ability-specific effects (Pounce, Chill, Barricade, Pylon, etc. — `AbilitySystem`, LLD-05), what happens after a defeat with respect to Spirit Ember and leveling (`LevelingSystem`, LLD-06), and the AP-gating/adjacency validation already done by `RulesEngine` before calling into this module (LLD-rules-engine.md Sections 4.3, 4.5–4.6) — this LLD trusts that its callers have already validated range, line-of-sight, and mount/dismount legality, and focuses only on the resulting state change.

## 2. File Layout

```
D:\mythcards\
├── scripts/
│   └── systems/
│       ├── combat_resolver.gd     (new — class_name CombatResolver)
│       └── mount_system.gd        (new — class_name MountSystem)
└── tests/
    └── unit/
        ├── test_combat_resolver.gd  (new — extends GutTest)
        └── test_mount_system.gd     (new — extends GutTest)
```

Both are plain `class_name` classes, not autoloads, per HLD Section 5.1 — instantiated and held by `RulesEngine` (or a shared systems container it owns), the same pattern already established for `BoardModel`.

## 3. Class & Function Specs

### 3.1 `CombatResolver` (`res://scripts/systems/combat_resolver.gd`)

```gdscript
class_name CombatResolver
extends RefCounted

var board: BoardModel   # injected at construction by whoever owns this instance (RulesEngine)

func _init(p_board: BoardModel) -> void:
    board = p_board

func resolve_attack(attacker: CharacterInstance, defender: CharacterInstance) -> Dictionary
    # The contract RulesEngine._handle_attack calls (LLD-rules-engine.md Section 4.3 step 7).
    # base_amount := attacker.get_effective_atk() + AbilitySystem.get_conditional_atk_bonus(attacker)
    # (forward reference, LLD-05) -- get_effective_atk() (LLD-match-setup.md v3, Section 3.3)
    # bakes in any permanent level-based ATK bonus and active temp_atk status effect; the added
    # AbilitySystem term covers live-condition bonuses that depend on board state rather than
    # level alone (e.g. Quartz Attendant's Synchronize: "+1 ATK while adjacent to another
    # Atlantean"). Never reads CharacterData.atk directly.
    # is_ranged := board's actual tile distance between attacker.position and defender.position
    # is greater than 1 (Section 9 -- "ranged" is defined by actual distance, not printed RANGE).
    # Delegates to apply_damage(attacker, defender, base_amount, is_ranged) (below) for the rest
    # of the math, then emits the two signals (Section 6) this function alone is responsible
    # for. Returns {"damage": int, "defeated": bool}.

func apply_damage(attacker: CharacterInstance, defender: CharacterInstance, base_amount: int,
        is_ranged: bool) -> Dictionary
    # Shared damage-application entrypoint -- used by resolve_attack() above AND by
    # AbilitySystem (LLD-05, forward-referenced there) for abilities that deal direct damage
    # (e.g. Frost Seer's Chill), so the shield/reduction/defeat pipeline is implemented exactly
    # once. See Section 4.1 for the exact algorithm. Returns {"damage": int, "defeated": bool}
    # ("damage" is the FINAL amount actually applied to HP, after reduction/shields -- not
    # base_amount). Does NOT emit attack_resolved (that signal is specific to the basic-attack
    # action) -- callers other than resolve_attack() emit their own appropriate signal.

func apply_push(target: CharacterInstance, from_position: Vector2i, distance: int) -> Vector2i
    # Shared displacement helper (FR-034) -- used by abilities that push/pull (e.g. Pounce's
    # Level 2 push, Psychic Undertow). See Section 4.2 for the exact algorithm. Returns the
    # target's actual final position (may be less than the requested distance if blocked).
    # Mutates board occupancy and target.position directly; does not spend AP (the calling
    # ability already did, via RulesEngine) and does not emit a signal itself -- the calling
    # ability's own execute_ability (LLD-05) is responsible for signaling its specific effect.

func _handle_defeat(defender: CharacterInstance, attacker: CharacterInstance) -> void
    # See Section 4.3. `attacker` (v5 addition) is threaded through so character_defeated can
    # report who gets credit for the defeat -- LevelingSystem (LLD-06) needs this for Spirit
    # Ember pickup (BR-023A) and has no other way to learn it, since not every defeat comes
    # through resolve_attack()/attack_resolved (e.g. Frost Seer's Chill calls apply_damage
    # directly, LLD-ability-system.md Section 5.7). Removes defender from the board, emits
    # character_defeated, and -- if defender.is_mounted_rider -- propagates defeat to the mount
    # (BR-016) via MountSystem.handle_rider_defeated() (Section 3.2).
```
Satisfies HLD Section 4.5 / BRD FR-028–FR-036C.

### 3.2 `MountSystem` (`res://scripts/systems/mount_system.gd`)

```gdscript
class_name MountSystem
extends RefCounted

var board: BoardModel   # injected at construction, same pattern as CombatResolver

func _init(p_board: BoardModel) -> void:
    board = p_board

func mount(rider: CharacterInstance, mount_char: CharacterInstance) -> void
    # Contract RulesEngine._handle_mount calls (LLD-rules-engine.md Section 4.5 step 6).
    # Preconditions (already validated by RulesEngine before this is called): rider.data.type
    # in ["Hero","Leader"], mount_char.data.type == "Mount", same player_id, both currently
    # unmounted, adjacent. Effects (BR-012, BR-013):
    #   rider.mounted_with_id = mount_char.instance_id
    #   mount_char.mounted_with_id = rider.instance_id
    #   rider.is_mounted_rider = true
    #   mount_char.is_mounted_rider = false
    #   board.clear_occupant(mount_char.position)   # the Mount's own tile is vacated --
    #     the combined pair now occupies only the rider's tile (BR-013)
    #   mount_char.position = rider.position         # kept in sync for bookkeeping even
    #     without its own BoardTile entry (LLD-rules-engine.md v2 patch note, Section 9)

func dismount(rider: CharacterInstance, to: Vector2i) -> void
    # Contract RulesEngine._handle_dismount calls (Section 4.6 step 4). Preconditions already
    # validated by RulesEngine: `to` is adjacent, in bounds, and empty. Effects (BR-017):
    #   var mount_char := <the CharacterInstance rider.mounted_with_id resolves to>
    #   board.set_occupant(to, mount_char.instance_id)
    #   mount_char.position = to
    #   rider.mounted_with_id = ""; mount_char.mounted_with_id = ""
    #   rider.is_mounted_rider = false  (mount_char.is_mounted_rider was already false)
    #   # rider.position is unchanged -- "the rider remains on the current tile" (BR-017)

func get_effective_move_stat(rider: CharacterInstance) -> int
    # Forward-referenced by RulesEngine._handle_move (LLD-rules-engine.md Section 4.2 step 1).
    # Returns the Mount's CharacterInstance.data.move if rider.is_mounted_rider, else
    # rider.data.move unchanged (callers only invoke this when already mounted, but the
    # fallback keeps the function safe to call unconditionally). BR-014.

func get_effective_movement_pattern(rider: CharacterInstance) -> String
    # Same shape as get_effective_move_stat(), for movement pattern (default "orthogonal"
    # unless the Mount itself has a pattern-altering passive, e.g. Manta Glider's Glide --
    # see Section 9 for how that composes with AbilitySystem's own pattern query).

func handle_rider_defeated(rider: CharacterInstance) -> CharacterInstance
    # Called by CombatResolver._handle_defeat() (Section 3.1) when a defeated character is a
    # mounted rider. Resolves the mount via rider.mounted_with_id, removes it from the board
    # (board.clear_occupant at its tracked position), clears both mounted_with_id fields, and
    # returns the now-also-defeated mount CharacterInstance so the caller can emit its own
    # character_defeated for it (BR-016 -- "both rider and Mount are defeated"). This function
    # does not itself emit character_defeated for the mount, keeping signal emission
    # centralized in CombatResolver (Section 6) rather than split across two classes.
```
Satisfies HLD Section 4.7 / BRD FR-045B–FR-045H, BR-012–BR-017.

## 4. Algorithms

### 4.1 `apply_damage` (shield/reduction pipeline)

1. `var mark_bonus := 0`; for each `se in defender.status_effects` where `se.type == "marked"` and `AbilitySystem.is_ally_of_mark_source(se, attacker)` (forward reference, LLD-05 — resolves `se.source_character_id`'s `player_id` and compares to `attacker.player_id`; a mark only benefits the marking character's own allies, per Sniper's Dead Lane, BR-026): `mark_bonus += se.value`; remove that `se` from `defender.status_effects` after this attack resolves (single use, Section 9). `var marked_amount := base_amount + mark_bonus`.
2. `var reduction := AbilitySystem.get_passive_damage_reduction(defender, attacker, is_ranged)` — forward reference (LLD-05); returns a flat int (e.g. Resonance Guard's innate Quartz Armor: `-1` to ranged attacks against itself; Bogatyr Champion's Level 2 aura: `-1` to attacks against characters adjacent to it). Defaults to `0` if `AbilitySystem` reports no applicable passive.
3. `var penetration := AbilitySystem.get_penetration(attacker)` — forward reference (LLD-05); returns `{"ignore_reduction": int, "ignore_shield": int}`, both `0` by default. Sniper's Piercing Shot (L2+) returns `{"ignore_reduction": 1, "ignore_shield": 0}` unconditionally — designer-confirmed 2026-09-25: it ignores exactly 1 *point* of damage reduction, with no attacker choice and no shield interaction, so a defender with 2 points of reduction still applies 1. `reduction = max(0, reduction - penetration["ignore_reduction"])`. The `ignore_shield` term currently has no consumer in the roster; it stays in the contract for future cards.
4. `var after_reduction := max(0, marked_amount - reduction)`.
5. `var shield_total := 0`; for each `se in defender.status_effects` where `se.type == "shield"`: `shield_total += se.value`. `shield_total = max(0, shield_total - penetration["ignore_shield"])`.
8. If `shield_consumed > 0`: walk `defender.status_effects` in **reverse** array order (newest first), subtracting from each `shield`-type entry's `value` until `shield_consumed` is fully accounted for; remove any entry whose `value` reaches `0`. **Designer ruling, 2026-09-25: the last shield applied is the first one consumed** (LIFO) — the shield a player just spent an action to put up is the one that absorbs the next hit, which is what a player watching the board expects. This matters whenever two shields with different `expires` values are stacked: the newer one is burned first, so the older, possibly longer-lived one survives. (Subtraction order between the `mark_bonus`/`reduction`/`shield` *terms* still does not change `final_damage` — all are flat linear terms clamped once — so only the order in which shield *entries* are drained is a rules decision, and it is now fixed as newest-first.)
9. `var would_be_hp := defender.current_hp - final_damage`.
10. If `would_be_hp <= 0`: `var intercept := AbilitySystem.intercept_lethal_damage(defender)` — forward reference (LLD-05); default `{"triggered": false}` when no character has a lethal-damage-interception passive (e.g. Bogatyr Champion's Last Oath, once per match). If `intercept["triggered"] == true`, set `defender.current_hp = intercept["final_hp"]` (Last Oath specifies `2`) instead of `would_be_hp`, and apply any side effect the intercept reports (e.g. Last Oath's "adjacent enemies take 1 damage" — `AbilitySystem` applies that itself via `apply_damage` recursion or a direct `board`-driven loop, since it already has both the board and combat-resolver context; see LLD-05 Section 9). Else `defender.current_hp = max(0, would_be_hp)`.
11. `var defeated := defender.current_hp <= 0`.
12. If `defeated`: call `_handle_defeat(defender, attacker)` (Section 4.3).
13. Return `{"damage": final_damage, "defeated": defeated}`.

### 4.2 `apply_push`

1. If `target.status_effects` contains a `type == "no_push"` entry, return `target.position` unchanged (Frost Seer's Winter Veil, L2: "shielded allies cannot be pushed this turn" — LLD-05 Section 9).
2. `var direction := <the orthogonal unit vector from from_position toward target's current position>` — pushes move the target further away along the same line it was already on relative to `from_position` (e.g. the attacker's tile for a melee push), per every current card's push text ("pushes the target 1 tile if possible").
3. `var cursor := target.position`; `var steps_taken := 0`.
4. While `steps_taken < distance`:
   a. `var next := cursor + direction`.
   b. If `not board.is_in_bounds(next)` or `board.is_occupied_by_character(next)` or `(board.get_placed_object(next) != null and PlacedObjectRegistry.get_def(board.get_placed_object(next).type_id).blocks_movement)`: stop (push halts at the first obstruction — "if possible" per card text means a partial or zero-distance push is valid, not a failure).
   c. `cursor = next`; `steps_taken += 1`.
5. If `cursor != target.position`: `board.clear_occupant(target.position)`; `board.set_occupant(cursor, target.instance_id)`; `target.position = cursor`.
6. Return `cursor`.

### 4.3 `_handle_defeat`

1. `board.clear_occupant(defender.position)`.
2. `EventBus.character_defeated.emit(defender.instance_id, attacker.instance_id, "direct")`.
3. If `defender.is_mounted_rider`: `var mount_char := MountSystem.handle_rider_defeated(defender)`; `EventBus.character_defeated.emit(mount_char.instance_id, attacker.instance_id, "mount_propagation")` (BR-016 — the propagated defeat gets its own signal emission so `LevelingSystem`/`VictoryChecker` see it as a distinct event, not folded into the rider's). Per the designer ruling of 2026-09-25 (BR-023A), defeating a mounted pair yields **two** Spirit Embers to the attacker: `LevelingSystem` grants one per `character_defeated`, for both the `"direct"` and the `"mount_propagation"` cause (LLD-06 Section 4.4). Emitting both signals with `attacker.instance_id` already carried everything that ruling needs — no signal-shape change.

## 5. Data Structures

Neither module introduces new persistent data structures — both operate on `CharacterInstance`/`StatusEffect` (LLD-match-setup.md) and `BoardModel`/`PlacedObjectRegistry` (LLD-content-board.md). `apply_damage`'s and `resolve_attack`'s return `Dictionary` shapes are transient, matching the contract already fixed by LLD-rules-engine.md Section 9.

## 6. Signal/Payload Specs

| Signal | Emitted by | Payload | Invariant |
| --- | --- | --- | --- |
| `attack_resolved(attacker_id: String, target_id: String, damage: int, defeated: bool)` | `CombatResolver.resolve_attack` | ids, int, bool | Emitted exactly once per `resolve_attack` call, regardless of whether `defeated` is true. `damage` is the final (post-reduction/shield) amount. |
| `character_defeated(character_id: String, defeated_by_id: String, cause: String)` | `CombatResolver._handle_defeat` | ids, `"direct"` \| `"mount_propagation"` | Emitted once per defeated character — twice for a single `apply_damage` call when a mounted rider is defeated (once for the rider with `cause="direct"`, once for the propagated mount with `cause="mount_propagation"`, Section 4.3 step 3), both carrying the same `defeated_by_id` (the actual attacker). `defeated_by_id` is never empty — every path into `_handle_defeat` has a concrete `attacker` (v5 addition, Section 3.1). |

`apply_damage` and `apply_push`, called directly by a future `AbilitySystem` (LLD-05) rather than through `resolve_attack`, do **not** emit `attack_resolved` themselves — per Section 3.1, the calling ability is responsible for its own signal (this keeps `attack_resolved` semantically meaning "a basic attack happened," not "damage happened for any reason"). `apply_damage` still triggers `_handle_defeat` internally (step 9 of Section 4.1) regardless of caller, so `character_defeated` fires correctly even for ability-sourced damage.

## 7. Error Handling & Edge Cases

| Scenario | Expected behavior | Source |
| --- | --- | --- |
| `apply_damage` called with `base_amount <= 0` | Proceeds through the pipeline normally; `final_damage` will be `0` and `defeated` will be `false` unless `defender.current_hp` was already `0` (which shouldn't happen — a `0`-HP character should already have been removed) | Section 4.1 |
| Defender has multiple stacked shields | All summed before consumption (Section 4.1 step 5); drained **newest-first** (step 8), per the 2026-09-25 designer ruling — the most recently applied shield is spent first, so a longer-lived older shield survives a partial hit | Section 4.1 |
| `resolve_attack` where `attacker` and `defender` are on the same team (friendly fire) | Not defended against by this LLD — `RulesEngine`/`AbilitySystem` are responsible for only ever calling this with a legitimate enemy target; no current card targets allies with damage | Flagged, not solved, here |
| `apply_push` where the target is already blocked in the push direction (0 legal steps) | Returns the target's unchanged `position`; no board mutation, no error — "if possible" already covers a zero-distance push (Section 4.2 step 3b) | FR-034 |
| `mount()` called when either character is already mounted | Not re-validated here — `RulesEngine._handle_mount` already checked `mounted_with_id == ""` for both before calling (LLD-rules-engine.md Section 4.5 step 4); this module trusts that precondition | Section 1 |
| `dismount()` called with a `to` tile that became occupied between `RulesEngine`'s validation and this call | Cannot happen in the current single-threaded, synchronous hotseat flow (no intervening action can execute mid-`request_action`) — flagged as a latent risk only relevant to the future networked-PvP extension point (HLD Section 9) | HLD Section 9 |
| A mounted rider is defeated while `mount_char` cannot be resolved (data corruption / `mounted_with_id` pointing at a nonexistent instance) | `push_error` and return `null` from `handle_rider_defeated` — `_handle_defeat` must guard against a `null` return and skip the second `character_defeated` emission rather than crash; this should never happen if `mount()`/`dismount()` keep both sides' `mounted_with_id` in sync correctly | NFR-020 |

## 8. Test Plan

Unit tests use **GUT**. `AbilitySystem.get_passive_damage_reduction` is doubled (returns `0` by default, overridden per case) since `AbilitySystem` is specced in LLD-05.

| Case | Given | When | Then | BRD ID |
| --- | --- | --- | --- | --- |
| C1 | Attacker ATK 2, defender no shield, no reduction | `apply_damage(attacker, defender, 2, false)` | `{"damage": 2, "defeated": <depends on HP>}`; `defender.current_hp` reduced by 2 | FR-030, FR-031 |
| C2 | Defender has a shield `StatusEffect(type="shield", value=1)`, incoming damage 2 | `apply_damage(...)` | `final_damage == 1`; the shield entry is removed from `status_effects` (fully consumed) | FR-033 |
| C3 | Defender has a shield `value=3`, incoming damage 1 | `apply_damage(...)` | `final_damage == 0`; the shield entry's `value` reduced to `2`, not removed | FR-033 |
| C3A | Defender carries two shields, an older `value=1` (`expires="this_round"`) and a newer `value=1` (`expires="this_turn"`), incoming damage 1 | `apply_damage(...)` | `final_damage == 0`; the **newer** entry is consumed and removed; the older `this_round` shield is still present at full value | Section 4.1 |
| C4 | Doubled `AbilitySystem.get_passive_damage_reduction` returns `1`, incoming damage 1, no shield | `apply_damage(...)` | `final_damage == 0` | FR-036 |
| C5 | `defender.current_hp` reaches exactly 0 | `apply_damage(...)` | `{"defeated": true}`; `character_defeated` signal fires once; `board.is_occupied_by_character(defender's old position)` is `false` | FR-032 |
| C6 | Defeated defender was `is_mounted_rider == true` | `apply_damage(...)` (or `resolve_attack`) | `character_defeated` fires **twice** (rider then mount); the mount's tile is also cleared | BR-016 |
| C7 | Target adjacent to a wall of allies 2 tiles in the push direction | `apply_push(target, from, 1)` | Target moves exactly 1 tile; board occupancy updated | FR-034 |
| C8 | Push direction immediately blocked (occupied tile 1 away) | `apply_push(target, from, 1)` | Target's position unchanged; returns the original position | FR-034, Section 4.2 |
| C9 | Adjacent ally Mount, both unmounted | `mount(rider, mount_char)` | `rider.mounted_with_id == mount_char.instance_id`; `board.is_occupied_by_character(mount_char's old tile)` is `false`; `mount_char.position == rider.position` | BR-012, BR-013 |
| C10 | Mounted pair, empty adjacent tile `to` | `dismount(rider, to)` | `mount_char.position == to`; `board.is_occupied_by_character(to)` is `true`; both `mounted_with_id` cleared; `rider.position` unchanged | BR-017 |
| C11 | Rider is mounted, Mount's `data.move == 4`, rider's own `data.move == 2` | `get_effective_move_stat(rider)` | Returns `4` | BR-014 |
| C12 | Rider is NOT mounted | `get_effective_move_stat(rider)` | Returns `rider.data.move` unchanged | BR-014 |
| C13 | Doubled `AbilitySystem.intercept_lethal_damage` returns `{"triggered": true, "final_hp": 2}`, incoming damage would reduce defender to 0 | `apply_damage(...)` | `defender.current_hp == 2`; `{"defeated": false}`; `character_defeated` does NOT fire | BR-026 (Last Oath) |

## 9. Open Implementation Questions

- **Definition of "ranged" — confirmed by the designer, 2026-09-25.** An attack is "ranged" if the actual tile distance between attacker and defender is greater than 1 at the moment of the attack (i.e., not adjacent), independent of the attacker's printed RANGE stat. A Sniper (RANGE 4) shooting an adjacent enemy is therefore *not* making a ranged attack, and Quartz Armor does not reduce it. This is now a fixed rule, not a working assumption, and it is what BR-011B in the BRD states.
- **Order of applying flat passive reduction vs. shields (Section 4.1) is a bookkeeping choice, not a rules decision** — both are linear subtractions clamped only at the end, so the final `final_damage` value is identical regardless of order. Documented rather than flagged as a real ambiguity.
- **Shield stacking order — resolved 2026-09-25: newest-first (LIFO).** The last shield applied is the first one consumed (Section 4.1 step 8). Still not exercised by any current card in normal play (the roster rarely stacks two shields on one character), but it is now a stated rule rather than an arbitrary implementation detail, so a future card that does stack shields inherits a defined answer.
- **(v3 patch note)** `AbilitySystem.intercept_lethal_damage(defender) -> Dictionary` is a new forward reference added for Last Oath (Bogatyr Champion L3) — needed because a lethal-damage interception must happen *before* `_handle_defeat` runs, not as a reaction afterward (by then the character is already removed from the board). `AbilitySystem` owns tracking whether Last Oath has already triggered this match (`ability_uses_this_match`).
- **`AbilitySystem.get_passive_damage_reduction(defender, attacker, is_ranged)` forward-referenced contract** — LLD-05 must implement this exact signature; it needs to consider the defender's own passives (Quartz Armor) and nearby allies' aura passives (Bogatyr Champion L2, Winter Engineer L3) in one combined lookup, but that composition logic belongs entirely to `AbilitySystem`, not this LLD.
- **`get_effective_movement_pattern` composing with a Mount-side pattern ability (e.g. Manta Glider's Glide) and the rider's own `AbilitySystem.get_movement_passable_predicate` query (LLD-rules-engine.md Section 4.2 step 2).** This LLD returns the Mount's pattern string only; whether a Mount's own pass-through ability (ridden or not) supplies the movement predicate is `AbilitySystem`'s composition responsibility in LLD-05 — flagged so that LLD doesn't have to rediscover this seam.

## 10. Traceability

| LLD Section | HLD Section | BRD/PRD IDs |
| --- | --- | --- |
| 3.1, 4.1 `CombatResolver`/`apply_damage` | HLD 4.5, Flow B | FR-028–FR-033, FR-036 |
| 4.2 `apply_push` | HLD 4.5 | FR-034 |
| 4.3 `_handle_defeat` | HLD 4.5, 4.7 | FR-032, BR-016 |
| 3.2 `MountSystem` | HLD 4.7 | FR-045B–FR-045H, BR-012–BR-017 |

## 11. Next Steps

1. Add `scripts/systems/combat_resolver.gd` and `mount_system.gd` (Section 3.1–3.2); wire both to be instantiated by `RulesEngine` at match start (constructed with the `BoardModel` instance from `GameState.match_state.board`).
2. Write `tests/unit/test_combat_resolver.gd` and `test_mount_system.gd`; confirm C1–C12, using a GUT double for `AbilitySystem.get_passive_damage_reduction`.
3. ~~Resolve the "ranged" definition open question~~ — closed 2026-09-25 (confirmed as actual tile distance > 1; see Section 9 and BR-011B). Implement `resolve_attack`'s `is_ranged` computation exactly that way.
4. Once LLD-05 lands, replace the `AbilitySystem` double with the real implementation and add an integration test exercising a full attack with an active passive reduction.
